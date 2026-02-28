export type ContentType = "image" | "video" | "link" | "audio" | "note" | "document" | "file"

export interface ContentItem {
  id: string
  type: ContentType
  title: string
  description?: string
  thumbnail?: string
  url?: string
  tags: string[]
  boardId: string
  createdAt: string
  color?: string
  duration?: string
  size?: string
  author?: string
  saved: boolean
}

export interface Board {
  id: string
  name: string
  description?: string
  itemCount: number
  coverImage?: string
  color: string
  icon: string
  isPublic: boolean
}

export interface NearbyPerson {
  id: string
  name: string
  avatar: string
  bio: string
  lastSeenLocation: string
  lastSeenTime: string
  sharedInterests: string[]
  publicBoards: Board[]
}

export type Screen =
  | "dashboard"
  | "board"
  | "detail"
  | "add"
  | "edit"
  | "search"
  | "drift"
  | "saved"
  | "ai-organize"
  | "person-boards"
  | "letters"
