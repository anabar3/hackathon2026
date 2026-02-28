"use client"

import { MapPin, Clock, ChevronRight, Radio, Compass, Palette, ChefHat, Mountain, Building, BookOpen, Waves } from "lucide-react"
import type { NearbyPerson } from "@/lib/types"
import { ScrollArea } from "@/components/ui/scroll-area"

interface DriftScreenProps {
  people: NearbyPerson[]
  onPersonSelect: (person: NearbyPerson) => void
}

const boardIconMap: Record<string, React.ReactNode> = {
  compass: <Compass className="w-3.5 h-3.5" />,
  palette: <Palette className="w-3.5 h-3.5" />,
  "chef-hat": <ChefHat className="w-3.5 h-3.5" />,
  mountain: <Mountain className="w-3.5 h-3.5" />,
  building: <Building className="w-3.5 h-3.5" />,
  "book-open": <BookOpen className="w-3.5 h-3.5" />,
}

function PersonCard({
  person,
  onSelect,
}: {
  person: NearbyPerson
  onSelect: () => void
}) {
  // Only show boards that match shared interests (the overlap with your boards)
  const matchingBoards = person.publicBoards.filter((b) =>
    person.sharedInterests.some(
      (interest) =>
        b.name.toLowerCase().includes(interest) ||
        b.description?.toLowerCase().includes(interest) ||
        b.icon === interest
    )
  )
  const shownBoards = matchingBoards.length > 0 ? matchingBoards : person.publicBoards.slice(0, 1)
  const hiddenCount = person.publicBoards.length - shownBoards.length

  return (
    <button
      onClick={onSelect}
      className="w-full text-left rounded-2xl bg-card border border-border/50 overflow-hidden transition-all hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    >
      {/* Person header */}
      <div className="flex items-center gap-3 p-4 pb-3">
        <div className="relative flex-shrink-0">
          <img
            src={person.avatar}
            alt={person.name}
            className="w-12 h-12 rounded-full object-cover border-2 border-border"
          />
          <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full bg-green-500 border-2 border-card" />
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="text-sm font-semibold text-foreground truncate">{person.name}</h3>
          <p className="text-[11px] text-muted-foreground truncate">{person.bio}</p>
        </div>
        <ChevronRight className="w-4 h-4 text-muted-foreground flex-shrink-0" />
      </div>

      {/* Location & time */}
      <div className="flex items-center gap-3 px-4 pb-3">
        <span className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
          <MapPin className="w-3 h-3" />
          {person.lastSeenLocation}
        </span>
        <span className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
          <Clock className="w-3 h-3" />
          {person.lastSeenTime}
        </span>
      </div>

      {/* Shared interest tags */}
      <div className="flex items-center gap-1.5 px-4 pb-3">
        <span className="text-[10px] text-primary font-semibold uppercase tracking-wider">In common</span>
        {person.sharedInterests.map((interest) => (
          <span
            key={interest}
            className="px-2 py-0.5 text-[10px] font-medium rounded-full bg-primary/10 text-primary border border-primary/20"
          >
            {interest}
          </span>
        ))}
      </div>

      {/* Matching public boards */}
      <div className="px-4 pb-4">
        <div className="flex flex-col gap-2">
          {shownBoards.map((board) => (
            <div
              key={board.id}
              className="flex items-center gap-3 p-2.5 rounded-xl bg-secondary/60"
            >
              {board.coverImage ? (
                <img
                  src={board.coverImage}
                  alt=""
                  className="w-10 h-10 rounded-lg object-cover flex-shrink-0"
                />
              ) : (
                <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary flex-shrink-0">
                  {boardIconMap[board.icon] || <Compass className="w-3.5 h-3.5" />}
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-foreground truncate">{board.name}</p>
                <p className="text-[10px] text-muted-foreground">{board.itemCount} items</p>
              </div>
            </div>
          ))}
          {hiddenCount > 0 && (
            <p className="text-[10px] text-muted-foreground text-center pt-1">
              +{hiddenCount} more public board{hiddenCount !== 1 ? "s" : ""}
            </p>
          )}
        </div>
      </div>
    </button>
  )
}

export function DriftScreen({ people, onPersonSelect }: DriftScreenProps) {
  const activeNow = people.filter((p) => p.lastSeenTime.includes("min"))
  const earlier = people.filter((p) => !p.lastSeenTime.includes("min"))

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header className="px-5 pt-2 pb-3">
        <div className="flex items-center justify-between mb-1">
          <div>
            <h1 className="text-xl font-bold text-foreground tracking-tight">Drift</h1>
            <p className="text-[11px] text-muted-foreground">People who crossed your path</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center">
            <Waves className="w-5 h-5 text-primary" />
          </div>
        </div>

        {/* Live pulse indicator */}
        <div className="flex items-center gap-2 mt-3 px-3 py-2 rounded-xl bg-primary/5 border border-primary/15">
          <span className="relative flex h-2.5 w-2.5">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75" />
            <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-primary" />
          </span>
          <p className="text-[11px] text-primary font-medium">
            {activeNow.length} {activeNow.length === 1 ? "person" : "people"} nearby share your interests
          </p>
        </div>

        {/* Explanation */}
        <p className="text-[10px] text-muted-foreground mt-2 leading-relaxed px-1">
          Only boards matching your interests are shown. Tap someone to see all their public boards.
        </p>
      </header>

      <ScrollArea className="flex-1 min-h-0 pb-24">
        <div className="px-4">
          {/* Active now */}
          {activeNow.length > 0 && (
            <div className="mb-5">
              <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
                Just now
              </h2>
              <div className="flex flex-col gap-3">
                {activeNow.map((person) => (
                  <PersonCard
                    key={person.id}
                    person={person}
                    onSelect={() => onPersonSelect(person)}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Earlier */}
          {earlier.length > 0 && (
            <div className="mb-5">
              <h2 className="text-[10px] font-semibold text-muted-foreground uppercase tracking-widest mb-3 px-1">
                Earlier today
              </h2>
              <div className="flex flex-col gap-3">
                {earlier.map((person) => (
                  <PersonCard
                    key={person.id}
                    person={person}
                    onSelect={() => onPersonSelect(person)}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
