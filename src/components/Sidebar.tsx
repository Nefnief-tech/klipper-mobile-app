"use client"
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Home, Settings } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ModeToggle } from '@/components/mode-toggle';

export function Sidebar() {
  const pathname = usePathname();

  const links = [
    { href: '/', label: 'Home', icon: Home },
  ];

  return (
    <div className="hidden md:flex h-full w-24 flex-col items-center py-8 bg-card/50 backdrop-blur-sm m-4 rounded-[40px] shadow-sm border border-white/20">
      <div className="mb-8">
        <div className="h-12 w-12 bg-primary rounded-full flex items-center justify-center text-white font-display text-xl">
            FM
        </div>
      </div>
      <nav className="flex-1 space-y-4 flex flex-col items-center w-full px-2">
        {links.map((link) => {
           const Icon = link.icon;
           const isActive = pathname === link.href;
           return (
             <Button
               key={link.href}
               variant={isActive ? "default" : "ghost"}
               size="icon-lg"
               className={cn(
                   "rounded-full transition-all duration-300", 
                   isActive ? "bg-primary text-white shadow-lg scale-110" : "text-muted-foreground hover:bg-white/50"
               )}
               asChild
             >
               <Link href={link.href} title={link.label}>
                 <Icon className="h-6 w-6" />
               </Link>
             </Button>
           )
        })}
      </nav>
      <div className="mt-auto flex flex-col gap-4">
          <Button variant="ghost" size="icon-lg" className="rounded-full hover:bg-white/50 text-muted-foreground">
              <Settings className="h-6 w-6" />
          </Button>
          <ModeToggle />
      </div>
    </div>
  );
}
