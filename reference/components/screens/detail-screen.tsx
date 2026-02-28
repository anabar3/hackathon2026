"use client"

import {
  ArrowLeft,
  Bookmark,
  Share2,
  MoreHorizontal,
  Play,
  Link2,
  Headphones,
  StickyNote,
  FileText,
  File,
  ExternalLink,
  Calendar,
  Tag,
  Folder,
  Globe,
  Lock,
} from "lucide-react"
import type { ContentItem } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"
import { boards } from "@/lib/mock-data"

interface DetailScreenProps {
  item: ContentItem
  onBack: () => void
  onToggleSaved?: (itemId: string) => void
}

const typeIcons: Record<string, React.ReactNode> = {
  video: <Play className="w-5 h-5" />,
  link: <Link2 className="w-5 h-5" />,
  audio: <Headphones className="w-5 h-5" />,
  note: <StickyNote className="w-5 h-5" />,
  document: <FileText className="w-5 h-5" />,
  file: <File className="w-5 h-5" />,
}

export function DetailScreen({ item, onBack, onToggleSaved }: DetailScreenProps) {
  const board = boards.find((b) => b.id === item.boardId)
  const hasImage = item.thumbnail && (item.type === "image" || item.type === "video" || item.type === "link")

  return (
    <div className="flex flex-col h-full">
      {/* Header overlay */}
      <header className="absolute top-8 left-0 right-0 px-4 z-30 flex items-center justify-between">
        <button
          onClick={onBack}
          className="w-9 h-9 rounded-full bg-background/80 backdrop-blur-sm flex items-center justify-center hover:bg-background transition-colors"
          aria-label="Go back"
        >
          <ArrowLeft className="w-5 h-5 text-foreground" />
        </button>
        <div className="flex items-center gap-2">
          <button
            onClick={() => onToggleSaved?.(item.id)}
            className="w-9 h-9 rounded-full bg-background/80 backdrop-blur-sm flex items-center justify-center hover:bg-background transition-colors"
            aria-label={item.saved ? "Remove from saved" : "Save item"}
          >
            <Bookmark
              className={`w-5 h-5 transition-colors ${
                item.saved ? "fill-primary text-primary" : "text-foreground"
              }`}
            />
          </button>
          <button
            className="w-9 h-9 rounded-full bg-background/80 backdrop-blur-sm flex items-center justify-center hover:bg-background transition-colors"
            aria-label="Share"
          >
            <Share2 className="w-4 h-4 text-foreground" />
          </button>
          <button
            className="w-9 h-9 rounded-full bg-background/80 backdrop-blur-sm flex items-center justify-center hover:bg-background transition-colors"
            aria-label="More options"
          >
            <MoreHorizontal className="w-4 h-4 text-foreground" />
          </button>
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        {/* Hero Image */}
        {hasImage ? (
          <div className="relative w-full h-72">
            <img
              src={item.thumbnail}
              alt={item.title}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-transparent" />
            {item.type === "video" && (
              <button
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-16 h-16 rounded-full bg-primary/90 flex items-center justify-center shadow-2xl shadow-primary/40"
                aria-label="Play video"
              >
                <Play className="w-7 h-7 text-primary-foreground ml-1" fill="currentColor" />
              </button>
            )}
          </div>
        ) : (
          <div className="w-full h-40 bg-secondary flex items-center justify-center">
            <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
              {typeIcons[item.type] || <File className="w-8 h-8" />}
            </div>
          </div>
        )}

        {/* Content */}
        <div className="px-5 -mt-4 relative z-10">
          {/* Type badge */}
          <div className="flex items-center gap-2 mb-2">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-semibold bg-primary/15 text-primary rounded-full capitalize">
              {typeIcons[item.type] && (
                <span className="w-3.5 h-3.5 flex items-center justify-center">
                  {typeIcons[item.type]}
                </span>
              )}
              {item.type}
            </span>
            {board && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-medium bg-secondary text-muted-foreground rounded-full">
                {board.isPublic ? <Globe className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
                {board.isPublic ? "Public" : "Private"}
              </span>
            )}
          </div>

          <h1 className="text-xl font-bold text-foreground leading-tight text-balance">{item.title}</h1>

          {item.author && (
            <p className="text-sm text-muted-foreground mt-1">by {item.author}</p>
          )}

          {item.description && (
            <p className="text-sm text-secondary-foreground leading-relaxed mt-4">
              {item.description}
            </p>
          )}

          {/* Metadata */}
          <div className="mt-6 flex flex-col gap-3">
            <div className="flex items-center gap-3 text-sm text-muted-foreground">
              <Calendar className="w-4 h-4" />
              <span>Added {item.createdAt}</span>
            </div>
            {board && (
              <div className="flex items-center gap-3 text-sm text-muted-foreground">
                <Folder className="w-4 h-4" />
                <span>{board.name}</span>
              </div>
            )}
            {item.duration && (
              <div className="flex items-center gap-3 text-sm text-muted-foreground">
                <Play className="w-4 h-4" />
                <span>{item.duration}</span>
              </div>
            )}
            {item.size && (
              <div className="flex items-center gap-3 text-sm text-muted-foreground">
                <File className="w-4 h-4" />
                <span>{item.size}</span>
              </div>
            )}
          </div>

          {/* Tags */}
          {item.tags.length > 0 && (
            <div className="mt-6">
              <div className="flex items-center gap-2 mb-2">
                <Tag className="w-4 h-4 text-muted-foreground" />
                <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Tags</span>
              </div>
              <div className="flex flex-wrap gap-2">
                {item.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 rounded-full bg-secondary text-xs font-medium text-secondary-foreground"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Actions */}
          {item.url && (
            <div className="mt-6">
              <button className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-primary text-primary-foreground font-semibold text-sm transition-colors hover:bg-primary/90">
                <ExternalLink className="w-4 h-4" />
                Open Link
              </button>
            </div>
          )}

          {item.type === "audio" && (
            <div className="mt-6">
              <div className="p-4 rounded-xl bg-secondary border border-border/50">
                <div className="flex items-center gap-3">
                  <button
                    className="w-10 h-10 rounded-full bg-primary flex items-center justify-center flex-shrink-0"
                    aria-label="Play audio"
                  >
                    <Play className="w-5 h-5 text-primary-foreground ml-0.5" fill="currentColor" />
                  </button>
                  <div className="flex-1">
                    <div className="w-full h-1 bg-border rounded-full overflow-hidden">
                      <div className="w-1/3 h-full bg-primary rounded-full" />
                    </div>
                    <div className="flex justify-between mt-1">
                      <span className="text-[10px] text-muted-foreground">15:23</span>
                      <span className="text-[10px] text-muted-foreground">{item.duration}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
