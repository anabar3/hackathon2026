"use client"

import { Bookmark, Folder, ChevronRight } from "lucide-react"
import type { ContentItem } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"
import { boards } from "@/lib/mock-data"
import { ContentCard } from "@/components/content-card"

interface SavedScreenProps {
  items: ContentItem[]
  onItemSelect: (item: ContentItem) => void
}

export function SavedScreen({ items, onItemSelect }: SavedScreenProps) {
  const savedItems = items.filter((item) => item.saved)

  // Group by board
  const grouped = savedItems.reduce<Record<string, ContentItem[]>>((acc, item) => {
    const key = item.boardId
    if (!acc[key]) acc[key] = []
    acc[key].push(item)
    return acc
  }, {})

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header className="px-5 pt-2 pb-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-foreground tracking-tight">Saved</h1>
            <p className="text-[11px] text-muted-foreground">
              {savedItems.length} item{savedItems.length !== 1 ? "s" : ""} bookmarked
            </p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center">
            <Bookmark className="w-5 h-5 text-primary" />
          </div>
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-4">
          {savedItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <div className="w-14 h-14 rounded-2xl bg-secondary flex items-center justify-center mb-4">
                <Bookmark className="w-7 h-7 text-muted-foreground" />
              </div>
              <p className="text-sm font-medium text-foreground">No saved items</p>
              <p className="text-xs text-muted-foreground mt-1">Tap the bookmark icon on any item to save it here.</p>
            </div>
          ) : (
            Object.entries(grouped).map(([boardId, groupItems]) => {
              const board = boards.find((b) => b.id === boardId)
              return (
                <div key={boardId} className="mb-6">
                  <div className="flex items-center gap-2 mb-3 px-1">
                    <Folder className="w-3.5 h-3.5 text-muted-foreground" />
                    <h2 className="text-[11px] font-semibold text-muted-foreground uppercase tracking-widest">
                      {board?.name || boardId}
                    </h2>
                    <span className="text-[10px] text-muted-foreground">({groupItems.length})</span>
                  </div>
                  <div className="grid grid-cols-2 gap-2.5">
                    {groupItems.map((item) => (
                      <ContentCard
                        key={item.id}
                        item={item}
                        onClick={() => onItemSelect(item)}
                      />
                    ))}
                  </div>
                </div>
              )
            })
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
