"use client"

import * as React from "react"
import { usePrinterStore } from "@/store/printerStore"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Input } from "@/components/ui/input"
import { 
  Play, 
  Pause, 
  Square, 
  ArrowLeft, 
  Clock, 
  FileCode, 
  Video, 
  RefreshCw, 
  Settings,
  Terminal,
  Zap,
  Flame,
  Home,
  Power,
  Fan,
  AlertCircle,
  Layers,
  Send,
  Target
} from "lucide-react"
import Link from "next/link"
import { cn } from "@/lib/utils"
import { toast } from "sonner"
import { ResponsiveContainer, LineChart, Line, YAxis } from "recharts"

export function PrinterDetail({ id }: { id: string }) {
  const printer = usePrinterStore((state) => state.printers.find((p) => p.id === id));
  const { startPrint, pausePrint, cancelPrint, refreshPrinter, setTemperature, sendGCode, excludePrinterObject } = usePrinterStore();
  const router = useRouter();
  const [tempInput, setTempInput] = React.useState("");
  const [commandInput, setCommandInput] = React.useState("");
  const scrollRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
      refreshPrinter(id);
      const interval = setInterval(() => { refreshPrinter(id); }, 1000);
      return () => clearInterval(interval);
  }, [id, refreshPrinter]);

  React.useEffect(() => {
      if (scrollRef.current) {
          scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
      }
  }, [printer?.terminalLogs]);

  if (!printer) return null;

  const handleSend = (e: React.FormEvent) => {
      e.preventDefault();
      if (!commandInput.trim()) return;
      sendGCode(printer.id, commandInput.trim());
      setCommandInput("");
  };

  const webcamUrl = `http://${printer.ip}/webcam/?action=stream`;

  return (
    <div className="relative min-h-screen">
      {/* Emergency Stop Overlay */}
      {printer.status === 'error' && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-2xl p-6">
          <Card className="max-w-md w-full bg-[#1A1020] border-2 border-destructive/50 rounded-[48px] p-10 text-center shadow-[0_0_100px_rgba(239,68,68,0.2)] animate-in fade-in zoom-in duration-300">
            <div className="mb-8 flex justify-center">
              <div className="bg-destructive/20 p-6 rounded-full text-destructive animate-pulse">
                <AlertCircle className="h-16 w-16" />
              </div>
            </div>
            <h2 className="text-4xl font-display uppercase tracking-tighter text-white mb-4">Emergency Stop</h2>
            <p className="text-gray-400 mb-10 font-medium">
              The printer firmware has been halted. Please check the machine for any physical issues before restarting.
            </p>
            <div className="flex flex-col gap-4">
              <Button 
                size="lg" 
                className="w-full h-16 rounded-full bg-primary text-white font-bold text-lg shadow-lg hover:bg-primary/90"
                onClick={() => sendGCode(printer.id, "FIRMWARE_RESTART")}
              >
                <RefreshCw className="mr-2 h-6 w-6" /> FIRMWARE RESTART
              </Button>
              <Button 
                variant="ghost" 
                className="rounded-full text-gray-500 hover:text-white"
                onClick={() => router.push("/")}
              >
                RETURN TO DASHBOARD
              </Button>
            </div>
          </Card>
        </div>
      )}

      <div className="p-6 md:p-8 max-w-[1920px] mx-auto flex flex-col gap-8 bg-background text-white">
      <header className="flex items-center justify-between">
          <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon" asChild className="rounded-full hover:bg-white/10 text-muted-foreground"><Link href="/"><ArrowLeft className="h-6 w-6" /></Link></Button>
              <div>
                  <h1 className="text-3xl md:text-5xl font-display uppercase tracking-tighter text-white leading-none">{printer.name}</h1>
                  <div className="flex items-center gap-3 mt-1">
                      <Badge variant="outline" className={cn("rounded-full px-2.5 py-0.5 text-xs font-bold uppercase border-none", printer.status === 'printing' ? "bg-primary text-white" : printer.status === 'error' ? "bg-destructive text-white" : "bg-white/10 text-muted-foreground")}>{printer.status}</Badge>
                      <span className="text-sm font-mono text-primary tracking-wide">{printer.ip}</span>
                  </div>
              </div>
          </div>
          <div className="flex items-center gap-3">
              <Button size="icon" className="rounded-full bg-primary text-white shadow-lg shadow-primary/20"><Settings className="h-5 w-5" /></Button>
          </div>
      </header>

      <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 flex-1">
          {/* Left: Viewport & Motion */}
          <div className="xl:col-span-7 flex flex-col gap-8">
              <Card className="relative flex-1 min-h-[400px] overflow-hidden bg-black rounded-[48px] border-none shadow-2xl ring-1 ring-white/10">
                  <img src={webcamUrl} alt="Webcam" className="absolute inset-0 w-full h-full object-cover opacity-90" onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0' }} />
                  {printer.status === 'printing' && (
                      <div className="absolute bottom-8 left-8 right-8 bg-black/70 backdrop-blur-xl p-6 rounded-[32px] border border-white/5 flex items-center justify-between">
                           <div className="flex items-center gap-6">
                               <div className="h-16 w-16 bg-primary rounded-full flex items-center justify-center font-display text-2xl shadow-lg">{printer.progress}%</div>
                               <div>
                                   <h3 className="font-bold text-lg truncate max-w-xs">{printer.currentFile}</h3>
                                   <div className="text-primary text-sm font-mono flex items-center gap-2"><Clock className="h-4 w-4" /> LIVE</div>
                               </div>
                           </div>
                           <div className="flex gap-3">
                               <Button size="icon" className="h-12 w-12 rounded-full bg-yellow-500 hover:bg-yellow-400 text-black" onClick={() => pausePrint(printer.id)}><Pause className="h-5 w-5 fill-current" /></Button>
                               <Button size="icon" className="h-12 w-12 rounded-full bg-destructive" onClick={() => cancelPrint(printer.id)}><Square className="h-5 w-5 fill-current" /></Button>
                           </div>
                      </div>
                  )}
              </Card>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {[["Home All", Home, "primary"], ["Motors Off", Power, "muted"], ["Cooldown", Fan, "blue"], ["Stop", AlertCircle, "destructive"]].map(([label, Icon, color]: any) => (
                      <Button key={label} variant="outline" className="h-20 rounded-[24px] border-white/10 bg-card hover:bg-white/5 flex flex-col gap-2" onClick={() => {
                          if (label === "Home All") sendGCode(printer.id, "G28");
                          if (label === "Motors Off") sendGCode(printer.id, "M18");
                          if (label === "Cooldown") { setTemperature(printer.id, 'extruder', 0); setTemperature(printer.id, 'heater_bed', 0); }
                          if (label === "Stop") sendGCode(printer.id, "M112");
                      }}>
                          <Icon className={cn("h-6 w-6", color === 'primary' ? "text-primary" : color === 'blue' ? "text-blue-400" : color === 'destructive' ? "text-destructive" : "text-muted-foreground")} />
                          <span className="text-[10px] font-bold uppercase tracking-widest">{label}</span>
                      </Button>
                  ))}
              </div>
          </div>

          {/* Right: Data & Logs */}
          <div className="xl:col-span-5 flex flex-col gap-8">
              <div className="grid grid-cols-2 gap-4">
                  {[["Extruder", Zap, printer.nozzleTemp, printer.targetNozzle, "#8A3FD6", "extruder"], ["Bed", Flame, printer.bedTemp, printer.targetBed, "#3B82F6", "heater_bed"]].map(([label, Icon, val, target, color, type]: any) => (
                      <Popover key={label}>
                          <PopoverTrigger asChild>
                              <div className="bg-card hover:bg-white/5 cursor-pointer p-6 rounded-[32px] border border-white/5 shadow-lg group relative overflow-hidden h-40">
                                  <div className="absolute inset-x-0 bottom-0 h-20 opacity-30">
                                      <ResponsiveContainer><LineChart data={printer.temperatureHistory}><YAxis domain={['auto', 'auto']} hide /><Line type="monotone" dataKey={type === 'extruder' ? 'nozzle' : 'bed'} stroke={color} strokeWidth={3} dot={false} isAnimationActive={false} /></LineChart></ResponsiveContainer>
                                  </div>
                                  <div className="relative z-10">
                                      <div className="flex items-center justify-between mb-2"><div className={cn("p-2 rounded-full", type === 'extruder' ? "bg-primary/10 text-primary" : "bg-blue-500/10 text-blue-500")}><Icon className="h-5 w-5" /></div><span className="text-[10px] font-bold uppercase text-muted-foreground">{label}</span></div>
                                      <div className="flex items-baseline gap-2"><span className="text-5xl font-display">{val}°</span><span className="text-sm font-mono text-muted-foreground">/ {target}°</span></div>
                                  </div>
                              </div>
                          </PopoverTrigger>
                          <PopoverContent className="w-72 p-6 bg-[#1A1020] border-white/10 rounded-[24px]">
                              <div className="space-y-4">
                                  <h4 className="font-bold uppercase text-sm">Set {label}</h4>
                                  <div className="flex gap-2"><Input type="number" className="bg-black/20 border-white/10" value={tempInput} onChange={e => setTempInput(e.target.value)} /><Button onClick={() => { setTemperature(printer.id, type, parseInt(tempInput)); setTempInput(""); }} className="bg-primary">SET</Button></div>
                              </div>
                          </PopoverContent>
                      </Popover>
                  ))}
              </div>

              <Card className="flex-1 bg-card border-none rounded-[40px] shadow-lg ring-1 ring-white/5 overflow-hidden flex flex-col min-h-[500px]">
                  <Tabs defaultValue="terminal" className="flex-1 flex flex-col h-full">
                      <div className="p-6 pb-2">
                          <TabsList className="bg-black/20 p-1 rounded-full w-full">
                              <TabsTrigger value="terminal" className="rounded-full flex-1 py-2.5 data-[state=active]:bg-primary uppercase font-bold text-[10px] tracking-widest"><Terminal className="mr-2 h-4 w-4" /> Terminal</TabsTrigger>
                              <TabsTrigger value="objects" className="rounded-full flex-1 py-2.5 data-[state=active]:bg-primary uppercase font-bold text-[10px] tracking-widest"><Target className="mr-2 h-4 w-4" /> Objects</TabsTrigger>
                              <TabsTrigger value="files" className="rounded-full flex-1 py-2.5 data-[state=active]:bg-primary uppercase font-bold text-[10px] tracking-widest"><FileCode className="mr-2 h-4 w-4" /> Files</TabsTrigger>
                          </TabsList>
                      </div>

                      <TabsContent value="terminal" className="flex-1 flex flex-col p-6 pt-2">
                          <div ref={scrollRef} className="flex-1 bg-black/40 rounded-[24px] border border-white/5 p-4 font-mono text-xs text-green-400/80 overflow-y-auto space-y-1">
                              {printer.terminalLogs?.map((log, i) => <div key={i}>{log}</div>)}
                              {(!printer.terminalLogs || printer.terminalLogs.length === 0) && <div className="text-white/20 h-full flex items-center justify-center">Log Stream Ready</div>}
                          </div>
                          <form onSubmit={handleSend} className="mt-4 flex gap-2">
                              <Input placeholder="Send Command..." className="rounded-full bg-black/20 border-white/10" value={commandInput} onChange={e => setCommandInput(e.target.value)} />
                              <Button type="submit" size="icon" className="rounded-full bg-primary"><Send className="h-4 w-4" /></Button>
                          </form>
                      </TabsContent>

                      <TabsContent value="objects" className="flex-1 p-6 pt-2 overflow-y-auto">
                          <div className="space-y-3">
                              {printer.excludeObject?.objects.map((obj) => {
                                  const isExcluded = printer.excludeObject?.excluded_objects.includes(obj.name);
                                  const isCurrent = printer.excludeObject?.current_object === obj.name;
                                  return (
                                      <div key={obj.name} className={cn("p-4 rounded-[24px] flex items-center justify-between transition-all", isExcluded ? "bg-white/5 opacity-40" : "bg-white/10 border border-white/5")}>
                                          <div className="flex items-center gap-4">
                                              <div className={cn("h-3 w-3 rounded-full", isExcluded ? "bg-red-500" : isCurrent ? "bg-green-500 animate-pulse" : "bg-primary")} />
                                              <span className="font-bold text-sm truncate">{obj.name}</span>
                                          </div>
                                          {!isExcluded && <Button size="sm" variant="secondary" className="rounded-full h-8 text-[10px]" onClick={() => excludePrinterObject(printer.id, obj.name)}>CANCEL PART</Button>}
                                      </div>
                                  );
                              })}
                              {(!printer.excludeObject || printer.excludeObject.objects.length === 0) && <div className="text-center py-20 text-muted-foreground">No Objects Found</div>}
                          </div>
                      </TabsContent>

                      <TabsContent value="files" className="flex-1 p-6 pt-2 overflow-y-auto">
                          <div className="space-y-3">
                              {printer.files.map(f => (
                                  <div key={f.name} className="p-4 rounded-[24px] bg-white/5 flex items-center justify-between group">
                                      <div className="flex items-center gap-4"><FileCode className="h-5 w-5 text-primary" /><div><p className="text-sm font-bold">{f.name}</p><p className="text-[10px] opacity-40">{(f.size/1024).toFixed(0)} KB</p></div></div>
                                      <Button size="icon" className="rounded-full opacity-0 group-hover:opacity-100" onClick={() => startPrint(printer.id, f.name)} disabled={printer.status !== 'idle'}><Play className="h-4 w-4" /></Button>
                                  </div>
                              ))}
                          </div>
                      </TabsContent>
                  </Tabs>
              </Card>
          </div>
      </div>
    </div>
    </div>
  );
}
