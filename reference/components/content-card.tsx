"use client"

import {
  Play,
  Link2,
  Headphones,
  StickyNote,
  FileText,
  File,
  Bookmark,
} from "lucide-react"
import type { ContentItem } from "@/lib/types"

interface ContentCardProps {
  item: ContentItem
  onClick: () => void
}

function TypeBadge({ type }: { type: ContentItem["type"] }) {
  const config: Record<string, { icon: React.ReactNode; label: string }> = {
    image: { icon: null, label: "" },
    video: {
      icon: <Play className="w-3 h-3" />,
      label: "Video",
    },
    link: {
      icon: <Link2 className="w-3 h-3" />,
      label: "Link",
    },
    audio: {
      icon: <Headphones className="w-3 h-3" />,
      label: "Audio",
    },
    note: {
      icon: <StickyNote className="w-3 h-3" />,
      label: "Note",
    },
    document: {
      icon: <FileText className="w-3 h-3" />,
      label: "Doc",
    },
    file: {
      icon: <File className="w-3 h-3" />,
      label: "File",
    },
  }
  const c = config[type]
  if (!c || !c.icon) return null

  return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-medium bg-background/80 backdrop-blur-sm text-foreground rounded-full">
      {c.icon}
      {c.label}
    </span>
  )
}

export function ContentCard({ item, onClick }: ContentCardProps) {
  const hasImage = item.thumbnail && (item.type === "image" || item.type === "video" || item.type === "link")

  if (hasImage) {
    return (
      <button
        className="group relative w-full mb-4 break-inside-avoid overflow-hidden text-left ac-card ac-button active:translate-y-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        <div className="relative">
          <img
            src={item.thumbnail}
            alt={item.title}
            className="w-full object-cover"
          />
          {item.type !== "image" && (
            <div className="absolute top-2 left-2">
              <TypeBadge type={item.type} />
            </div>
          )}
          {item.duration && (
            <div className="absolute bottom-2 right-2 px-1.5 py-0.5 text-[10px] font-medium bg-background/80 backdrop-blur-sm text-foreground rounded">
              {item.duration}
            </div>
          )}
          {/* Saved indicator */}
          {item.saved && (
            <div className="absolute top-2 right-2">
              <div className="w-7 h-7 rounded-full bg-primary/90 backdrop-blur-sm flex items-center justify-center">
                <Bookmark className="w-3.5 h-3.5 text-primary-foreground fill-primary-foreground" />
              </div>
            </div>
          )}
        </div>
        <div className="p-3">
          <h3 className="text-sm font-semibold text-foreground leading-tight line-clamp-2">
            {item.title}
          </h3>
          {item.author && (
            <p className="text-[11px] text-muted-foreground mt-1">{item.author}</p>
          )}
        </div>
      </button>
    )
  }

  // Non-image cards (notes, audio, documents, files)
  const bgClasses: Record<string, string> = {
    note: "bg-primary/8",
    audio: "bg-primary/5",
    document: "bg-secondary/80",
    file: "bg-secondary/80",
  }

  const iconMap: Record<string, React.ReactNode> = {
    note: <StickyNote className="w-8 h-8 text-primary/60" />,
    audio: <Headphones className="w-8 h-8 text-primary/60" />,
    document: <FileText className="w-8 h-8 text-muted-foreground" />,
    file: <File className="w-8 h-8 text-muted-foreground" />,
  }

  return (
    <button
      className="group relative w-full mb-4 break-inside-avoid overflow-hidden text-left ac-card ac-button active:translate-y-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    >
      <div className={`p-4 ${bgClasses[item.type] || "bg-secondary"}`}>
        <div className="flex items-start justify-between mb-3">
          {iconMap[item.type]}
          {item.saved && (
            <div className="w-6 h-6 rounded-full bg-primary/90 flex items-center justify-center">
              <Bookmark className="w-3 h-3 text-primary-foreground fill-primary-foreground" />
            </div>
          )}
        </div>
        <h3 className="text-sm font-semibold text-foreground leading-tight line-clamp-2 mb-1">
          {item.title}
        </h3>
        {item.description && (
          <p className="text-[11px] text-muted-foreground line-clamp-3 leading-relaxed">
            {item.description}
          </p>
        )}
        <div className="flex items-center gap-2 mt-3">
          {item.duration && (
            <span className="text-[10px] text-primary font-medium">{item.duration}</span>
          )}
          {item.size && (
            <span className="text-[10px] text-muted-foreground font-medium">{item.size}</span>
          )}
          {item.tags.slice(0, 2).map((tag) => (
            <span
              key={tag}
              className="text-[10px] px-1.5 py-0.5 rounded-full bg-background/60 text-muted-foreground"
            >
              {tag}
            </span>
          ))}
        </div>
      </div>
    </button>
  )
}
