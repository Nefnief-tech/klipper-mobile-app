"use client"

import { AFCLane } from "@/types";
import { cn } from "@/lib/utils";

interface AfcLaneCardProps {
  lane: AFCLane;
  isActive: boolean;
  onLoad: () => void;
  onUnload: () => void;
}

export function AfcLaneCard({ lane, isActive, onLoad, onUnload }: AfcLaneCardProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
      case "loaded":
        return "bg-green-500/20 border-green-500/50";
      case "loading":
      case "unloading":
        return "bg-yellow-500/20 border-yellow-500/50";
      case "empty":
        return "bg-muted/50 border-muted";
      default:
        return "bg-muted/30 border-muted/50";
    }
  };

  const getStatusDot = (status: string) => {
    switch (status) {
      case "active":
      case "loaded":
        return "bg-green-500";
      case "loading":
      case "unloading":
        return "bg-yellow-500 animate-pulse";
      case "empty":
        return "bg-muted-foreground/50";
      default:
        return "bg-muted-foreground/50";
    }
  };

  return (
    <div
      className={cn(
        "relative p-4 rounded-2xl border-2 transition-all",
        getStatusColor(lane.status),
        isActive && "ring-2 ring-primary ring-offset-2 ring-offset-background"
      )}
    >
      {isActive && (
        <div className="absolute -top-2 -right-2 bg-primary text-primary-foreground text-xs font-bold px-2 py-1 rounded-full">
          ACTIVE
        </div>
      )}

      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <div className={cn("w-3 h-3 rounded-full", getStatusDot(lane.status))} />
          <span className="font-mono text-lg font-bold">Lane {lane.id}</span>
        </div>
        <span className="text-xs uppercase tracking-wider text-muted-foreground">
          {lane.status}
        </span>
      </div>

      <div className="space-y-2">
        {lane.material && (
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground uppercase w-16">Material</span>
            <span className="font-medium">{lane.material}</span>
          </div>
        )}
        {lane.color && (
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground uppercase w-16">Color</span>
            <div
              className="w-4 h-4 rounded-full border border-white/20"
              style={{ backgroundColor: lane.color.startsWith('#') ? lane.color : `#${lane.color}` }}
            />
          </div>
        )}
      </div>

      <div className="flex gap-2 mt-4">
        {lane.status === "empty" ? (
          <button
            onClick={onLoad}
            className="flex-1 py-2 px-3 bg-green-600/80 hover:bg-green-600 text-white text-sm font-medium rounded-lg transition-colors"
          >
            Load
          </button>
        ) : lane.status === "loaded" || lane.status === "active" ? (
          <button
            onClick={onUnload}
            className="flex-1 py-2 px-3 bg-orange-600/80 hover:bg-orange-600 text-white text-sm font-medium rounded-lg transition-colors"
          >
            Unload
          </button>
        ) : (
          <div className="flex-1 py-2 px-3 bg-muted text-muted-foreground text-sm font-medium rounded-lg text-center">
            {lane.status}
          </div>
        )}
      </div>
    </div>
  );
}
