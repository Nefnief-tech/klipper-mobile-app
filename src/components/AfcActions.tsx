"use client"

import { Button } from "@/components/ui/button";
import { 
  RotateCcw, Scissors, Trash2, Brush, 
  ParkingSquare, Gauge, Lightbulb, LightbulbOff,
  Settings, VolumeX, AlertCircle, Timer
} from "lucide-react";

interface AfcActionsProps {
  onAction: (action: string) => void;
  isLoading?: boolean;
}

const actions = [
  { id: "eject", label: "Eject", icon: Trash2, color: "bg-red-600 hover:bg-red-700" },
  { id: "cut", label: "Cut", icon: Scissors, color: "bg-orange-600 hover:bg-orange-700" },
  { id: "brush", label: "Brush", icon: Brush, color: "bg-blue-600 hover:bg-blue-700" },
  { id: "poop", label: "Poop", icon: RotateCcw, color: "bg-purple-600 hover:bg-purple-700" },
  { id: "park", label: "Park", icon: ParkingSquare, color: "bg-yellow-600 hover:bg-yellow-700" },
  { id: "stats", label: "Stats", icon: Gauge, color: "bg-cyan-600 hover:bg-cyan-700" },
  { id: "calibration", label: "Calibrate", icon: Settings, color: "bg-teal-600 hover:bg-teal-700" },
];

const ledActions = [
  { id: "led_on", label: "LED On", icon: Lightbulb, color: "bg-green-600 hover:bg-green-700" },
  { id: "led_off", label: "LED Off", icon: LightbulbOff, color: "bg-gray-600 hover:bg-gray-700" },
];

const systemActions = [
  { id: "quiet_mode", label: "Quiet", icon: VolumeX, color: "bg-slate-600 hover:bg-slate-700" },
  { id: "clear_message", label: "Clear", icon: AlertCircle, color: "bg-zinc-600 hover:bg-zinc-700" },
  { id: "reset_motor_time", label: "Reset Motors", icon: Timer, color: "bg-indigo-600 hover:bg-indigo-700" },
];

export function AfcActions({ onAction, isLoading }: AfcActionsProps) {
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        {actions.map((action) => (
          <Button
            key={action.id}
            variant="outline"
            size="sm"
            onClick={() => onAction(action.id)}
            disabled={isLoading}
            className="gap-2"
          >
            <action.icon className="w-4 h-4" />
            {action.label}
          </Button>
        ))}
      </div>
      
      <div className="flex flex-wrap gap-2">
        {ledActions.map((action) => (
          <Button
            key={action.id}
            variant="outline"
            size="sm"
            onClick={() => onAction(action.id)}
            disabled={isLoading}
            className="gap-2"
          >
            <action.icon className="w-4 h-4" />
            {action.label}
          </Button>
        ))}
      </div>

      <div className="flex flex-wrap gap-2">
        {systemActions.map((action) => (
          <Button
            key={action.id}
            variant="outline"
            size="sm"
            onClick={() => onAction(action.id)}
            disabled={isLoading}
            className="gap-2"
          >
            <action.icon className="w-4 h-4" />
            {action.label}
          </Button>
        ))}
      </div>
    </div>
  );
}
