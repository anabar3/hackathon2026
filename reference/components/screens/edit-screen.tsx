"use client"

import {
  ArrowLeft,
  GripVertical,
  Trash2,
  Edit3,
  Check,
  Image,
  Video,
  Link2,
  Headphones,
  StickyNote,
  FileText,
  File,
} from "lucide-react"
import type { Board, ContentItem } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"
import { useState } from "react"

interface EditScreenProps {
  board: Board
  items: ContentItem[]
  onBack: () => void
}

const typeIcons: Record<string, React.ReactNode> = {
  image: <Image className="w-4 h-4" />,
  video: <Video className="w-4 h-4" />,
  link: <Link2 className="w-4 h-4" />,
  audio: <Headphones className="w-4 h-4" />,
  note: <StickyNote className="w-4 h-4" />,
  document: <FileText className="w-4 h-4" />,
  file: <File className="w-4 h-4" />,
}

export function EditScreen({ board, items, onBack }: EditScreenProps) {
  const boardItems = items.filter((i) => i.boardId === board.id)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [editingName, setEditingName] = useState(false)
  const [boardName, setBoardName] = useState(board.name)

  const toggleSelect = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  const selectAll = () => {
    if (selected.size === boardItems.length) {
      setSelected(new Set())
    } else {
      setSelected(new Set(boardItems.map((i) => i.id)))
    }
  }

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <header className="px-5 pt-2 pb-4 border-b border-border">
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Go back"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <h1 className="text-base font-semibold text-foreground">Edit Board</h1>
          <button
            onClick={onBack}
            className="text-xs font-semibold text-primary"
          >
            Done
          </button>
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-5 pt-4">
          {/* Board Settings */}
          <section className="mb-6">
            <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              Board Details
            </h2>
            <div className="p-4 rounded-xl bg-secondary border border-border/50">
              {/* Board Name */}
              <div className="flex items-center justify-between mb-3 pb-3 border-b border-border/50">
                <div className="flex-1">
                  <label className="text-[11px] text-muted-foreground font-medium block mb-1">Name</label>
                  {editingName ? (
                    <input
                      type="text"
                      value={boardName}
                      onChange={(e) => setBoardName(e.target.value)}
                      className="w-full bg-transparent text-sm font-semibold text-foreground outline-none border-b border-primary"
                      autoFocus
                    />
                  ) : (
                    <p className="text-sm font-semibold text-foreground">{boardName}</p>
                  )}
                </div>
                <button
                  onClick={() => setEditingName(!editingName)}
                  className="w-8 h-8 rounded-lg bg-background flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
                  aria-label={editingName ? "Save name" : "Edit name"}
                >
                  {editingName ? <Check className="w-4 h-4" /> : <Edit3 className="w-4 h-4" />}
                </button>
              </div>
              {/* Board Description */}
              <div>
                <label htmlFor="board-desc" className="text-[11px] text-muted-foreground font-medium block mb-1">Description</label>
                <textarea
                  id="board-desc"
                  defaultValue={board.description}
                  rows={2}
                  className="w-full bg-transparent text-sm text-secondary-foreground outline-none resize-none placeholder:text-muted-foreground"
                  placeholder="Add a description..."
                />
              </div>
            </div>
          </section>

          {/* Board Cover */}
          <section className="mb-6">
            <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              Cover Image
            </h2>
            <div className="relative h-28 rounded-xl overflow-hidden bg-secondary border border-border/50">
              {board.coverImage ? (
                <img src={board.coverImage} alt="Board cover" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <Image className="w-8 h-8 text-muted-foreground" />
                </div>
              )}
              <div className="absolute inset-0 bg-background/40 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity">
                <span className="text-xs font-medium text-foreground bg-background/80 px-3 py-1.5 rounded-lg backdrop-blur-sm">
                  Change Cover
                </span>
              </div>
            </div>
          </section>

          {/* Content Items */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Items ({boardItems.length})
              </h2>
              <button
                onClick={selectAll}
                className="text-xs text-primary font-medium"
              >
                {selected.size === boardItems.length ? "Deselect All" : "Select All"}
              </button>
            </div>

            {/* Selection Actions */}
            {selected.size > 0 && (
              <div className="flex items-center gap-2 mb-3 p-3 rounded-xl bg-primary/10 border border-primary/20">
                <span className="text-xs font-medium text-primary flex-1">
                  {selected.size} selected
                </span>
                <button className="px-3 py-1.5 rounded-lg bg-secondary text-xs font-medium text-foreground hover:bg-secondary/80 transition-colors">
                  Move
                </button>
                <button className="px-3 py-1.5 rounded-lg bg-destructive/10 text-xs font-medium text-destructive hover:bg-destructive/20 transition-colors">
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            )}

            <div className="flex flex-col gap-2">
              {boardItems.map((item) => (
                <div
                  key={item.id}
                  className={`flex items-center gap-3 p-3 rounded-xl border transition-all ${
                    selected.has(item.id)
                      ? "bg-primary/5 border-primary/30"
                      : "bg-secondary border-border/50"
                  }`}
                >
                  <button
                    className="text-muted-foreground hover:text-foreground cursor-grab active:cursor-grabbing"
                    aria-label="Drag to reorder"
                  >
                    <GripVertical className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => toggleSelect(item.id)}
                    className={`w-5 h-5 rounded-md border-2 flex items-center justify-center flex-shrink-0 transition-colors ${
                      selected.has(item.id)
                        ? "bg-primary border-primary"
                        : "border-border hover:border-muted-foreground"
                    }`}
                    aria-label={selected.has(item.id) ? "Deselect item" : "Select item"}
                  >
                    {selected.has(item.id) && <Check className="w-3 h-3 text-primary-foreground" />}
                  </button>
                  {item.thumbnail ? (
                    <div className="w-10 h-10 rounded-lg overflow-hidden flex-shrink-0">
                      <img src={item.thumbnail} alt="" className="w-full h-full object-cover" />
                    </div>
                  ) : (
                    <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center flex-shrink-0 text-primary">
                      {typeIcons[item.type]}
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <h3 className="text-sm font-medium text-foreground truncate">{item.title}</h3>
                    <p className="text-[11px] text-muted-foreground capitalize">{item.type}</p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* Danger Zone */}
          <section className="mt-8 mb-4">
            <button className="w-full py-3 rounded-xl border border-destructive/30 text-sm font-medium text-destructive hover:bg-destructive/10 transition-colors">
              Delete Board
            </button>
          </section>
        </div>
      </ScrollArea>
    </div>
  )
}
