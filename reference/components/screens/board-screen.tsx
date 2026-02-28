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
      {/* Header Container */}
      <div className="relative w-full">
        {/* Optional Hero Image */}
        {board.coverImage && (
          <div className="absolute inset-0 w-full h-48 sm:h-56 z-0 overflow-hidden rounded-b-[2.5rem]">
            <img
              src={board.coverImage}
              alt={board.name}
              className="w-full h-full object-cover opacity-90"
            />
            <div className="absolute inset-0 bg-linear-to-t from-background via-background/60 to-transparent" />
          </div>
        )}

        <header className="relative z-10 px-4 pt-12 pb-3">
          <div className="flex items-center justify-between">
            <button
              onClick={onBack}
              className="w-10 h-10 rounded-full bg-secondary/80 backdrop-blur-md flex items-center justify-center ac-button ac-toon-shadow-sm"
              aria-label="Go back"
            >
              <ArrowLeft className="w-5 h-5 text-foreground" strokeWidth={2.5} />
            </button>
            <div className="flex items-center gap-2">
              {onAiOrganize && (
                <button
                  onClick={onAiOrganize}
                  className="h-10 px-4 rounded-full bg-primary/90 text-primary-foreground backdrop-blur-md flex items-center justify-center gap-1.5 ac-button ac-toon-shadow-sm"
                  aria-label="AI organize board"
                >
                  <Sparkles className="w-4 h-4" strokeWidth={2.5} />
                  <span className="text-xs font-bold">AI</span>
                </button>
              )}
              <button
                className="w-10 h-10 rounded-full bg-secondary/80 backdrop-blur-md flex items-center justify-center ac-button ac-toon-shadow-sm"
                aria-label="Filter"
              >
                <SlidersHorizontal className="w-5 h-5 text-foreground" strokeWidth={2.5} />
              </button>
              <button
                onClick={onEdit}
                className="w-10 h-10 rounded-full bg-secondary/80 backdrop-blur-md flex items-center justify-center ac-button ac-toon-shadow-sm"
                aria-label="Board options"
              >
                <MoreHorizontal className="w-5 h-5 text-foreground" strokeWidth={2.5} />
              </button>
            </div>
          </div>

          <div className={`mt-${board.coverImage ? '16' : '3'}`}>
            <div className="flex flex-col gap-1.5">
              <h1 className="text-3xl font-extrabold text-foreground tracking-tight">{board.name}</h1>
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 text-[10px] font-bold rounded-full bg-foreground/10 text-foreground">
                  {board.isPublic ? <Globe className="w-3.5 h-3.5" strokeWidth={2.5} /> : <Lock className="w-3.5 h-3.5" strokeWidth={2.5} />}
                  {board.isPublic ? "Public" : "Private"}
                </span>
                <span className="text-xs text-muted-foreground font-medium bg-background/50 px-2 py-0.5 rounded-full">
                  {boardItems.length} items
                </span>
              </div>
            </div>
            {board.description && (
              <p className="text-sm text-muted-foreground font-medium mt-2 max-w-[90%]">{board.description}</p>
            )}
          </div>
        </header>
      </div>

      <div className="px-4">
        <div className="flex items-center gap-2 mt-2 mb-4 overflow-x-auto pb-2 scrollbar-hide">
          {["All", "Images", "Videos", "Links", "Notes"].map((filter) => (
            <button
              key={filter}
              className={`px-4 py-1.5 rounded-full text-xs font-bold whitespace-nowrap ac-button ${filter === "All"
                ? "bg-primary text-primary-foreground ac-toon-shadow-sm"
                : "bg-secondary text-muted-foreground"
                }`}
            >
              {filter}
            </button>
          ))}
        </div>
      </div>


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
