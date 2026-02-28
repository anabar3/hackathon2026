"use client"

import {
  LayoutGrid,
  Radio,
  Plus,
  Bookmark,
  User,
} from "lucide-react"
import type { Screen } from "@/lib/types"

interface BottomNavProps {
  activeScreen: Screen
  onNavigate: (screen: Screen) => void
  onAdd: () => void
}

export function BottomNav({ activeScreen, onNavigate, onAdd }: BottomNavProps) {
  return (
    <nav
      className="absolute bottom-0 left-0 right-0 bg-background/90 backdrop-blur-md border-t-[3px] border-border z-40 pb-6"
      role="navigation"
      aria-label="Main navigation"
    >
      <div className="flex items-center justify-around px-4 pt-3">
        <button
          onClick={() => onNavigate("dashboard")}
          className={`flex flex-col items-center gap-1 px-4 py-2 rounded-full transition-colors ac-button ${activeScreen === "dashboard"
            ? "text-primary-foreground bg-primary"
            : "text-muted-foreground hover:bg-secondary"
            }`}
          aria-label="Home"
          aria-current={activeScreen === "dashboard" ? "page" : undefined}
        >
          <LayoutGrid className="w-5 h-5" strokeWidth={2.5} />
          <span className="text-[10px] font-bold">Home</span>
        </button>

        <button
          onClick={() => onNavigate("drift")}
          className={`flex flex-col items-center gap-1 px-4 py-2 rounded-full transition-colors ac-button ${activeScreen === "drift" || activeScreen === "person-boards"
            ? "text-primary-foreground bg-primary"
            : "text-muted-foreground hover:bg-secondary"
            }`}
          aria-label="Street"
          aria-current={activeScreen === "drift" ? "page" : undefined}
        >
          <Radio className="w-5 h-5" strokeWidth={2.5} />
          <span className="text-[10px] font-bold">Street</span>
        </button>

        <div className="relative">
          <button
            onClick={() => onNavigate("add")}
            className={`flex items-center justify-center w-14 h-14 -mt-6 rounded-full text-accent-foreground border-3 border-border transition-transform active:translate-y-1 relative ${activeScreen === "add" ? "bg-accent shadow-inner" : "bg-card"}`}
            aria-label="Open inbox"
          >
            <Plus className="w-7 h-7" strokeWidth={3} />
            <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full border-2 border-background" />
          </button>
          <span className="absolute -bottom-5 left-1/2 -translate-x-1/2 text-[10px] font-bold text-muted-foreground">Inbox</span>
        </div>

        <button
          onClick={() => onNavigate("letters")}
          className={`flex flex-col items-center gap-1 px-4 py-2 rounded-full transition-colors ac-button ${activeScreen === "letters"
            ? "text-primary-foreground bg-primary"
            : "text-muted-foreground hover:bg-secondary"
            }`}
          aria-label="Letters"
          aria-current={activeScreen === "letters" ? "page" : undefined}
        >
          <Bookmark className="w-5 h-5" strokeWidth={2.5} />
          <span className="text-[10px] font-bold">Letters</span>
        </button>

        <button
          className="flex flex-col items-center gap-1 px-4 py-2 rounded-full text-muted-foreground hover:bg-secondary transition-colors ac-button"
          aria-label="Profile"
        >
          <User className="w-5 h-5" strokeWidth={2.5} />
          <span className="text-[10px] font-bold">Profile</span>
        </button>
      </div>
    </nav>
  )
}
