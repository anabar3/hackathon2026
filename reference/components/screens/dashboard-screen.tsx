"use client"

import { Bell, ChevronRight, Compass, Palette, ChefHat, Mountain, Building, BookOpen, Globe, Lock, Search, Filter } from "lucide-react"
import type { Board } from "@/lib/types"
import { ScrollArea, ScrollBar } from "@/components/ui/scroll-area"

interface DashboardScreenProps {
  boards: Board[]
  onBoardSelect: (board: Board) => void
}

const iconMap: Record<string, React.ReactNode> = {
  compass: <Compass className="w-5 h-5" />,
  palette: <Palette className="w-5 h-5" />,
  "chef-hat": <ChefHat className="w-5 h-5" />,
  mountain: <Mountain className="w-5 h-5" />,
  building: <Building className="w-5 h-5" />,
  "book-open": <BookOpen className="w-5 h-5" />,
}

export function DashboardScreen({ boards, onBoardSelect }: DashboardScreenProps) {
  return (
    <div className="flex flex-col h-full">
      {/* Search Header */}
      <header className="px-4 pt-4 pb-2 z-10 bg-background/95 backdrop-blur shadow-sm sticky top-0">
        <div className="flex items-center gap-3 w-full">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" strokeWidth={3} />
            <input
              type="text"
              placeholder="Search pins or boards..."
              className="w-full h-11 pl-10 pr-4 bg-card border-3 border-border rounded-full text-foreground placeholder:text-muted-foreground text-sm font-bold focus:outline-none focus:border-primary transition-colors"
            />
          </div>
          <button
            className="w-11 h-11 rounded-full bg-secondary flex items-center justify-center ac-button shrink-0"
            aria-label="Filter"
          >
            <Filter className="w-5 h-5 text-foreground" strokeWidth={2.5} />
          </button>
          <button
            className="relative w-11 h-11 rounded-full bg-secondary flex items-center justify-center ac-button shrink-0"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 text-foreground" strokeWidth={2.5} />
            <span className="absolute top-2 right-2 w-2.5 h-2.5 bg-accent rounded-full border-2 border-background" />
          </button>
        </div>

        {/* Header visual separator */}
        <div className="w-full h-px bg-border mt-3" />
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-4 mt-2">
          {/* Masonry-style Board Previews */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-foreground uppercase tracking-wider">Pinned by you</h2>
              <button className="text-xs text-primary font-medium flex items-center gap-0.5">
                View all
                <ChevronRight className="w-3 h-3" />
              </button>
            </div>
            <button
              onClick={() => onBoardSelect(boards[0])}
              className="relative w-full h-40 ac-card ac-toon-shadow overflow-hidden group text-left transition-transform active:translate-y-1"
            >
              <img
                src={boards[0].coverImage}
                alt={boards[0].name}
                className="w-full h-full object-cover opacity-90 transition-opacity group-active:opacity-75"
              />
              <div className="absolute inset-0 bg-linear-to-t from-background/95 via-background/40 to-transparent" />
              <div className="absolute bottom-0 left-0 right-0 p-4">
                <div className="flex items-center gap-2">
                  <h3 className="text-lg font-bold text-foreground">{boards[0].name}</h3>
                  <span className="inline-flex items-center gap-1 px-1.5 py-0.5 text-[9px] font-semibold rounded-full bg-background/60 backdrop-blur-sm text-foreground">
                    {boards[0].isPublic ? <Globe className="w-2.5 h-2.5" /> : <Lock className="w-2.5 h-2.5" />}
                    {boards[0].isPublic ? "Public" : "Private"}
                  </span>
                </div>
                <p className="text-xs text-muted-foreground mt-0.5">
                  {boards[0].itemCount} items
                </p>
              </div>
            </button>
          </div>

          {/* Discover Boards Grid */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-foreground uppercase tracking-wider">Your Boards</h2>
            </div>
            <div className="columns-2 gap-3 space-y-3">
              {boards.map((board, i) => (
                <button
                  key={board.id}
                  onClick={() => onBoardSelect(board)}
                  className="w-full flex flex-col group ac-card ac-button overflow-hidden text-left break-inside-avoid"
                  style={{ borderRadius: 'var(--radius)' }}
                >
                  {/* Pinterest-like image preview area */}
                  <div className={`w-full relative bg-secondary/50 border-b-2 border-border/50 ${i % 2 === 0 ? 'h-32' : 'h-48'}`}>
                    {board.coverImage ? (
                      <img src={board.coverImage} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-primary/30">
                        {iconMap[board.icon] || <Compass className="w-8 h-8" />}
                      </div>
                    )}
                    <div className="absolute top-2 right-2">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-bold bg-background/90 text-muted-foreground border border-border shadow-sm">
                        {board.isPublic ? <Globe className="w-2.5 h-2.5 mr-0.5" /> : <Lock className="w-2.5 h-2.5 mr-0.5" />}
                        {board.isPublic ? "Public" : "Private"}
                      </span>
                    </div>
                  </div>
                  {/* AC Style details footer */}
                  <div className="p-3 bg-background">
                    <h3 className="text-sm font-bold text-foreground leading-tight truncate">{board.name}</h3>
                    <div className="flex items-center gap-2 mt-1.5 flex-wrap">
                      <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-secondary text-secondary-foreground border border-border/50">
                        {["For You", "Following", "Inspo", "DIY"][i % 4]}
                      </span>
                      <p className="text-[10px] font-semibold text-muted-foreground">{board.itemCount} items</p>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      </ScrollArea>
    </div>
  )
}
