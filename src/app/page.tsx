"use client"
import { useEffect, useMemo } from "react";
import { usePrinterStore } from "@/store/printerStore";
import { PrinterCard } from "@/components/PrinterCard";
import { AddPrinterDialog } from "@/components/AddPrinterDialog";
import { AtGlance } from "@/components/AtGlance";

export default function Dashboard() {
  const printers = usePrinterStore((state) => state.printers);
  const refreshPrinters = usePrinterStore((state) => state.refreshPrinters);
  const init = usePrinterStore((state) => state.init);

  useEffect(() => {
      init();
      const interval = setInterval(() => {
          refreshPrinters();
      }, 5000);
      return () => clearInterval(interval);
  }, [init, refreshPrinters]);

  const sortedPrinters = useMemo(() => {
      return [...printers].sort((a, b) => {
          const score = {
              'error': 0,
              'printing': 1,
              'paused': 2,
              'idle': 3,
              'offline': 4
          };
          return (score[a.status] ?? 5) - (score[b.status] ?? 5);
      });
  }, [printers]);

  return (
    <div className="min-h-full p-8 md:p-12 space-y-12 max-w-[1920px] mx-auto">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div className="space-y-2">
            <h1 className="text-6xl md:text-8xl font-display uppercase tracking-tighter text-primary leading-[0.85]">
                Control<br/>Center
            </h1>
          </div>
          <div className="flex items-center gap-4">
            <AddPrinterDialog />
          </div>
      </div>

      <AtGlance printers={printers} />
      
      {printers.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 rounded-[48px] bg-white/40 border-4 border-dashed border-white/50">
              <h3 className="text-3xl font-display text-primary/50 mb-4">No Machines Found</h3>
              <p className="text-lg text-muted-foreground mb-8 max-w-md text-center">
                  Add a Moonraker/Klipper instance to get started.
              </p>
              <AddPrinterDialog />
          </div>
      ) : (
          <div className="grid gap-8 md:gap-12 sm:grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3">
            {sortedPrinters.map((printer) => (
              <PrinterCard key={printer.id} printer={printer} />
            ))}
          </div>
      )}
    </div>
  );
}