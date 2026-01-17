import type { Metadata } from "next";
import { Anton, DM_Sans, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { Sidebar } from "@/components/Sidebar";
import { Toaster } from "@/components/ui/sonner";

const anton = Anton({
    weight: "400",
    subsets: ["latin"],
    variable: "--font-anton",
});

const dmSans = DM_Sans({
    subsets: ["latin"],
    variable: "--font-dm-sans",
});

const jetbrainsMono = JetBrains_Mono({
    subsets: ["latin"],
    variable: "--font-jetbrains-mono",
});

export const metadata: Metadata = {
  title: "Farm Manager",
  description: "Manage your 3D printer farm",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${dmSans.variable} ${anton.variable} ${jetbrainsMono.variable} antialiased`}>
        <ThemeProvider
            attribute="class"
            defaultTheme="dark" // Default to dark as requested
            enableSystem
            disableTransitionOnChange
          >
            <div className="flex h-screen overflow-hidden bg-background font-sans">
                <Sidebar />
                <main className="flex-1 overflow-y-auto relative z-0">
                    {children}
                </main>
            </div>
            <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
