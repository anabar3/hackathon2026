"use client"

import type { Screen } from "@/lib/types"
import {
  LayoutGrid,
  Columns3,
  Eye,
  Inbox,
  Edit3,
  Sparkles,
  Radio,
  Bookmark,
  User,
} from "lucide-react"

interface ScreenSelectorProps {
  activeScreen: Screen
  onSelect: (screen: Screen) => void
}

const screens: { id: Screen; label: string; icon: React.ReactNode }[] = [
  { id: "dashboard", label: "Home", icon: <LayoutGrid className="w-4 h-4" /> },
  { id: "board", label: "Board", icon: <Columns3 className="w-4 h-4" /> },
  { id: "detail", label: "Detail", icon: <Eye className="w-4 h-4" /> },
  { id: "add", label: "Inbox", icon: <Inbox className="w-4 h-4" /> },
  { id: "edit", label: "Edit", icon: <Edit3 className="w-4 h-4" /> },
  { id: "ai-organize", label: "AI Organize", icon: <Sparkles className="w-4 h-4" /> },
  { id: "drift", label: "Street", icon: <Radio className="w-4 h-4" /> },
  { id: "letters", label: "Letters", icon: <Bookmark className="w-4 h-4" /> },
  { id: "person-boards", label: "Profile", icon: <User className="w-4 h-4" /> },
]

export function ScreenSelector({ activeScreen, onSelect }: ScreenSelectorProps) {
  return (
    <div className="flex flex-wrap items-center justify-center gap-2">
      {screens.map((s) => (
        <button
          key={s.id}
          onClick={() => onSelect(s.id)}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-bold transition-colors ac-button ${activeScreen === s.id
            ? "bg-foreground text-card shadow-md"
            : "bg-background text-foreground hover:bg-secondary border border-border/50"
            }`}
        >
          {s.icon}
          {s.label}
        </button>
      ))}
    </div>
  )
}
