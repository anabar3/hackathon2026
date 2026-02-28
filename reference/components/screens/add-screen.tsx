"use client"

import {
  X,
  Camera,
  Link2,
  Mic,
  Image,
  Sparkles,
  Check,
  ArrowRight,
  FileUp,
  Pencil,
} from "lucide-react"
import { useState, useEffect, useCallback } from "react"
import { ScrollArea } from "@/components/ui/scroll-area"

interface AddScreenProps {
  onClose: () => void
}

type InboxPhase = "idle" | "dropped" | "processing" | "done"

interface ProcessedItem {
  title: string
  description: string
  suggestedBoard: string
  tags: string[]
  type: string
}

function ProcessingIndicator({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-2.5">
      <div className="relative w-4 h-4">
        <div className="absolute inset-0 rounded-full border-2 border-primary/30" />
        <div className="absolute inset-0 rounded-full border-2 border-primary border-t-transparent animate-spin" />
      </div>
      <span className="text-xs text-muted-foreground">{label}</span>
    </div>
  )
}

function CompletedStep({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-2.5">
      <div className="w-4 h-4 rounded-full bg-primary flex items-center justify-center">
        <Check className="w-2.5 h-2.5 text-primary-foreground" />
      </div>
      <span className="text-xs text-foreground">{label}</span>
    </div>
  )
}

const quickActions = [
  { icon: <Camera className="w-5 h-5" />, label: "Camera", accent: true },
  { icon: <Image className="w-5 h-5" />, label: "Photos" },
  { icon: <Link2 className="w-5 h-5" />, label: "Link" },
  { icon: <Mic className="w-5 h-5" />, label: "Voice" },
  { icon: <FileUp className="w-5 h-5" />, label: "File" },
]

const recentDrops = [
  { name: "IMG_2847.jpg", time: "2 min ago", board: "Travel Inspo", status: "sorted" },
  { name: "recipe-link.url", time: "15 min ago", board: "Recipes", status: "sorted" },
  { name: "voice-memo-03.m4a", time: "1h ago", board: "Reading List", status: "sorted" },
]

