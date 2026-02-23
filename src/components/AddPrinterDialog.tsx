"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { usePrinterStore } from "@/store/printerStore"
import { toast } from "sonner"
import { Plus } from "lucide-react"

export function AddPrinterDialog() {
  const [open, setOpen] = useState(false)
  const [name, setName] = useState("")
  const [ip, setIp] = useState("")
  const addPrinter = usePrinterStore((state) => state.addPrinter)

  const handleSubmit = async () => {
    if (!name || !ip) {
        toast.error("Please fill in all fields")
        return
    }
    
    await addPrinter({ name, ip })
    
    setOpen(false)
    setName("")
    setIp("")
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
            <Plus className="mr-2 h-4 w-4" /> Add Printer
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px] bg-[#1A1020] border-white/10 text-white rounded-[32px]">
        <DialogHeader>
          <DialogTitle className="text-2xl font-display uppercase tracking-tight text-white">Add Printer</DialogTitle>
          <DialogDescription className="text-gray-400">
            Enter the details of your Moonraker/Klipper printer.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-6 py-6">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="name" className="text-right text-gray-300">
              Name
            </Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="col-span-3 bg-black/20 border-white/10 rounded-xl text-white focus-visible:ring-primary"
              placeholder="Voron 2.4"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="ip" className="text-right text-gray-300">
              IP / Hostname
            </Label>
            <Input
              id="ip"
              value={ip}
              onChange={(e) => setIp(e.target.value)}
              className="col-span-3 bg-black/20 border-white/10 rounded-xl text-white focus-visible:ring-primary"
              placeholder="192.168.1.100"
            />
          </div>
        </div>
        <DialogFooter>
          <Button onClick={handleSubmit} className="w-full rounded-full bg-primary hover:bg-primary/90 text-white">Add Printer</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
