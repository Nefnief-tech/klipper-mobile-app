import { create } from 'zustand';
import { Printer, GCodeFile, AFC, AFCLane, Spool, KlipperDevice } from '@/types';
import { toast } from 'sonner';

interface PrinterState {
  printers: Printer[];
  init: () => Promise<void>;
  addPrinter: (data: { name: string; ip: string }) => Promise<void>;
  removePrinter: (id: string) => Promise<void>;
  updatePrinter: (id: string, data: Partial<Printer>) => void;
  
  // Actions
  refreshPrinters: () => Promise<void>;
  refreshPrinter: (printerId: string) => Promise<void>;
  startPrint: (printerId: string, filename: string) => Promise<void>;
  pausePrint: (printerId: string) => Promise<void>;
  resumePrint: (printerId: string) => Promise<void>;
  cancelPrint: (printerId: string) => Promise<void>;
  setTemperature: (printerId: string, type: 'extruder' | 'heater_bed', temp: number) => Promise<void>;
  sendGCode: (printerId: string, script: string) => Promise<void>;
  excludePrinterObject: (printerId: string, name: string) => Promise<void>;
  
  // AFC Actions
  refreshAfc: (printerId: string) => Promise<void>;
  afcAction: (printerId: string, action: string, laneId?: number) => Promise<void>;
  updateAfcLane: (printerId: string, laneId: number, material: string, color: string, spoolId?: number) => Promise<void>;
}

const getBaseUrl = (ip: string) => {
    let url = ip;
    if (!url.startsWith('http')) {
        url = `http://${url}`;
    }
    return url;
};

const fetchProxy = async (targetUrl: string, method: 'GET' | 'POST' = 'GET') => {
    const proxyUrl = `/api/proxy?url=${encodeURIComponent(targetUrl)}`;
    const res = await fetch(proxyUrl, { method });
    if (!res.ok) throw new Error(`Proxy error: ${res.statusText}`);
    return res.json();
};

