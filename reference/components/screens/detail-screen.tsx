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
          className="w-10 h-10 rounded-full bg-background/90 backdrop-blur-md flex items-center justify-center ac-button shadow-sm"
          aria-label="Go back"
        >
          <ArrowLeft className="w-5 h-5 text-foreground" strokeWidth={2.5} />
        </button>
        <div className="flex items-center gap-2">
          <button
            onClick={() => onToggleSaved?.(item.id)}
            className="w-10 h-10 rounded-full bg-background/90 backdrop-blur-md flex items-center justify-center ac-button shadow-sm"
            aria-label={item.saved ? "Remove from saved" : "Save item"}
          >
            <Bookmark
              className={`w-5 h-5 ${item.saved ? "fill-primary text-primary" : "text-foreground"
                }`}
            />
          </button>
          <button
            className="w-10 h-10 rounded-full bg-background/90 backdrop-blur-md flex items-center justify-center ac-button shadow-sm"
            aria-label="Share"
          >
            <Share2 className="w-5 h-5 text-foreground" strokeWidth={2.5} />
          </button>
          <button
            className="w-10 h-10 rounded-full bg-background/90 backdrop-blur-md flex items-center justify-center ac-button shadow-sm"
            aria-label="More options"
          >
            <MoreHorizontal className="w-5 h-5 text-foreground" strokeWidth={2.5} />
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
            <div className="absolute inset-0 bg-linear-to-t from-background via-transparent to-transparent" />
            {item.type === "video" && (
              <button
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-16 h-16 rounded-full bg-primary/90 flex items-center justify-center shadow-lg ac-button"
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

        {/* Content Card (Passport/Critterpedia style) */}
        <div className="px-4 -mt-6 relative z-10 pb-12">
          <div className="ac-card bg-background p-5 pt-6">
            {/* Type badge */}
            <div className="flex items-center gap-2 mb-4">
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 text-[11px] font-bold bg-primary text-primary-foreground rounded-full capitalize shadow-sm">
                {typeIcons[item.type] && (
                  <span className="w-3.5 h-3.5 flex items-center justify-center">
                    {typeIcons[item.type]}
                  </span>
                )}
                {item.type}
              </span>
              {board && (
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-[10px] font-bold bg-secondary text-muted-foreground border border-border/50 rounded-full shadow-sm">
                  {board.isPublic ? <Globe className="w-3.5 h-3.5" strokeWidth={2.5} /> : <Lock className="w-3.5 h-3.5" strokeWidth={2.5} />}
                  {board.isPublic ? "Public" : "Private"}
                </span>
              )}
            </div>

            <h1 className="text-2xl font-extrabold text-foreground leading-tight text-balance mb-2">{item.title}</h1>

            {item.author && (
              <p className="text-sm font-semibold text-muted-foreground mb-4">by {item.author}</p>
            )}

            {item.description && (
              <p className="text-sm text-secondary-foreground leading-relaxed mb-6 font-medium">
                {item.description}
              </p>
            )}

            {/* Metadata Grid */}
            <div className="grid grid-cols-2 gap-4 py-4 border-y-2 border-border/50 bg-secondary/20 p-4 rounded-[1rem] mb-6">
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

          </div>

          {/* Tags */}
          {item.tags.length > 0 && (
            <div className="mb-6">
              <div className="flex items-center gap-2 mb-3">
                <Tag className="w-4 h-4 text-primary" strokeWidth={2.5} />
                <span className="text-xs font-bold text-foreground uppercase tracking-wider">Tags</span>
              </div>
              <div className="flex flex-wrap gap-2">
                {item.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1.5 rounded-full bg-secondary border-2 border-border/50 text-xs font-bold text-secondary-foreground"
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
              <button className="w-full flex items-center justify-center gap-2 py-3.5 rounded-full bg-primary text-primary-foreground font-bold text-sm ac-button shadow-md">
                <ExternalLink className="w-4 h-4" strokeWidth={2.5} />
                Open Link
              </button>
            </div>
          )}

          {item.type === "audio" && (
            <div className="mt-6">
              <div className="p-4 rounded-[1rem] bg-secondary border-2 border-border/50">
                <div className="flex items-center gap-3">
                  <button
                    className="w-10 h-10 rounded-full bg-primary flex items-center justify-center shrink-0 active:translate-y-0.5 transition-all border-2 border-border"
                    aria-label="Play audio"
                  >
                    <Play className="w-5 h-5 text-primary-foreground ml-0.5" fill="currentColor" />
                  </button>
                  <div className="flex-1">
                    <div className="w-full h-1.5 bg-border rounded-full overflow-hidden">
                      <div className="w-1/3 h-full bg-primary rounded-full" />
                    </div>
                    <div className="flex justify-between mt-1.5">
                      <span className="text-[10px] font-bold text-muted-foreground">15:23</span>
                      <span className="text-[10px] font-bold text-muted-foreground">{item.duration}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </ScrollArea >
    </div >
  )
}
