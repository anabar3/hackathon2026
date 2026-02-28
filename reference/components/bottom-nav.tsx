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
      className="absolute bottom-0 left-0 right-0 bg-card/95 backdrop-blur-xl border-t border-border z-40 pb-6"
      role="navigation"
      aria-label="Main navigation"
    >
      <div className="flex items-center justify-around px-4 pt-2">
        <button
          onClick={() => onNavigate("dashboard")}
          className={`flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors ${
            activeScreen === "dashboard"
              ? "text-primary"
              : "text-muted-foreground hover:text-foreground"
          }`}
          aria-label="Home"
          aria-current={activeScreen === "dashboard" ? "page" : undefined}
        >
          <LayoutGrid className="w-5 h-5" />
          <span className="text-[10px] font-medium">Home</span>
        </button>

        <button
          onClick={() => onNavigate("drift")}
          className={`flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors ${
            activeScreen === "drift" || activeScreen === "person-boards"
              ? "text-primary"
              : "text-muted-foreground hover:text-foreground"
          }`}
          aria-label="Drift"
          aria-current={activeScreen === "drift" ? "page" : undefined}
        >
          <Radio className="w-5 h-5" />
          <span className="text-[10px] font-medium">Drift</span>
        </button>

        <button
          onClick={onAdd}
          className="flex items-center justify-center w-12 h-12 -mt-4 rounded-2xl bg-primary text-primary-foreground shadow-lg shadow-primary/30 transition-transform hover:scale-105 active:scale-95"
          aria-label="Open inbox"
        >
          <Plus className="w-6 h-6" strokeWidth={2.5} />
        </button>

        <button
          onClick={() => onNavigate("saved")}
          className={`flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors ${
            activeScreen === "saved"
              ? "text-primary"
              : "text-muted-foreground hover:text-foreground"
          }`}
          aria-label="Saved"
          aria-current={activeScreen === "saved" ? "page" : undefined}
        >
          <Bookmark className="w-5 h-5" />
          <span className="text-[10px] font-medium">Saved</span>
        </button>

        <button
          className="flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl text-muted-foreground hover:text-foreground transition-colors"
          aria-label="Profile"
        >
          <User className="w-5 h-5" />
          <span className="text-[10px] font-medium">Profile</span>
        </button>
      </div>
    </nav>
  )
}