export const usePrinterStore = create<PrinterState>((set, get) => ({
  printers: [],

  init: async () => {
    try {
        const res = await fetch('/api/printers');
        const data = await res.json();
        const printersWithStatus = data.map((p: any) => ({
            ...p,
            status: 'offline',
            progress: 0,
            nozzleTemp: 0,
            targetNozzle: 0,
            bedTemp: 0,
            targetBed: 0,
            files: [],
            macros: [],
            terminalLogs: [],
            temperatureHistory: [],
            devices: []
        }));
        set({ printers: printersWithStatus });
        get().refreshPrinters();
    } catch (e) {
        console.error("Failed to load printers", e);
    }
  },
  
  addPrinter: async (data) => {
    try {
        const res = await fetch('/api/printers', {
            method: 'POST',
            body: JSON.stringify(data),
            headers: { 'Content-Type': 'application/json' }
        });
        const printer = await res.json();
        set((state) => ({ 
            printers: [...state.printers, {
                ...printer,
                status: 'offline',
                progress: 0,
                nozzleTemp: 0,
                targetNozzle: 0,
                bedTemp: 0,
                targetBed: 0,
                files: [],
                macros: [],
                terminalLogs: [],
                temperatureHistory: [],
                devices: []
            }] 
        }));
        get().refreshPrinter(printer.id);
    } catch (e) {
        toast.error("Failed to add printer");
    }
  },

  removePrinter: async (id) => {
    try {
        await fetch(`/api/printers/${id}`, { method: 'DELETE' });
        set((state) => ({ printers: state.printers.filter((p) => p.id !== id) }));
        toast.success("Printer removed");
    } catch (e) {
        toast.error("Failed to remove printer");
    }
  },

  updatePrinter: (id, data) => set((state) => ({
    printers: state.printers.map((p) => (p.id === id ? { ...p, ...data } : p))
  })),

  refreshPrinters: async () => {
      const { printers } = get();
      await Promise.all(printers.map(printer => get().refreshPrinter(printer.id)));
  },

  refreshPrinter: async (printerId: string) => {
      const { printers, updatePrinter } = get();
      const printer = printers.find(p => p.id === printerId);
      if (!printer) return;

      const baseUrl = getBaseUrl(printer.ip);
      try {
          const statusUrl = `${baseUrl}/printer/objects/query?print_stats&display_status&heater_bed&extruder&virtual_sdcard&exclude_object`;
          const statusData = await fetchProxy(statusUrl);
          const stats = statusData.result.status;
          const ps = stats.print_stats;
          
          let status: Printer['status'] = 'idle';
          if (ps.state === 'printing') status = 'printing';
          else if (ps.state === 'paused') status = 'paused';
          else if (ps.state === 'error' || ps.state === 'shutdown' || ps.state === 'disconnected') status = 'error';
          else if (stats.print_stats.state === 'standby') status = 'idle';

          let progress = 0;
          if (stats.display_status?.progress) progress = stats.display_status.progress * 100;

          let files: GCodeFile[] = printer.files;
          try {
              const filesData = await fetchProxy(`${baseUrl}/server/files/list?root=gcodes`);
              files = filesData.result.map((f: any) => ({
                  name: f.path,
                  size: f.size,
                  modified: f.modified
              })).sort((a: any, b: any) => b.modified - a.modified);
          } catch (e) {}

          let macros: string[] = printer.macros;
          try {
              const objectsData = await fetchProxy(`${baseUrl}/printer/objects/list`);
              macros = (objectsData.result.objects as string[])
                  .filter(obj => obj.startsWith('gcode_macro '))
                  .map(obj => obj.replace('gcode_macro ', ''));
          } catch (e) {}

          const newHistoryPoint = {
              time: Date.now(),
              nozzle: Math.round(stats.extruder?.temperature || 0),
              targetNozzle: Math.round(stats.extruder?.target || 0),
              bed: Math.round(stats.heater_bed?.temperature || 0),
              targetBed: Math.round(stats.heater_bed?.target || 0),
          };
          
          const updatedHistory = [...(printer.temperatureHistory || []), newHistoryPoint].slice(-60);

          updatePrinter(printer.id, {
              status,
              progress: Math.round(progress),
              nozzleTemp: Math.round(stats.extruder?.temperature || 0),
              targetNozzle: Math.round(stats.extruder?.target || 0),
              bedTemp: Math.round(stats.heater_bed?.temperature || 0),
              targetBed: Math.round(stats.heater_bed?.target || 0),
              currentFile: ps.filename,
              files,
              macros,
              temperatureHistory: updatedHistory,
              excludeObject: stats.exclude_object
          });

      } catch (error) {
          // Try to fetch AFC separately even if main status fails
          get().refreshAfc(printerId);
          updatePrinter(printer.id, { status: 'offline' });
      }
  },

  refreshAfc: async (printerId: string) => {
      const { printers, updatePrinter } = get();
      const printer = printers.find(p => p.id === printerId);
      if (!printer) return;

      const baseUrl = getBaseUrl(printer.ip);
      
      try {
          // Fetch AFC status from dedicated endpoint
          const afcData = await fetchProxy(`${baseUrl}/printer/afc/status`);
          const result = afcData.result || afcData;
          
          // Parse AFC data similar to Flutter implementation
          const afc = parseAfcData(result);
          
          updatePrinter(printerId, { afc });
      } catch (e) {
          // AFC endpoint might not exist or printer might be offline
          console.error("Failed to refresh AFC:", e);
      }
  },

  afcAction: async (printerId: string, action: string, laneId?: number) => {
      const printer = get().printers.find(p => p.id === printerId);
      if (!printer) return;

      const baseUrl = getBaseUrl(printer.ip);
      let cmd = '';
      const laneName = laneId ? `lane${laneId}` : '';

      switch (action.toLowerCase()) {
          case 'load':
              if (laneId == null) return;
              // T0, T1, etc. triggers load for that lane
              cmd = `T${laneId - 1}`;
              break;
          case 'unload':
              cmd = laneId ? `AFC_LANE_RESET LANE=${laneName}` : 'AFC_LANE_RESET';
              break;
          case 'eject':
              cmd = 'AFC_KICK';
              break;
          case 'stats':
              cmd = 'AFC_STATS';
              break;
          case 'cut':
              cmd = 'AFC_CUT';
              break;
          case 'poop':
              cmd = 'AFC_POOP';
              break;
          case 'brush':
              cmd = 'AFC_BRUSH';
              break;
          case 'park':
              cmd = 'AFC_PARK';
              break;
          case 'calibration':
              cmd = 'CALIBRATE_AFC';
              break;
          case 'led_on':
              cmd = 'TURN_ON_AFC_LED';
              break;
          case 'led_off':
              cmd = 'TURN_OFF_AFC_LED';
              break;
          case 'reset_lane':
              if (laneId == null) return;
              cmd = `AFC_LANE_RESET LANE=${laneName}`;
              break;
          case 'reset_mapping':
              cmd = 'RESET_AFC_MAPPING';
              break;
          case 'tip_forming':
              cmd = 'TEST_AFC_TIP_FORMING';
              break;
          case 'quiet_mode':
              cmd = 'AFC_QUIET_MODE';
              break;
          case 'clear_message':
              cmd = 'AFC_CLEAR_MESSAGE';
              break;
          case 'reset_motor_time':
              cmd = 'AFC_RESET_MOTOR_TIME';
              break;
          default:
              return;
      }

      try {
          await fetchProxy(`${baseUrl}/printer/gcode/script?script=${encodeURIComponent(cmd)}`, 'POST');
          toast.success(`AFC: ${action}${laneId ? ` lane ${laneId}` : ''}`);
          // Refresh AFC status after action
          setTimeout(() => get().refreshAfc(printerId), 500);
      } catch (e) {
          toast.error(`Failed to execute AFC action: ${action}`);
      }
  },

  updateAfcLane: async (printerId: string, laneId: number, material: string, color: string, spoolId?: number) => {
      const printer = get().printers.find(p => p.id === printerId);
      if (!printer) return;

      const baseUrl = getBaseUrl(printer.ip);
      const laneName = `lane${laneId}`;
      const commands: string[] = [];

      if (spoolId != null) {
          commands.push(`SET_SPOOL_ID LANE=${laneName} SPOOL_ID=${spoolId}`);
      } else {
          if (material) {
              commands.push(`SET_MATERIAL LANE=${laneName} MATERIAL=${material}`);
          }
          if (color) {
              const cleanColor = color.replace('#', '');
              commands.push(`SET_COLOR LANE=${laneName} COLOR=${cleanColor}`);
          }
      }

      try {
          for (const cmd of commands) {
              await fetchProxy(`${baseUrl}/printer/gcode/script?script=${encodeURIComponent(cmd)}`, 'POST');
          }
          toast.success(`Updated lane ${laneId}`);
          setTimeout(() => get().refreshAfc(printerId), 500);
      } catch (e) {
          toast.error("Failed to update lane");
      }
  }

}));