export function AddScreen({ onClose }: AddScreenProps) {
  const [phase, setPhase] = useState<InboxPhase>("idle")
  const [processed, setProcessed] = useState<ProcessedItem | null>(null)
  const [steps, setSteps] = useState<number>(0)
  const [isEditing, setIsEditing] = useState(false)

  const simulateProcessing = useCallback(() => {
    setPhase("dropped")
    setSteps(0)

    const timers: NodeJS.Timeout[] = []

    timers.push(
      setTimeout(() => {
        setPhase("processing")
        setSteps(1)
      }, 400)
    )
    timers.push(
      setTimeout(() => setSteps(2), 1200)
    )
    timers.push(
      setTimeout(() => setSteps(3), 2000)
    )
    timers.push(
      setTimeout(() => {
        setSteps(4)
        setProcessed({
          title: "Santorini Blue Domes",
          description: "Iconic white-washed buildings with blue domes overlooking the Aegean Sea at sunset.",
          suggestedBoard: "Travel Inspo",
          tags: ["greece", "architecture", "sunset", "islands"],
          type: "Image",
        })
        setPhase("done")
      }, 2800)
    )

    return () => timers.forEach(clearTimeout)
  }, [])

  useEffect(() => {
    return () => {
      // cleanup
    }
  }, [])

  const handleReset = useCallback(() => {
    setPhase("idle")
    setProcessed(null)
    setSteps(0)
    setIsEditing(false)
  }, [])

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <header className="px-5 pt-2 pb-3">
        <div className="flex items-center justify-between">
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Close"
          >
            <X className="w-5 h-5 text-foreground" />
          </button>
          <h1 className="text-base font-semibold text-foreground">Inbox</h1>
          <div className="w-9" />
        </div>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-6">
        <div className="px-5">
          {/* Phase: Idle -- drop zone */}
          {phase === "idle" && (
            <>
              {/* Drop zone */}
              <button
                onClick={simulateProcessing}
                className="w-full mb-5 border-2 border-dashed border-primary/30 rounded-2xl p-8 flex flex-col items-center gap-3 bg-primary/5 hover:bg-primary/8 hover:border-primary/50 transition-all active:scale-[0.98]"
              >
                <div className="w-14 h-14 rounded-2xl bg-primary/15 flex items-center justify-center text-primary mb-1">
                  <Sparkles className="w-7 h-7" />
                </div>
                <p className="text-sm font-semibold text-foreground">Drop anything here</p>
                <p className="text-[11px] text-muted-foreground text-center leading-relaxed max-w-[200px]">
                  Photos, links, files, voice memos... AI will name, describe, tag, and sort it for you.
                </p>
              </button>

              {/* Quick capture */}
              <div className="mb-6">
                <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
                  Quick Capture
                </h2>
                <div className="grid grid-cols-5 gap-2">
                  {quickActions.map((action) => (
                    <button
                      key={action.label}
                      onClick={simulateProcessing}
                      className={`flex flex-col items-center gap-1.5 py-3 rounded-xl transition-colors ${
                        action.accent
                          ? "bg-primary/10 text-primary border border-primary/20 hover:bg-primary/15"
                          : "bg-secondary text-foreground border border-border/50 hover:bg-secondary/80"
                      }`}
                    >
                      {action.icon}
                      <span className="text-[10px] font-medium">{action.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Paste a link inline */}
              <div className="mb-6">
                <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
                  Paste Link
                </h2>
                <div className="flex items-center gap-2">
                  <div className="flex-1 relative">
                    <Link2 className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    <input
                      type="url"
                      placeholder="https://..."
                      className="w-full pl-9 pr-4 py-3 rounded-xl bg-secondary border border-border text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    />
                  </div>
                  <button
                    onClick={simulateProcessing}
                    className="w-11 h-11 rounded-xl bg-primary flex items-center justify-center text-primary-foreground flex-shrink-0 hover:bg-primary/90 transition-colors"
                    aria-label="Submit link"
                  >
                    <ArrowRight className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Recent activity */}
              <div>
                <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
                  Recent
                </h2>
                <div className="flex flex-col gap-2">
                  {recentDrops.map((drop) => (
                    <div
                      key={drop.name}
                      className="flex items-center gap-3 p-3 rounded-xl bg-secondary/60 border border-border/30"
                    >
                      <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                        <Check className="w-3.5 h-3.5 text-primary" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-foreground truncate">{drop.name}</p>
                        <p className="text-[10px] text-muted-foreground">
                          {drop.time} &middot; {drop.board}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}

          {/* Phase: Processing */}
          {(phase === "processing" || phase === "dropped") && (
            <div className="flex flex-col items-center pt-8">
              {/* Animated brain */}
              <div className="relative w-20 h-20 mb-6">
                <div className="absolute inset-0 rounded-full bg-primary/10 animate-pulse" />
                <div className="absolute inset-2 rounded-full bg-primary/15 animate-pulse" style={{ animationDelay: "150ms" }} />
                <div className="absolute inset-0 flex items-center justify-center">
                  <Sparkles className="w-8 h-8 text-primary" />
                </div>
              </div>

              <h2 className="text-base font-semibold text-foreground mb-1">Processing...</h2>
              <p className="text-xs text-muted-foreground mb-8">AI is analyzing your content</p>

              {/* Step indicators */}
              <div className="w-full flex flex-col gap-3 px-4">
                {steps >= 1 ? (
                  steps > 1 ? <CompletedStep label="Content type detected" /> : <ProcessingIndicator label="Detecting content type..." />
                ) : (
                  <div className="flex items-center gap-2.5">
                    <div className="w-4 h-4 rounded-full bg-muted" />
                    <span className="text-xs text-muted-foreground/50">Detecting content type</span>
                  </div>
                )}
                {steps >= 2 ? (
                  steps > 2 ? <CompletedStep label="Title and description generated" /> : <ProcessingIndicator label="Generating title and description..." />
                ) : (
                  <div className="flex items-center gap-2.5">
                    <div className="w-4 h-4 rounded-full bg-muted" />
                    <span className="text-xs text-muted-foreground/50">Generate title and description</span>
                  </div>
                )}
                {steps >= 3 ? (
                  steps > 3 ? <CompletedStep label="Tags assigned and board matched" /> : <ProcessingIndicator label="Assigning tags and matching board..." />
                ) : (
                  <div className="flex items-center gap-2.5">
                    <div className="w-4 h-4 rounded-full bg-muted" />
                    <span className="text-xs text-muted-foreground/50">Assign tags and match board</span>
                  </div>
                )}
                {steps >= 4 ? (
                  <CompletedStep label="Sorted to board" />
                ) : (
                  <div className="flex items-center gap-2.5">
                    <div className="w-4 h-4 rounded-full bg-muted" />
                    <span className="text-xs text-muted-foreground/50">Sort to board</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Phase: Done */}
          {phase === "done" && processed && (
            <div className="pt-2">
              {/* Success header */}
              <div className="flex flex-col items-center mb-6">
                <div className="w-14 h-14 rounded-full bg-primary/15 flex items-center justify-center mb-3">
                  <Check className="w-7 h-7 text-primary" />
                </div>
                <h2 className="text-base font-semibold text-foreground">Sorted by AI</h2>
                <p className="text-xs text-muted-foreground">Review and confirm, or edit the details</p>
              </div>

              {/* Preview card */}
              <div className="rounded-2xl bg-card border border-border/50 overflow-hidden mb-5">
                <img
                  src="/images/travel-1.jpg"
                  alt={processed.title}
                  className="w-full h-36 object-cover"
                />
                <div className="p-4">
                  {!isEditing ? (
                    <>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-[10px] font-semibold text-primary uppercase tracking-wider">
                          {processed.type}
                        </span>
                        <button
                          onClick={() => setIsEditing(true)}
                          className="flex items-center gap-1 text-[10px] text-muted-foreground hover:text-foreground transition-colors"
                        >
                          <Pencil className="w-3 h-3" />
                          Edit
                        </button>
                      </div>
                      <h3 className="text-sm font-semibold text-foreground mb-1">{processed.title}</h3>
                      <p className="text-[11px] text-muted-foreground leading-relaxed mb-3">{processed.description}</p>
                      <div className="flex flex-wrap gap-1.5 mb-3">
                        {processed.tags.map((tag) => (
                          <span
                            key={tag}
                            className="px-2 py-0.5 text-[10px] font-medium rounded-full bg-secondary text-muted-foreground"
                          >
                            {tag}
                          </span>
                        ))}
                      </div>
                      <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-primary/5 border border-primary/15">
                        <ArrowRight className="w-3.5 h-3.5 text-primary" />
                        <span className="text-xs text-primary font-medium">
                          {processed.suggestedBoard}
                        </span>
                      </div>
                    </>
                  ) : (
                    <div className="flex flex-col gap-3">
                      <div>
                        <label htmlFor="edit-title" className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider block mb-1">
                          Title
                        </label>
                        <input
                          id="edit-title"
                          type="text"
                          defaultValue={processed.title}
                          className="w-full px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                        />
                      </div>
                      <div>
                        <label htmlFor="edit-desc" className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider block mb-1">
                          Description
                        </label>
                        <textarea
                          id="edit-desc"
                          rows={2}
                          defaultValue={processed.description}
                          className="w-full px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring resize-none"
                        />
                      </div>
                      <div>
                        <label htmlFor="edit-board" className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider block mb-1">
                          Board
                        </label>
                        <select
                          id="edit-board"
                          defaultValue="travel"
                          className="w-full px-3 py-2 rounded-lg bg-secondary border border-border text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring appearance-none"
                        >
                          <option value="travel">Travel Inspo</option>
                          <option value="design">Design System</option>
                          <option value="recipes">Recipes</option>
                          <option value="nature">Nature</option>
                          <option value="architecture">Architecture</option>
                          <option value="reading">Reading List</option>
                        </select>
                      </div>
                      <button
                        onClick={() => setIsEditing(false)}
                        className="self-end px-4 py-2 rounded-lg bg-primary text-primary-foreground text-xs font-semibold hover:bg-primary/90 transition-colors"
                      >
                        Done Editing
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* Action buttons */}
              {!isEditing && (
                <div className="flex gap-3">
                  <button
                    onClick={handleReset}
                    className="flex-1 py-3 rounded-xl bg-secondary text-foreground font-semibold text-sm hover:bg-secondary/80 transition-colors border border-border/50"
                  >
                    Discard
                  </button>
                  <button
                    onClick={handleReset}
                    className="flex-1 py-3 rounded-xl bg-primary text-primary-foreground font-semibold text-sm hover:bg-primary/90 transition-colors"
                  >
                    Confirm
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
