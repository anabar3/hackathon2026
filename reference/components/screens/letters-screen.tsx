import { Mail, Send, Sparkles } from "lucide-react"

export function LettersScreen() {
    return (
        <div className="min-h-screen bg-background p-6">
            <header className="mb-8 pt-8 text-center flex flex-col items-center">
                <div className="inline-flex items-center gap-2 px-6 py-2 rounded-full bg-accent text-accent-foreground font-bold border-3 border-border shadow-sm mb-4">
                    <Mail className="w-5 h-5" />
                    <span>Post Office</span>
                </div>
                <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Letters</h1>
                <p className="text-muted-foreground mt-2 font-medium">Send and receive cozy messages</p>
            </header>

            <div className="space-y-4 max-w-md mx-auto">
                <button className="w-full flex items-center justify-between p-5 bg-card border-3 border-border rounded-2xl ac-button active:translate-y-1 group">
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                            <Sparkles className="w-6 h-6" />
                        </div>
                        <div className="text-left">
                            <h3 className="font-bold text-foreground text-lg">Send a Letter</h3>
                            <p className="text-sm font-medium text-muted-foreground">Attach a gift or a board!</p>
                        </div>
                    </div>
                    <Send className="w-5 h-5 text-muted-foreground group-hover:translate-x-1 transition-transform" />
                </button>

                <div className="mt-8">
                    <h2 className="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4 px-2">Your Mailbox</h2>
                    <div className="flex flex-col items-center justify-center p-12 text-center bg-secondary/50 border-3 border-border border-dashed rounded-[2rem]">
                        <Mail className="w-12 h-12 text-muted-foreground/30 mb-3" />
                        <p className="text-muted-foreground font-medium">Your mailbox is empty right now.</p>
                    </div>
                </div>
            </div>
        </div>
    )
}
