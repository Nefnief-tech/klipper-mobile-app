"use client"

import { Printer } from "@/types";
import { Card } from "@/components/ui/card";
import { Printer as PrinterIcon, Play, AlertCircle, WifiOff } from "lucide-react";

interface AtGlanceProps {
  printers: Printer[];
}

export function AtGlance({ printers }: AtGlanceProps) {
  const stats = {
    total: printers.length,
    printing: printers.filter(p => p.status === 'printing').length,
    error: printers.filter(p => p.status === 'error').length,
    offline: printers.filter(p => p.status === 'offline').length,
  };

  const statItems = [
    {
      label: "Total Printers",
      value: stats.total,
      icon: PrinterIcon,
      color: "text-primary",
      bg: "bg-primary/10",
    },
    {
      label: "Active Prints",
      value: stats.printing,
      icon: Play,
      color: "text-secondary",
      bg: "bg-secondary/10",
    },
    {
      label: "Errors",
      value: stats.error,
      icon: AlertCircle,
      color: "text-destructive",
      bg: "bg-destructive/10",
    },
    {
      label: "Offline",
      value: stats.offline,
      icon: WifiOff,
      color: "text-muted-foreground",
      bg: "bg-muted/10",
    },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
      {statItems.map((item, index) => (
        <Card key={index} className="p-6 bg-card border-none rounded-[32px] shadow-lg ring-1 ring-white/5 flex items-center gap-4">
          <div className={`${item.bg} p-3 rounded-2xl`}>
            <item.icon className={`h-6 w-6 ${item.color}`} />
          </div>
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">{item.label}</p>
            <p className="text-2xl font-mono font-bold text-white">{item.value}</p>
          </div>
        </Card>
      ))}
    </div>
  );
}
