"use client"

import Link from "next/link";
import { Printer } from "@/types";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Button } from "@/components/ui/button";
import { Thermometer, Clock, FileCode, ArrowRight } from "lucide-react";
import { cn } from "@/lib/utils";

interface PrinterCardProps {
  printer: Printer;
}

export function PrinterCard({ printer }: PrinterCardProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "printing":
        return "bg-secondary text-secondary-foreground hover:bg-secondary/90 border-transparent";
      case "error":
      case "offline":
        return "bg-destructive text-white hover:bg-destructive/90 border-transparent";
      case "paused":
        return "bg-yellow-400 text-yellow-950 hover:bg-yellow-500 border-transparent";
      default:
        return "bg-white text-black border-2 border-primary/20 hover:border-primary/50";
    }
  };

  return (
    <Card className="group overflow-hidden transition-all hover:-translate-y-1 hover:shadow-2xl bg-card border-none rounded-[40px] shadow-lg ring-1 ring-white/5">
      <div className="p-8 pb-0 flex flex-row items-center justify-between space-y-0">
        <div>
            <CardTitle className="text-3xl font-display uppercase tracking-tight text-white group-hover:text-primary transition-colors">
            {printer.name}
            </CardTitle>
            <p className="text-sm font-mono text-muted-foreground mt-1 tracking-wider">{printer.ip}</p>
        </div>
        <Badge className={cn("px-4 py-1.5 rounded-full text-sm font-bold uppercase tracking-wider shadow-none border-none", getStatusColor(printer.status))}>
          {printer.status}
        </Badge>
      </div>
      
      <CardContent className="p-8 pt-6">
        <div className="grid gap-6">
            {printer.status === 'printing' ? (
                <div className="bg-primary/10 p-6 rounded-[24px] space-y-4 border border-primary/20">
                    <div className="flex items-center justify-between">
                        <span className="flex items-center font-bold text-primary truncate max-w-[150px]">
                            <FileCode className="mr-2 h-4 w-4" />
                            {printer.currentFile || 'Unknown'}
                        </span>
                        <span className="font-mono font-bold text-xl text-white">{printer.progress}%</span>
                    </div>
                    <Progress value={printer.progress} className="h-4 rounded-full bg-white/10 [&>div]:bg-primary" />
                    {printer.timeLeft && (
                        <div className="flex items-center justify-end text-sm font-medium text-muted-foreground">
                            <span className="flex items-center bg-white/5 px-3 py-1 rounded-full">
                                <Clock className="mr-1.5 h-3.5 w-3.5" />
                                {printer.timeLeft}
                            </span>
                        </div>
                    )}
                </div>
            ) : (
                <div className="bg-muted/50 p-6 rounded-[24px] flex items-center justify-center min-h-[140px] border border-white/5">
                    <p className="text-muted-foreground font-medium flex items-center">
                        <Clock className="mr-2 h-4 w-4" /> Ready for tasks
                    </p>
                </div>
            )}
            
            <div className="grid grid-cols-2 gap-4">
                <div className="bg-[#2a1b35] p-5 rounded-[24px] flex flex-col items-center text-center ring-1 ring-white/5">
                    <span className="text-xs font-bold uppercase tracking-widest text-primary/60 mb-1">Nozzle</span>
                    <span className="font-mono text-2xl font-bold text-primary">
                        {printer.nozzleTemp}°
                    </span>
                    <span className="text-[10px] font-mono text-muted-foreground">TARGET {printer.targetNozzle}°</span>
                </div>
                <div className="bg-[#1b2235] p-5 rounded-[24px] flex flex-col items-center text-center ring-1 ring-white/5">
                    <span className="text-xs font-bold uppercase tracking-widest text-blue-400 mb-1">Bed</span>
                    <span className="font-mono text-2xl font-bold text-blue-500">
                        {printer.bedTemp}°
                    </span>
                     <span className="text-[10px] font-mono text-muted-foreground">TARGET {printer.targetBed}°</span>
                </div>
            </div>
        </div>
      </CardContent>
      <CardFooter className="p-8 pt-0">
        <Button asChild className="w-full text-base bg-primary text-white hover:bg-primary/90 shadow-md" size="lg" variant="default">
          <Link href={`/printer/${printer.id}`}>
            Manage <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </Button>
      </CardFooter>
    </Card>
  );
}