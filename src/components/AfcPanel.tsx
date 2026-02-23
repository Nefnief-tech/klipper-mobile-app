"use client"

import { useEffect } from "react";
import { Printer, AFC, AFCLane } from "@/types";
import { usePrinterStore } from "@/store/printerStore";
import { AfcLaneCard } from "./AfcLaneCard";
import { AfcActions } from "./AfcActions";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { RefreshCw, Box } from "lucide-react";

interface AfcPanelProps {
  printer: Printer;
}

export function AfcPanel({ printer }: AfcPanelProps) {
  const { afcAction, refreshAfc, updateAfcLane } = usePrinterStore();
  const afc = printer.afc;

  useEffect(() => {
    refreshAfc(printer.id);
    const interval = setInterval(() => refreshAfc(printer.id), 10000);
    return () => clearInterval(interval);
  }, [printer.id, refreshAfc]);

  const handleLaneLoad = (laneId: number) => {
    afcAction(printer.id, "load", laneId);
  };

  const handleLaneUnload = (laneId: number) => {
    afcAction(printer.id, "unload", laneId);
  };

  const handleAction = (action: string) => {
    afcAction(printer.id, action);
  };

  if (!afc || afc.lanes.length === 0) {
    return (
      <Card className="bg-card border-none rounded-[32px]">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-xl font-display uppercase">
              <Box className="w-5 h-5" />
              Box Turtle AFC
            </CardTitle>
            <Button
              variant="outline"
              size="sm"
              onClick={() => refreshAfc(printer.id)}
            >
              <RefreshCw className="w-4 h-4" />
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            <Box className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>No AFC detected</p>
            <p className="text-sm mt-2">Connect a Box Turtle AFC to manage filament lanes</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-card border-none rounded-[32px]">
      <CardHeader className="pb-4">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-xl font-display uppercase">
            <Box className="w-5 h-5" />
            Box Turtle AFC
          </CardTitle>
          <div className="flex items-center gap-2">
            {afc.status && (
              <span className="text-xs uppercase tracking-wider px-2 py-1 bg-muted rounded-full">
                {afc.status}
              </span>
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={() => refreshAfc(printer.id)}
            >
              <RefreshCw className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {afc.lanes.map((lane: AFCLane) => (
            <AfcLaneCard
              key={lane.id}
              lane={lane}
              isActive={afc.activeLane === lane.id}
              onLoad={() => handleLaneLoad(lane.id)}
              onUnload={() => handleLaneUnload(lane.id)}
            />
          ))}
        </div>

        <div className="border-t border-border pt-4">
          <h4 className="text-sm font-medium uppercase tracking-wider mb-3 text-muted-foreground">
            Quick Actions
          </h4>
          <AfcActions onAction={handleAction} />
        </div>
      </CardContent>
    </Card>
  );
}
