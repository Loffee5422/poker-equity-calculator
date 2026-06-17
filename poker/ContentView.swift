import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left panel: card selection + controls
            leftPanel
                .frame(width: 520)

            // Divider
            Rectangle()
                .fill(PokerTheme.border)
                .frame(width: 1)

            // Right panel: hand display + results + strategy
            rightPanel
                .frame(maxWidth: .infinity)
        }
        .background(PokerTheme.appBg)
        .preferredColorScheme(.dark)
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Title
                HStack(spacing: 8) {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(PokerTheme.accentGreen)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PokerPro Assistant")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(PokerTheme.textPrimary)
                        Text("Texas Hold'em Equity Calculator")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(PokerTheme.textMuted)
                    }
                    Spacer()
                }
                .padding(.bottom, 2)

                // Card grid
                CardGridView()

                // Opponent selector
                opponentSelector

                // Table parameters
                tableParameters

                // Action buttons
                actionButtons
            }
            .padding(16)
        }
    }

    // MARK: - Opponent Selector

    private var opponentSelector: some View {
        HStack(spacing: 0) {
            sectionLabel("OPPONENTS", icon: "person.3.fill", color: PokerTheme.accentPurple)
            Spacer()

            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.2)) { game.updateOpponents(-1) }
                    if game.heroComplete { game.calculateEquity() }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 26)
                        .foregroundColor(game.numOpponents > 1
                                         ? PokerTheme.textPrimary : PokerTheme.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(game.numOpponents <= 1)

                Text("\(game.numOpponents)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(PokerTheme.textPrimary)
                    .frame(width: 30)
                    .contentTransition(.numericText())

                Button {
                    withAnimation(.spring(response: 0.2)) { game.updateOpponents(1) }
                    if game.heroComplete { game.calculateEquity() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 26)
                        .foregroundColor(game.numOpponents < 8
                                         ? PokerTheme.textPrimary : PokerTheme.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(game.numOpponents >= 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(PokerTheme.elevatedBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(PokerTheme.border, lineWidth: 0.5)
                    )
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(PokerTheme.panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(PokerTheme.border, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Table Parameters

    private var tableParameters: some View {
        VStack(spacing: 8) {
            sectionLabel("TABLE INFO", icon: "tablecells.fill", color: PokerTheme.accentGold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                paramField("Pot", $game.potSize, icon: "circle.fill")
                paramField("Bet to Call", $game.betToCall, icon: "arrow.right.circle.fill")
                paramField("Stack", $game.heroStack, icon: "square.stack.3d.up.fill")
                paramField("Big Blind", $game.bigBlind, icon: "b.circle.fill")
                paramField("Small Blind", $game.smallBlind, icon: "s.circle.fill")
                paramField("Antes", $game.antes, icon: "a.circle.fill")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(PokerTheme.panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(PokerTheme.border, lineWidth: 0.5)
                )
        )
    }

    private func paramField(_ label: String, _ value: Binding<Double>,
                            icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 7))
                    .foregroundColor(PokerTheme.textMuted)
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(PokerTheme.textMuted)
            }
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(PokerTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(PokerTheme.elevatedBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(PokerTheme.border, lineWidth: 0.5)
                        )
                )
                .onSubmit {
                    if game.heroComplete { game.calculateEquity() }
                }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) { game.reset() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(PokerTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PokerTheme.elevatedBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PokerTheme.border, lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            Button {
                game.calculateEquity()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Calculate")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(game.heroComplete
                              ? PokerTheme.accentGreen
                              : PokerTheme.textMuted.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
            .disabled(!game.heroComplete)
            .keyboardShortcut(.return, modifiers: .command)
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                HandDisplayView()
                EquityDashboardView()
                LosingHandsView()
                StrategyPanelView()
                Spacer(minLength: 20)
            }
            .padding(16)
        }
    }

    // MARK: - Shared

    private func sectionLabel(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(PokerTheme.textSecondary)
                .tracking(1.2)
        }
    }
}
