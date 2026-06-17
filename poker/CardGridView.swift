import SwiftUI

// MARK: - Card Selection Grid (52 cards: 4 suits x 13 ranks)

struct CardGridView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("CARD SELECTOR", icon: "rectangle.grid.3x2.fill")

            VStack(spacing: 3) {
                ForEach(Suit.allCases) { suit in
                    HStack(spacing: 3) {
                        // Suit label
                        Text(suit.symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(suit.color)
                            .frame(width: 18)

                        ForEach(Rank.allCases) { rank in
                            let card = Card(rank: rank, suit: suit)
                            let selected = game.selectedCards.contains(card)
                            CardButton(card: card, isSelected: selected) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    game.selectCard(card)
                                }
                            }
                        }
                    }
                }
            }

            // Active slot indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(PokerTheme.accentGreen)
                    .frame(width: 6, height: 6)
                    .opacity(game.activeSlot < 7 ? 1 : 0.3)

                Text(game.activeSlot < 7
                     ? "Selecting: \(game.activeSlotName)"
                     : "All slots filled")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(game.activeSlot < 7
                                     ? PokerTheme.accentGreen
                                     : PokerTheme.textMuted)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PokerTheme.panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PokerTheme.border, lineWidth: 0.5)
                )
        )
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(PokerTheme.accentBlue)
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(PokerTheme.textSecondary)
                .tracking(1.2)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Individual Card Button

struct CardButton: View {
    let card: Card
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(card.rank.symbol)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                Text(card.suit.symbol)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(foregroundColor)
            .frame(width: 32, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .shadow(color: isSelected ? Color.clear : .clear, radius: 0)
            .scaleEffect(isHovered && !isSelected ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var foregroundColor: Color {
        if isSelected { return PokerTheme.textMuted.opacity(0.6) }
        return card.suit.isRed ? PokerTheme.suitRed : PokerTheme.suitLight
    }

    private var bgColor: Color {
        if isSelected { return PokerTheme.slotBg.opacity(0.4) }
        if isHovered  { return PokerTheme.elevatedBg }
        return PokerTheme.cardBg
    }

    private var borderColor: Color {
        if isSelected { return PokerTheme.textMuted.opacity(0.3) }
        if isHovered  { return PokerTheme.borderLight }
        return PokerTheme.border.opacity(0.6)
    }
}

// MARK: - Hand Display (Hero + Community Slots)

struct HandDisplayView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        HStack(spacing: 24) {
            // Hero Hand
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(PokerTheme.accentGold)
                    Text("HERO")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(PokerTheme.textSecondary)
                        .tracking(1.2)
                }

                HStack(spacing: 6) {
                    ForEach(0 ..< 2, id: \.self) { i in
                        CardSlotView(
                            card: game.heroCards[i],
                            label: "H\(i + 1)",
                            isActive: game.activeSlot == i
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                game.tapSlot(i)
                            }
                        }
                    }
                }

                if !game.startingHandName.isEmpty {
                    Text(game.startingHandName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(PokerTheme.accentGold)
                }
            }

            Rectangle()
                .fill(PokerTheme.border)
                .frame(width: 1, height: 70)

            // Community Cards
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(PokerTheme.accentBlue)
                    Text("BOARD")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(PokerTheme.textSecondary)
                        .tracking(1.2)
                }

                HStack(spacing: 4) {
                    ForEach(0 ..< 3, id: \.self) { i in
                        CardSlotView(
                            card: game.communityCards[i],
                            label: "F\(i + 1)",
                            isActive: game.activeSlot == i + 2
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                game.tapSlot(i + 2)
                            }
                        }
                    }

                    Spacer().frame(width: 8)

                    CardSlotView(
                        card: game.communityCards[3],
                        label: "T",
                        isActive: game.activeSlot == 5
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            game.tapSlot(5)
                        }
                    }

                    Spacer().frame(width: 8)

                    CardSlotView(
                        card: game.communityCards[4],
                        label: "R",
                        isActive: game.activeSlot == 6
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            game.tapSlot(6)
                        }
                    }
                }

                // Street labels
                HStack(spacing: 0) {
                    Text("Flop")
                        .frame(width: 120, alignment: .center)
                    Spacer().frame(width: 8)
                    Text("Turn")
                        .frame(width: 38, alignment: .center)
                    Spacer().frame(width: 8)
                    Text("River")
                        .frame(width: 38, alignment: .center)
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(PokerTheme.textMuted)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PokerTheme.panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PokerTheme.border, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Single Card Slot

struct CardSlotView: View {
    let card: Card?
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var pulseAnimation = false

    var body: some View {
        Button(action: action) {
            Group {
                if let card = card {
                    filledCard(card)
                } else {
                    emptySlot
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private func filledCard(_ card: Card) -> some View {
        VStack(spacing: 1) {
            Text(card.rank.symbol)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(card.suit.isRed ? PokerTheme.suitRed : Color(white: 0.15))
        .frame(width: 38, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(white: 0.78), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.05 : 1.0)
    }

    private var emptySlot: some View {
        VStack(spacing: 3) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundColor(isActive ? PokerTheme.accentGreen : PokerTheme.textMuted)
        .frame(width: 38, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(PokerTheme.slotBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    isActive
                        ? PokerTheme.accentGreen.opacity(pulseAnimation ? 0.8 : 0.4)
                        : PokerTheme.border,
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .shadow(color: isActive ? PokerTheme.accentGreen.opacity(0.15) : .clear,
                radius: 6)
    }
}
