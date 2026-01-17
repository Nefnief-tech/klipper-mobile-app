import { create } from 'zustand';
import { Printer, GCodeFile } from '@/types';
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
            temperatureHistory: []
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
                temperatureHistory: []
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
          updatePrinter(printer.id, { status: 'offline' });
      }
  },

  startPrint: async (printerId, filename) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/print/start?filename=${encodeURIComponent(filename)}`, 'POST');
          toast.success("Print started");
          get().refreshPrinter(printerId);
      } catch (e) { toast.error("Failed to start print"); }
  },

  pausePrint: async (printerId) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/print/pause`, 'POST');
          get().refreshPrinter(printerId);
      } catch (e) {}
  },

  resumePrint: async (printerId) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/print/resume`, 'POST');
          get().refreshPrinter(printerId);
      } catch (e) {}
  },

  cancelPrint: async (printerId) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/print/cancel`, 'POST');
          get().refreshPrinter(printerId);
      } catch (e) {}
  },

  setTemperature: async (printerId, type, temp) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          const cmd = type === 'extruder' ? 'M104' : 'M140';
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/gcode/script?script=${cmd} S${temp}`, 'POST');
          toast.success(`Set ${type} to ${temp}°C`);
          get().updatePrinter(printerId, type === 'extruder' ? { targetNozzle: temp } : { targetBed: temp });
      } catch (e) {}
  },

  sendGCode: async (printerId, script) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          
          // Optimistic UI for Emergency Stop
          if (script === 'M112' || script === 'FIRMWARE_RESTART') {
              get().updatePrinter(printerId, { status: script === 'M112' ? 'error' : 'offline' });
          }

          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/gcode/script?script=${encodeURIComponent(script)}`, 'POST');
          const newLogs = [...(printer.terminalLogs || []), `> ${script}`].slice(-100);
          get().updatePrinter(printerId, { terminalLogs: newLogs });
      } catch (e) {
          // If connection drops during E-stop, it's expected
          if (script === 'M112') {
              get().updatePrinter(printerId, { status: 'error' });
          }
      }
  },

  excludePrinterObject: async (printerId, name) => {
      try {
          const printer = get().printers.find(p => p.id === printerId);
          if (!printer) return;
          await fetchProxy(`${getBaseUrl(printer.ip)}/printer/exclude_object/exclude?name=${encodeURIComponent(name)}`, 'POST');
          toast.success(`Excluded: ${name}`);
          get().refreshPrinter(printerId);
      } catch (e) {
          toast.error("Failed to exclude object");
      }
  }

}));
