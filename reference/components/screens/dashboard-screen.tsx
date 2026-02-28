"use client"

import { Bell, ChevronRight, Compass, Palette, ChefHat, Mountain, Building, BookOpen, Globe, Lock } from "lucide-react"
import type { Board } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"

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
      {/* Header */}
      <header className="px-5 pt-2 pb-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-muted-foreground font-medium">Good evening</p>
            <h1 className="text-2xl font-bold text-foreground tracking-tight">Collect</h1>
          </div>
          <button
            className="relative w-10 h-10 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 text-foreground" />
            <span className="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full" />
          </button>
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-5">
          {/* Quick Stats */}
          <div className="flex items-center gap-3 mb-6">
            <div className="flex-1 p-3 rounded-xl bg-secondary border border-border/50">
              <p className="text-2xl font-bold text-foreground">109</p>
              <p className="text-[11px] text-muted-foreground">Total Items</p>
            </div>
            <div className="flex-1 p-3 rounded-xl bg-secondary border border-border/50">
              <p className="text-2xl font-bold text-primary">6</p>
              <p className="text-[11px] text-muted-foreground">Boards</p>
            </div>
            <div className="flex-1 p-3 rounded-xl bg-secondary border border-border/50">
              <p className="text-2xl font-bold text-foreground">3</p>
              <p className="text-[11px] text-muted-foreground">Recent</p>
            </div>
          </div>

          {/* Recent Board - Featured */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-foreground uppercase tracking-wider">Recent</h2>
              <button className="text-xs text-primary font-medium flex items-center gap-0.5">
                View all
                <ChevronRight className="w-3 h-3" />
              </button>
            </div>
            <button
              onClick={() => onBoardSelect(boards[0])}
              className="relative w-full h-40 rounded-2xl overflow-hidden group text-left"
            >
              <img
                src={boards[0].coverImage}
                alt={boards[0].name}
                className="w-full h-full object-cover transition-transform group-hover:scale-105 duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-background/90 via-background/30 to-transparent" />
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

          {/* Boards Grid */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-foreground uppercase tracking-wider">Your Boards</h2>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {boards.map((board) => (
                <button
                  key={board.id}
                  onClick={() => onBoardSelect(board)}
                  className="group relative overflow-hidden rounded-2xl bg-secondary border border-border/50 p-4 text-left transition-all hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5"
                >
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                      {iconMap[board.icon] || <Compass className="w-5 h-5" />}
                    </div>
                    <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[9px] font-medium bg-background/60 text-muted-foreground">
                      {board.isPublic ? <Globe className="w-2.5 h-2.5 mr-0.5" /> : <Lock className="w-2.5 h-2.5 mr-0.5" />}
                      {board.isPublic ? "Public" : "Private"}
                    </span>
                  </div>
                  <h3 className="text-sm font-semibold text-foreground leading-tight">{board.name}</h3>
                  <p className="text-[11px] text-muted-foreground mt-0.5">{board.itemCount} items</p>
                  {board.coverImage && (
                    <div className="absolute -bottom-2 -right-2 w-16 h-16 rounded-xl overflow-hidden opacity-20 group-hover:opacity-30 transition-opacity">
                      <img
                        src={board.coverImage}
                        alt=""
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>
      </ScrollArea>
    </div>
  )
}
