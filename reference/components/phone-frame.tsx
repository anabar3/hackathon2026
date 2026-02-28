"use client"

import type { ReactNode } from "react"

export function PhoneFrame({ children }: { children: ReactNode }) {
  return (
    <div className="relative mx-auto w-[375px] h-[812px] rounded-[3rem] bg-card border-2 border-border shadow-2xl shadow-black/40 overflow-hidden">
      {/* Notch */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[28px] bg-background rounded-b-2xl z-50" />
      {/* Status bar */}
      <div className="relative z-40 flex items-center justify-between px-8 pt-3 pb-1">
        <span className="text-xs font-medium text-foreground">9:41</span>
        <div className="flex items-center gap-1">
          <div className="w-4 h-2.5 rounded-sm border border-foreground/60 relative">
            <div className="absolute inset-0.5 bg-foreground/60 rounded-[1px]" style={{ width: "70%" }} />
          </div>
        </div>
      </div>
      {/* Content area */}
      <div className="h-[calc(100%-28px)] flex flex-col overflow-hidden">
        {children}
      </div>
      {/* Home indicator */}
      <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-foreground/30 rounded-full z-50" />
    </div>
  )
}
