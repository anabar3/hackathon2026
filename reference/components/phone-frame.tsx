"use client"

import type { ReactNode } from "react"

export function PhoneFrame({ children }: { children: ReactNode }) {
  return (
    <div className="relative mx-auto w-[375px] h-[812px] rounded-[3.5rem] bg-background border-4 border-border overflow-hidden">
      {/* Notch / Speaker hole */}
      <div className="absolute top-[8px] left-1/2 -translate-x-1/2 w-[60px] h-[6px] bg-border rounded-full z-50 opacity-80" />
      {/* Status bar */}
      <div className="relative z-40 flex items-center justify-between px-8 pt-5 pb-2">
        <span className="text-xs font-bold text-foreground">12:29 PM</span>
        <div className="flex items-center gap-1">
          <div className="w-5 h-3 rounded-[3px] border-2 border-foreground/30 relative">
            <div className="absolute inset-[1px] bg-foreground/50 rounded-[1px]" style={{ width: "80%" }} />
          </div>
        </div>
      </div>
      {/* Content area */}
      <div className="h-[calc(100%-40px)] flex flex-col overflow-hidden bg-background">
        {children}
      </div>
      {/* Home indicator */}
      <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1.5 bg-foreground/20 rounded-full z-50" />
    </div>
  )
}
