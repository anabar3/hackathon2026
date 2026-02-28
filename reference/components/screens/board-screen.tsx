"use client"

import { ArrowLeft, SlidersHorizontal, MoreHorizontal, Sparkles, Globe, Lock } from "lucide-react"
import type { Board, ContentItem } from "@/lib/types"
import { ContentCard } from "@/components/content-card"
import { ScrollArea } from "@/components/ui/scroll-area"

interface BoardScreenProps {
  board: Board
  items: ContentItem[]
  onBack: () => void
  onItemSelect: (item: ContentItem) => void
  onEdit: () => void
  onAiOrganize?: () => void
}

export function BoardScreen({
  board,
  items,
  onBack,
  onItemSelect,
  onEdit,
  onAiOrganize,
}: BoardScreenProps) {
  const boardItems = items.filter((i) => i.boardId === board.id)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header className="px-4 pt-2 pb-3">
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Go back"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div className="flex items-center gap-2">
            {onAiOrganize && (
              <button
                onClick={onAiOrganize}
                className="h-9 px-3 rounded-full bg-primary/15 border border-primary/25 flex items-center justify-center gap-1.5 hover:bg-primary/25 transition-colors"
                aria-label="AI organize board"
              >
                <Sparkles className="w-3.5 h-3.5 text-primary" />
                <span className="text-[11px] font-semibold text-primary">AI</span>
              </button>
            )}
            <button
              className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
              aria-label="Filter content"
            >
              <SlidersHorizontal className="w-4 h-4 text-foreground" />
            </button>
            <button
              onClick={onEdit}
              className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
              aria-label="Board options"
            >
              <MoreHorizontal className="w-4 h-4 text-foreground" />
            </button>
          </div>
        </div>
        <div className="mt-3">
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-foreground">{board.name}</h1>
            <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-medium rounded-full bg-secondary text-muted-foreground">
              {board.isPublic ? <Globe className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
              {board.isPublic ? "Public" : "Private"}
            </span>
          </div>
          {board.description && (
            <p className="text-xs text-muted-foreground mt-0.5">{board.description}</p>
          )}
          <div className="flex items-center gap-3 mt-2">
            <span className="text-xs text-muted-foreground font-medium">
              {boardItems.length} items
            </span>
            <div className="flex items-center gap-1.5">
              {["All", "Images", "Videos", "Links", "Notes"].map((filter) => (
                <button
                  key={filter}
                  className={`px-3 py-1 rounded-full text-[11px] font-medium transition-colors ${
                    filter === "All"
                      ? "bg-primary text-primary-foreground"
                      : "bg-secondary text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {filter}
                </button>
              ))}
            </div>
          </div>
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-4">
          {/* Masonry Grid */}
          <div className="columns-2 gap-3">
            {boardItems.map((item) => (
              <div key={item.id} className="mb-3 break-inside-avoid">
                <ContentCard
                  item={item}
                  onClick={() => onItemSelect(item)}
                />
              </div>
            ))}
          </div>

          {boardItems.length === 0 && (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="w-16 h-16 rounded-2xl bg-secondary flex items-center justify-center mb-4">
                <SlidersHorizontal className="w-8 h-8 text-muted-foreground" />
              </div>
              <p className="text-sm font-medium text-foreground">No items yet</p>
              <p className="text-xs text-muted-foreground mt-1">
                Add content to this board
              </p>
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
