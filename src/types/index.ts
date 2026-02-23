export type PrinterStatus = 'idle' | 'printing' | 'paused' | 'error' | 'offline';

export type AfcLaneStatus = 'empty' | 'loaded' | 'active' | 'loading' | 'unloading' | 'unknown';

export interface AFCLane {
  id: number;
  name: string;
  status: AfcLaneStatus;
  material?: string;
  color?: string;
}

export interface AFC {
  lanes: AFCLane[];
  activeLane: number | null;
  status: string;
}

export interface Spool {
  id: number;
  name: string;
  material: string;
  vendor: string;
  remainingWeight: number;
  color?: string;
}

export interface KlipperDevice {
  name: string;
  type: 'fan' | 'fan_generic' | 'output_pin' | 'led' | 'neopixel';
  value: number;
  isOn?: boolean;
}

export interface GCodeFile {
  name: string;
  size: number;
  modified: number; // timestamp
}

export interface Printer {
  id: string;
  name: string;
  ip: string;
  status: PrinterStatus;
  progress: number; // 0-100
  nozzleTemp: number;
  targetNozzle: number;
  bedTemp: number;
  targetBed: number;
  currentFile?: string;
  thumbnail?: string; // base64 or url
  timeLeft?: string; // e.g. "2h 15m"
  files: GCodeFile[];
  macros: string[];
  terminalLogs: string[];
  excludeObject?: {
    objects: { name: string; center: number[]; polygon: number[][] }[];
    excluded_objects: string[];
    current_object: string | null;
  };
  temperatureHistory: {
    time: number;
    nozzle: number;
    targetNozzle: number;
    bed: number;
    targetBed: number;
  }[];
  afc?: AFC;
  currentSpool?: Spool;
  devices: KlipperDevice[];
}

export interface PrintJob {
  id: string;
  printerId: string;
  filename: string;
  scheduledTime: Date;
  status: 'pending' | 'completed' | 'cancelled';
}
