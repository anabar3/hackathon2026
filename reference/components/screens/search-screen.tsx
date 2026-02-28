"use client"

import { Search, X, Image, Video, Link2, Headphones, StickyNote, FileText } from "lucide-react"
import type { ContentItem } from "@/lib/types"
import { ContentCard } from "@/components/content-card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { useState } from "react"

interface SearchScreenProps {
  items: ContentItem[]
  onItemSelect: (item: ContentItem) => void
}

const filters = [
  { label: "All", icon: null },
  { label: "Images", icon: <Image className="w-3.5 h-3.5" /> },
  { label: "Videos", icon: <Video className="w-3.5 h-3.5" /> },
  { label: "Links", icon: <Link2 className="w-3.5 h-3.5" /> },
  { label: "Audio", icon: <Headphones className="w-3.5 h-3.5" /> },
  { label: "Notes", icon: <StickyNote className="w-3.5 h-3.5" /> },
  { label: "Docs", icon: <FileText className="w-3.5 h-3.5" /> },
]

export function SearchScreen({ items, onItemSelect }: SearchScreenProps) {
  const [query, setQuery] = useState("")
  const [activeFilter, setActiveFilter] = useState("All")

  const filtered = items.filter((item) => {
    const matchesQuery =
      query === "" ||
      item.title.toLowerCase().includes(query.toLowerCase()) ||
      item.tags.some((t) => t.toLowerCase().includes(query.toLowerCase()))
    const matchesFilter =
      activeFilter === "All" ||
      (activeFilter === "Images" && item.type === "image") ||
      (activeFilter === "Videos" && item.type === "video") ||
      (activeFilter === "Links" && item.type === "link") ||
      (activeFilter === "Audio" && item.type === "audio") ||
      (activeFilter === "Notes" && item.type === "note") ||
      (activeFilter === "Docs" && (item.type === "document" || item.type === "file"))
    return matchesQuery && matchesFilter
  })

  return (
    <div className="flex flex-col h-full">
      {/* Search Header */}
      <header className="px-5 pt-2 pb-3">
        <h1 className="text-xl font-bold text-foreground mb-3">Search</h1>
        <div className="relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search content, tags..."
            className="w-full pl-10 pr-10 py-3 rounded-xl bg-secondary border border-border text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {query && (
            <button
              onClick={() => setQuery("")}
              className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 rounded-full bg-muted flex items-center justify-center"
              aria-label="Clear search"
            >
              <X className="w-3 h-3 text-muted-foreground" />
            </button>
          )}
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-2 mt-3 overflow-x-auto pb-1 -mx-1 px-1">
          {filters.map((f) => (
            <button
              key={f.label}
              onClick={() => setActiveFilter(f.label)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[11px] font-medium whitespace-nowrap transition-colors ${
                activeFilter === f.label
                  ? "bg-primary text-primary-foreground"
                  : "bg-secondary text-muted-foreground hover:text-foreground"
              }`}
            >
              {f.icon}
              {f.label}
            </button>
          ))}
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-4">
          {/* Results count */}
          <p className="text-xs text-muted-foreground mb-3 px-1">
            {filtered.length} result{filtered.length !== 1 ? "s" : ""}
          </p>

          {/* Masonry Grid */}
          <div className="columns-2 gap-3">
            {filtered.map((item) => (
              <div key={item.id} className="mb-3 break-inside-avoid">
                <ContentCard
                  item={item}
                  onClick={() => onItemSelect(item)}
                />
              </div>
            ))}
          </div>

          {filtered.length === 0 && (
            <div className="flex flex-col items-center justify-center py-20">
              <Search className="w-12 h-12 text-muted-foreground mb-3" />
              <p className="text-sm font-medium text-foreground">No results found</p>
              <p className="text-xs text-muted-foreground mt-1">
                Try a different search term or filter
              </p>
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