// Helper function to parse AFC data from Moonraker
function parseAfcData(raw: any): AFC | undefined {
  if (!raw || typeof raw !== 'object') return undefined;

  try {
      const rawAfc = raw.AFC || raw.afc || raw;
      if (!rawAfc || typeof rawAfc !== 'object') return undefined;

      let lanes: AFCLane[] = [];
      let activeLane: number | null = null;
      let status = 'unknown';

      // Find active lane info
      if (rawAfc.system) {
          const systemData = rawAfc.system;
          if (systemData.current_load) {
              const activeName = systemData.current_load.toString();
              // Parse lane number from name like "lane4"
              const match = activeName.match(/lane(\d+)/i);
              if (match) activeLane = parseInt(match[1], 10);
          }
          if (systemData.buffers) {
              const firstBuffer = Object.values(systemData.buffers)[0] as any;
              if (firstBuffer?.state) status = firstBuffer.state.toString();
          }
      }
      if (rawAfc.current_load) {
          const activeName = rawAfc.current_load.toString();
          const match = activeName.match(/lane(\d+)/i);
          if (match) activeLane = parseInt(match[1], 10);
      }

      // Find the unit that contains lanes
      let unitData = rawAfc;
      for (const key of Object.keys(rawAfc)) {
          if (rawAfc[key] && typeof rawAfc[key] === 'object' && (rawAfc[key] as any).lane1) {
              unitData = rawAfc[key];
              break;
          }
      }

      // Parse lanes
      for (const [key, value] of Object.entries(unitData)) {
          if (key.startsWith('lane') && value && typeof value === 'object') {
              const laneData = value as any;
              if (laneData.lane !== undefined) {
                  lanes.push({
                      id: typeof laneData.lane === 'number' ? laneData.lane : parseInt(laneData.lane.toString()) || -1,
                      name: laneData.name?.toString() || key,
                      status: mapLaneStatus(laneData.status?.toString()),
                      material: laneData.material?.toString(),
                      color: laneData.color?.toString()
                  });
              }
          }
      }

      // Sort by lane ID
      lanes.sort((a, b) => a.id - b.id);

      if (lanes.length === 0) return undefined;

      return { lanes, activeLane, status };
  } catch (e) {
      console.error("Error parsing AFC data:", e);
      return undefined;
  }
}

function mapLaneStatus(status: string | undefined): AFCLane['status'] {
  if (!status) return 'unknown';
  const s = status.toLowerCase();
  if (s === 'loaded' || s === 'active') return s;
  if (s === 'empty') return 'empty';
  if (s.includes('loading')) return 'loading';
  if (s.includes('unloading')) return 'unloading';
  return 'unknown';
}
