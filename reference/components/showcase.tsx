"use client"

import { useState, useCallback } from "react"
import type { Board, ContentItem, NearbyPerson, Screen } from "@/lib/types"
import { boards as initialBoards, contentItems as initialItems, nearbyPeople } from "@/lib/mock-data"
import { PhoneFrame } from "@/components/phone-frame"
import { BottomNav } from "@/components/bottom-nav"
import { DashboardScreen } from "@/components/screens/dashboard-screen"
import { BoardScreen } from "@/components/screens/board-screen"
import { DetailScreen } from "@/components/screens/detail-screen"
import { AddScreen } from "@/components/screens/add-screen"
import { EditScreen } from "@/components/screens/edit-screen"
import { AiOrganizeScreen } from "@/components/screens/ai-organize-screen"
import { DriftScreen } from "@/components/screens/drift-screen"
import { SavedScreen } from "@/components/screens/saved-screen"
import { PersonBoardsScreen } from "@/components/screens/person-boards-screen"
import { ScreenSelector } from "@/components/screen-selector"

export function Showcase() {
  const [screen, setScreen] = useState<Screen>("dashboard")
  const [selectedBoard, setSelectedBoard] = useState<Board>(initialBoards[0])
  const [selectedItem, setSelectedItem] = useState<ContentItem>(initialItems[0])
  const [selectedPerson, setSelectedPerson] = useState<NearbyPerson>(nearbyPeople[0])
  const [prevScreen, setPrevScreen] = useState<Screen>("dashboard")
  const [items, setItems] = useState<ContentItem[]>(initialItems)

  const navigate = useCallback(
    (newScreen: Screen) => {
      setPrevScreen(screen)
      setScreen(newScreen)
    },
    [screen]
  )

  const handleBoardSelect = useCallback(
    (board: Board) => {
      setSelectedBoard(board)
      navigate("board")
    },
    [navigate]
  )

  const handleItemSelect = useCallback(
    (item: ContentItem) => {
      setSelectedItem(item)
      navigate("detail")
    },
    [navigate]
  )

  const handleBack = useCallback(() => {
    if (screen === "detail") {
      setScreen(prevScreen === "detail" ? "board" : prevScreen)
    } else if (screen === "edit" || screen === "ai-organize") {
      setScreen("board")
    } else if (screen === "person-boards") {
      setScreen("drift")
    } else {
      setScreen("dashboard")
    }
  }, [screen, prevScreen])

  const handleAdd = useCallback(() => {
    navigate("add")
  }, [navigate])

  const handleEdit = useCallback(() => {
    navigate("edit")
  }, [navigate])

  const handleAiOrganize = useCallback(() => {
    navigate("ai-organize")
  }, [navigate])

  const handleAiAccept = useCallback(() => {
    setScreen("board")
  }, [])

  const handlePersonSelect = useCallback(
    (person: NearbyPerson) => {
      setSelectedPerson(person)
      navigate("person-boards")
    },
    [navigate]
  )

  const handleToggleSaved = useCallback((itemId: string) => {
    setItems((prev) =>
      prev.map((item) =>
        item.id === itemId ? { ...item, saved: !item.saved } : item
      )
    )
  }, [])

  const handleScreenSelect = useCallback(
    (s: Screen) => {
      if (s === "board" && !selectedBoard) setSelectedBoard(initialBoards[0])
      if (s === "detail" && !selectedItem) setSelectedItem(initialItems[0])
      if (s === "edit" && !selectedBoard) setSelectedBoard(initialBoards[0])
      if (s === "ai-organize" && !selectedBoard) setSelectedBoard(initialBoards[0])
      if (s === "person-boards" && !selectedPerson) setSelectedPerson(nearbyPeople[0])
      setPrevScreen(screen)
      setScreen(s)
    },
    [screen, selectedBoard, selectedItem, selectedPerson]
  )

  const showBottomNav =
    screen !== "add" &&
    screen !== "detail" &&
    screen !== "ai-organize" &&
    screen !== "edit" &&
    screen !== "person-boards"

  return (
    <div className="min-h-screen bg-background flex flex-col items-center">
      {/* Page Header */}
      <header className="w-full max-w-4xl mx-auto px-6 pt-12 pb-8 text-center">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary text-xs font-semibold mb-4">
          <span className="w-1.5 h-1.5 rounded-full bg-primary" />
          Mobile App UI
        </div>
        <h1 className="text-4xl md:text-5xl font-bold text-foreground tracking-tight text-balance">
          Collect
        </h1>
        <p className="text-base text-muted-foreground mt-3 max-w-md mx-auto leading-relaxed">
          Organize images, videos, links, audio, notes, and documents in visual boards.
        </p>
      </header>

      {/* Screen Selector */}
      <div className="w-full max-w-3xl mx-auto px-6 mb-8">
        <ScreenSelector activeScreen={screen} onSelect={handleScreenSelect} />
      </div>

      {/* Phone Preview */}
      <div className="pb-20">
        <PhoneFrame>
          <div className="relative h-full overflow-hidden">
            <div className="h-full overflow-hidden">
              {screen === "dashboard" && (
                <DashboardScreen
                  boards={initialBoards}
                  onBoardSelect={handleBoardSelect}
                />
              )}
              {screen === "board" && selectedBoard && (
                <BoardScreen
                  board={selectedBoard}
                  items={items}
                  onBack={handleBack}
                  onItemSelect={handleItemSelect}
                  onEdit={handleEdit}
                  onAiOrganize={handleAiOrganize}
                />
              )}
              {screen === "detail" && selectedItem && (
                <DetailScreen
                  item={items.find((i) => i.id === selectedItem.id) || selectedItem}
                  onBack={handleBack}
                  onToggleSaved={handleToggleSaved}
                />
              )}
              {screen === "add" && <AddScreen onClose={handleBack} />}
              {screen === "edit" && selectedBoard && (
                <EditScreen
                  board={selectedBoard}
                  items={items}
                  onBack={handleBack}
                />
              )}
              {screen === "ai-organize" && selectedBoard && (
                <AiOrganizeScreen
                  board={selectedBoard}
                  items={items}
                  onBack={handleBack}
                  onAccept={handleAiAccept}
                />
              )}
              {screen === "drift" && (
                <DriftScreen
                  people={nearbyPeople}
                  onPersonSelect={handlePersonSelect}
                />
              )}
              {screen === "saved" && (
                <SavedScreen
                  items={items}
                  onItemSelect={handleItemSelect}
                />
              )}
              {screen === "person-boards" && selectedPerson && (
                <PersonBoardsScreen
                  person={selectedPerson}
                  onBack={handleBack}
                />
              )}
            </div>

            {showBottomNav && (
              <BottomNav
                activeScreen={screen}
                onNavigate={(s) => handleScreenSelect(s)}
                onAdd={handleAdd}
              />
            )}
          </div>
        </PhoneFrame>
      </div>

      {/* Footer info */}
      <footer className="w-full max-w-2xl mx-auto px-6 pb-12 text-center">
        <p className="text-xs text-muted-foreground">
          Interactive prototype. Navigate between screens using the buttons above or interact directly with the phone.
        </p>
      </footer>
    </div>
  )
}
