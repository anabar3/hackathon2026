"use client"

import { useState, useEffect, useCallback } from "react"
import {
  ArrowLeft,
  Sparkles,
  Check,
  X,
  ArrowRightLeft,
  RotateCcw,
  Loader2,
  Image,
  Video,
  Link2,
  Headphones,
  StickyNote,
  FileText,
  File,
  ChevronDown,
  Grip,
} from "lucide-react"
import type { Board, ContentItem } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"

interface AiOrganizeScreenProps {
  board: Board
  items: ContentItem[]
  onBack: () => void
  onAccept: (items: ContentItem[]) => void
}

type SortCriteria =
  | "by-type"
  | "by-date"
  | "by-relevance"
  | "by-color"

const criteriaLabels: Record<SortCriteria, string> = {
  "by-type": "By Content Type",
  "by-date": "By Date (Newest)",
  "by-relevance": "By Relevance",
  "by-color": "By Visual Similarity",
}

const criteriaDescriptions: Record<SortCriteria, string> = {
  "by-type": "Groups images, videos, links, notes and documents together",
  "by-date": "Most recently added content appears first",
  "by-relevance": "Related content placed next to each other using tags",
  "by-color": "Visually similar items arranged together for aesthetic flow",
}

const typeIcons: Record<string, React.ReactNode> = {
  image: <Image className="w-3.5 h-3.5" />,
  video: <Video className="w-3.5 h-3.5" />,
  link: <Link2 className="w-3.5 h-3.5" />,
  audio: <Headphones className="w-3.5 h-3.5" />,
  note: <StickyNote className="w-3.5 h-3.5" />,
  document: <FileText className="w-3.5 h-3.5" />,
  file: <File className="w-3.5 h-3.5" />,
}

const typeOrder: Record<string, number> = {
  image: 0,
  video: 1,
  link: 2,
  audio: 3,
  note: 4,
  document: 5,
  file: 6,
}

function shuffleWithSeed(arr: ContentItem[], seed: number): ContentItem[] {
  const result = [...arr]
  let s = seed
  for (let i = result.length - 1; i > 0; i--) {
    s = (s * 9301 + 49297) % 233280
    const j = Math.floor((s / 233280) * (i + 1))
    ;[result[i], result[j]] = [result[j], result[i]]
  }
  return result
}

function sortItems(
  items: ContentItem[],
  criteria: SortCriteria
): ContentItem[] {
  const copy = [...items]
  switch (criteria) {
    case "by-type":
      return copy.sort(
        (a, b) => (typeOrder[a.type] ?? 99) - (typeOrder[b.type] ?? 99)
      )
    case "by-date":
      return copy.sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
    case "by-relevance":
      return copy.sort((a, b) => {
        const sharedTags = a.tags.filter((t) => b.tags.includes(t)).length
        return sharedTags > 0 ? -1 : 1
      })
    case "by-color":
      return shuffleWithSeed(copy, 42)
    default:
      return copy
  }
}

type AnalysisPhase = "scanning" | "analyzing" | "organizing" | "done"

const phaseMessages: Record<AnalysisPhase, string> = {
  scanning: "Scanning board content...",
  analyzing: "Analyzing relationships between items...",
  organizing: "Generating optimal arrangement...",
  done: "Organization ready for review",
}

