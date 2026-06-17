import SwiftUI

@main
struct PokerProAssistantApp: App {
    @StateObject private var game = GameViewModel()

    var body: some Scene {
        WindowGroup("PokerPro Assistant") {
            ContentView()
                .environmentObject(game)
                .frame(minWidth: 1060, minHeight: 680)
        }
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Game") {
                Button("Reset Hand") { game.reset() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("Recalculate") { game.calculateEquity() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!game.heroComplete)
                Divider()
                Button("Fewer Opponents") { game.updateOpponents(-1) }
                    .keyboardShortcut("-", modifiers: .command)
                    .disabled(game.numOpponents <= 1)
                Button("More Opponents") { game.updateOpponents(1) }
                    .keyboardShortcut("=", modifiers: .command)
                    .disabled(game.numOpponents >= 8)
            }
        }
    }
}
