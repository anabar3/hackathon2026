"use client"

import {
  ArrowLeft,
  MapPin,
  Clock,
  Compass,
  Palette,
  ChefHat,
  Mountain,
  Building,
  BookOpen,
} from "lucide-react"
import type { NearbyPerson } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"

interface PersonBoardsScreenProps {
  person: NearbyPerson
  onBack: () => void
}

const iconMap: Record<string, React.ReactNode> = {
  compass: <Compass className="w-4 h-4" />,
  palette: <Palette className="w-4 h-4" />,
  "chef-hat": <ChefHat className="w-4 h-4" />,
  mountain: <Mountain className="w-4 h-4" />,
  building: <Building className="w-4 h-4" />,
  "book-open": <BookOpen className="w-4 h-4" />,
}

export function PersonBoardsScreen({ person, onBack }: PersonBoardsScreenProps) {
  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header className="px-4 pt-2 pb-4">
        <div className="flex items-center gap-3 mb-4">
          <button
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Go back"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <span className="text-sm font-medium text-muted-foreground">Back to Drift</span>
        </div>

        {/* Profile */}
        <div className="flex items-center gap-4">
          <img
            src={person.avatar}
            alt={person.name}
            className="w-16 h-16 rounded-full object-cover border-2 border-border"
          />
          <div className="flex-1 min-w-0">
            <h1 className="text-lg font-bold text-foreground truncate">{person.name}</h1>
            <p className="text-xs text-muted-foreground">{person.bio}</p>
            <div className="flex items-center gap-3 mt-1.5">
              <span className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
                <MapPin className="w-3 h-3" />
                {person.lastSeenLocation}
              </span>
              <span className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
                <Clock className="w-3 h-3" />
                {person.lastSeenTime}
              </span>
            </div>
          </div>
        </div>

        {/* Shared interests */}
        <div className="flex items-center gap-2 mt-3">
          {person.sharedInterests.map((interest) => (
            <span
              key={interest}
              className="px-2.5 py-1 text-[10px] font-medium rounded-full bg-primary/10 text-primary border border-primary/20"
            >
              {interest}
            </span>
          ))}
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0">
        <div className="px-4 pb-8">
          <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
            Public Boards ({person.publicBoards.length})
          </h2>

          <div className="flex flex-col gap-3">
            {person.publicBoards.map((board) => (
              <div
                key={board.id}
                className="relative overflow-hidden rounded-2xl bg-card border border-border/50 transition-all hover:border-primary/30"
              >
                {board.coverImage && (
                  <div className="relative h-24 overflow-hidden">
                    <img
                      src={board.coverImage}
                      alt={board.name}
                      className="w-full h-full object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-card via-card/30 to-transparent" />
                  </div>
                )}
                <div className={`p-4 ${board.coverImage ? "-mt-6 relative z-10" : ""}`}>
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center text-primary flex-shrink-0">
                      {iconMap[board.icon] || <Compass className="w-4 h-4" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-sm font-semibold text-foreground truncate">{board.name}</h3>
                      <p className="text-[10px] text-muted-foreground">{board.itemCount} items</p>
                    </div>
                  </div>
                  {board.description && (
                    <p className="text-[11px] text-muted-foreground mt-2 leading-relaxed">{board.description}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </ScrollArea>
    </div>
  )
}