export function AiOrganizeScreen({
  board,
  items,
  onBack,
  onAccept,
}: AiOrganizeScreenProps) {
  const boardItems = items.filter((i) => i.boardId === board.id)
  const [phase, setPhase] = useState<AnalysisPhase>("scanning")
  const [criteria, setCriteria] = useState<SortCriteria>("by-type")
  const [showCriteriaMenu, setShowCriteriaMenu] = useState(false)
  const [previewMode, setPreviewMode] = useState<"suggested" | "original">("suggested")
  const [accepted, setAccepted] = useState<boolean | null>(null)

  const suggestedItems = sortItems(boardItems, criteria)

  // Simulate the AI "analysis" loading
  useEffect(() => {
    setPhase("scanning")
    setAccepted(null)
    const t1 = setTimeout(() => setPhase("analyzing"), 800)
    const t2 = setTimeout(() => setPhase("organizing"), 1800)
    const t3 = setTimeout(() => setPhase("done"), 2600)
    return () => {
      clearTimeout(t1)
      clearTimeout(t2)
      clearTimeout(t3)
    }
  }, [criteria])

  const handleAccept = useCallback(() => {
    setAccepted(true)
    setTimeout(() => onAccept(suggestedItems), 1200)
  }, [onAccept, suggestedItems])

  const handleReject = useCallback(() => {
    setAccepted(false)
    setTimeout(() => onBack(), 800)
  }, [onBack])

  const handleRetry = useCallback(() => {
    const allCriteria: SortCriteria[] = [
      "by-type",
      "by-date",
      "by-relevance",
      "by-color",
    ]
    const currentIdx = allCriteria.indexOf(criteria)
    const nextIdx = (currentIdx + 1) % allCriteria.length
    setCriteria(allCriteria[nextIdx])
  }, [criteria])

  const displayItems =
    previewMode === "suggested" ? suggestedItems : boardItems
  const isLoading = phase !== "done"

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <header className="px-5 pt-2 pb-3 border-b border-border">
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center hover:bg-secondary/80 transition-colors"
            aria-label="Go back"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-primary" />
            <h1 className="text-base font-semibold text-foreground">
              AI Organize
            </h1>
          </div>
          <div className="w-9" />
        </div>
      </header>

      {/* Analysis Status Banner */}
      <div
        className={`mx-5 mt-3 p-3 rounded-xl border transition-all duration-500 ${
          isLoading
            ? "bg-primary/5 border-primary/20"
            : accepted === true
              ? "bg-green-500/10 border-green-500/30"
              : accepted === false
                ? "bg-destructive/10 border-destructive/30"
                : "bg-primary/5 border-primary/20"
        }`}
      >
        <div className="flex items-center gap-3">
          {isLoading ? (
            <div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center flex-shrink-0">
              <Loader2 className="w-4 h-4 text-primary animate-spin" />
            </div>
          ) : accepted === true ? (
            <div className="w-8 h-8 rounded-lg bg-green-500/15 flex items-center justify-center flex-shrink-0">
              <Check className="w-4 h-4 text-green-400" />
            </div>
          ) : accepted === false ? (
            <div className="w-8 h-8 rounded-lg bg-destructive/15 flex items-center justify-center flex-shrink-0">
              <X className="w-4 h-4 text-destructive" />
            </div>
          ) : (
            <div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center flex-shrink-0">
              <Sparkles className="w-4 h-4 text-primary" />
            </div>
          )}
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-foreground">
              {accepted === true
                ? "Organization accepted!"
                : accepted === false
                  ? "Changes discarded"
                  : phaseMessages[phase]}
            </p>
            <p className="text-[11px] text-muted-foreground mt-0.5">
              {accepted === true
                ? "Applying new arrangement to your board..."
                : accepted === false
                  ? "Returning to original order..."
                  : isLoading
                    ? `Analyzing ${boardItems.length} items in "${board.name}"`
                    : criteriaDescriptions[criteria]}
            </p>
          </div>
        </div>

        {/* Loading bar */}
        {isLoading && (
          <div className="mt-3 h-1 rounded-full bg-secondary overflow-hidden">
            <div
              className="h-full rounded-full bg-primary transition-all duration-700 ease-out"
              style={{
                width:
                  phase === "scanning"
                    ? "30%"
                    : phase === "analyzing"
                      ? "65%"
                      : "95%",
              }}
            />
          </div>
        )}
      </div>

      {/* Criteria Selector */}
      {!isLoading && accepted === null && (
        <div className="mx-5 mt-3 relative">
          <button
            onClick={() => setShowCriteriaMenu(!showCriteriaMenu)}
            className="w-full flex items-center justify-between p-3 rounded-xl bg-secondary border border-border/50 hover:border-primary/30 transition-colors"
          >
            <div className="flex items-center gap-2">
              <Sparkles className="w-3.5 h-3.5 text-primary" />
              <span className="text-sm font-medium text-foreground">
                {criteriaLabels[criteria]}
              </span>
            </div>
            <ChevronDown
              className={`w-4 h-4 text-muted-foreground transition-transform ${showCriteriaMenu ? "rotate-180" : ""}`}
            />
          </button>

          {showCriteriaMenu && (
            <div className="absolute top-full left-0 right-0 mt-1 rounded-xl bg-popover border border-border shadow-xl z-50 overflow-hidden">
              {(Object.keys(criteriaLabels) as SortCriteria[]).map((c) => (
                <button
                  key={c}
                  onClick={() => {
                    setCriteria(c)
                    setShowCriteriaMenu(false)
                  }}
                  className={`w-full text-left px-4 py-3 flex items-center justify-between transition-colors ${
                    c === criteria
                      ? "bg-primary/10"
                      : "hover:bg-secondary"
                  }`}
                >
                  <div>
                    <p
                      className={`text-sm font-medium ${c === criteria ? "text-primary" : "text-foreground"}`}
                    >
                      {criteriaLabels[c]}
                    </p>
                    <p className="text-[11px] text-muted-foreground mt-0.5">
                      {criteriaDescriptions[c]}
                    </p>
                  </div>
                  {c === criteria && (
                    <Check className="w-4 h-4 text-primary flex-shrink-0" />
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Before/After Toggle */}
      {!isLoading && accepted === null && (
        <div className="mx-5 mt-3 flex items-center gap-2">
          <button
            onClick={() => setPreviewMode("suggested")}
            className={`flex-1 py-2 rounded-lg text-xs font-semibold text-center transition-all ${
              previewMode === "suggested"
                ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                : "bg-secondary text-muted-foreground hover:text-foreground"
            }`}
          >
            Suggested Order
          </button>
          <button
            onClick={() => setPreviewMode("original")}
            className={`flex-1 py-2 rounded-lg text-xs font-semibold text-center transition-all ${
              previewMode === "original"
                ? "bg-secondary text-foreground border border-border"
                : "bg-secondary text-muted-foreground hover:text-foreground"
            }`}
          >
            Original Order
          </button>
          <button
            onClick={() =>
              setPreviewMode((p) =>
                p === "suggested" ? "original" : "suggested"
              )
            }
            className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Toggle view"
          >
            <ArrowRightLeft className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Items Preview */}
      <ScrollArea className="flex-1 min-h-0 mt-3">
        <div className="px-5 pb-44">
          {isLoading ? (
            <div className="flex flex-col gap-2.5 mt-2">
              {boardItems.map((item, i) => (
                <div
                  key={item.id}
                  className="flex items-center gap-3 p-3 rounded-xl bg-secondary border border-border/50 animate-pulse"
                  style={{ animationDelay: `${i * 100}ms` }}
                >
                  <div className="w-4 h-4 rounded bg-muted-foreground/20" />
                  <div className="w-10 h-10 rounded-lg bg-muted-foreground/20 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="h-3.5 rounded bg-muted-foreground/20 w-3/4 mb-1.5" />
                    <div className="h-2.5 rounded bg-muted-foreground/10 w-1/2" />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col gap-2 mt-1">
              {displayItems.map((item, index) => {
                const originalIndex = boardItems.findIndex(
                  (bi) => bi.id === item.id
                )
                const moved = originalIndex !== index
                return (
                  <div
                    key={item.id}
                    className={`flex items-center gap-3 p-3 rounded-xl border transition-all duration-300 ${
                      previewMode === "suggested" && moved
                        ? "bg-primary/5 border-primary/20"
                        : "bg-secondary border-border/50"
                    }`}
                    style={{
                      animationDelay: `${index * 50}ms`,
                    }}
                  >
                    {/* Position number */}
                    <span
                      className={`text-[11px] font-bold w-5 text-center flex-shrink-0 ${
                        previewMode === "suggested" && moved
                          ? "text-primary"
                          : "text-muted-foreground"
                      }`}
                    >
                      {index + 1}
                    </span>

                    {/* Grip handle */}
                    <Grip className="w-3.5 h-3.5 text-muted-foreground/50 flex-shrink-0" />

                    {/* Thumbnail or icon */}
                    {item.thumbnail ? (
                      <div className="w-10 h-10 rounded-lg overflow-hidden flex-shrink-0">
                        <img
                          src={item.thumbnail}
                          alt=""
                          className="w-full h-full object-cover"
                        />
                      </div>
                    ) : (
                      <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center flex-shrink-0 text-primary">
                        {typeIcons[item.type]}
                      </div>
                    )}

                    {/* Info */}
                    <div className="flex-1 min-w-0">
                      <h3 className="text-sm font-medium text-foreground truncate">
                        {item.title}
                      </h3>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <span className="text-[10px] text-muted-foreground capitalize">
                          {item.type}
                        </span>
                        {previewMode === "suggested" && moved && (
                          <span className="text-[10px] text-primary font-medium">
                            moved
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Movement indicator */}
                    {previewMode === "suggested" && moved && (
                      <div className="flex items-center gap-1 flex-shrink-0">
                        <span className="text-[10px] font-semibold text-primary">
                          {originalIndex > index ? (
                            <span>{"↑"}{originalIndex - index}</span>
                          ) : (
                            <span>{"↓"}{index - originalIndex}</span>
                          )}
                        </span>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </ScrollArea>

      {/* Accept / Reject footer */}
      {!isLoading && accepted === null && (
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-background via-background/95 to-transparent pt-8 pb-8 px-5">
          <div className="flex items-center gap-3">
            {/* Retry button */}
            <button
              onClick={handleRetry}
              className="w-12 h-12 rounded-xl bg-secondary border border-border/50 flex items-center justify-center text-muted-foreground hover:text-foreground hover:border-border transition-colors flex-shrink-0"
              aria-label="Try different organization"
            >
              <RotateCcw className="w-5 h-5" />
            </button>

            {/* Reject */}
            <button
              onClick={handleReject}
              className="flex-1 h-12 rounded-xl bg-secondary border border-border/50 flex items-center justify-center gap-2 text-foreground font-semibold text-sm hover:bg-secondary/80 transition-colors"
            >
              <X className="w-4 h-4" />
              Discard
            </button>

            {/* Accept */}
            <button
              onClick={handleAccept}
              className="flex-1 h-12 rounded-xl bg-primary text-primary-foreground flex items-center justify-center gap-2 font-semibold text-sm shadow-lg shadow-primary/25 hover:brightness-110 transition-all"
            >
              <Check className="w-4 h-4" />
              Accept
            </button>
          </div>

          <p className="text-[10px] text-muted-foreground text-center mt-3">
            Accept to apply this arrangement or try a different criteria
          </p>
        </div>
      )}

      {/* Accepted / Rejected feedback */}
      {accepted !== null && (
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-background via-background/95 to-transparent pt-8 pb-8 px-5">
          <div
            className={`flex items-center justify-center gap-2 py-4 rounded-xl ${
              accepted
                ? "bg-green-500/10 border border-green-500/30"
                : "bg-secondary border border-border/50"
            }`}
          >
            {accepted ? (
              <>
                <Check className="w-5 h-5 text-green-400" />
                <span className="text-sm font-semibold text-green-400">
                  Arrangement applied
                </span>
              </>
            ) : (
              <>
                <X className="w-5 h-5 text-muted-foreground" />
                <span className="text-sm font-semibold text-muted-foreground">
                  Changes discarded
                </span>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
