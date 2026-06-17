import SwiftUI

// MARK: - Equity Dashboard

struct EquityDashboardView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let result = game.equityResult {
                equityDisplay(result)
                statsGrid(result)
                playSuggestion(result)
            } else if game.isCalculating {
                calculatingView
            } else {
                placeholderView
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

    // MARK: - Equity Display

    private func equityDisplay(_ result: EquityResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("EQUITY ANALYSIS", icon: "chart.bar.fill",
                             color: PokerTheme.accentGreen)
                Spacer()
                Text(result.handRank.description)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(handColor(result.handRank.category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(handColor(result.handRank.category).opacity(0.12))
                    )
            }

            // Large equity number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", result.equity))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(equityColor(result.equity))
                        Text("%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(equityColor(result.equity).opacity(0.6))
                            .offset(y: -2)
                    }
                    Text("vs. random hands")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(PokerTheme.textMuted)
                        .tracking(0.5)
                }

                Spacer()

                // Win / Tie / Lose chips
                VStack(alignment: .trailing, spacing: 4) {
                    pctChip("W", result.winPct, PokerTheme.accentGreen)
                    pctChip("T", result.tiePct, PokerTheme.accentGold)
                    pctChip("L", result.losePct, PokerTheme.accentRed)
                }
            }

            // Equity bar
            equityBar(result)

            // Board texture warning
            if let warning = game.boardWetnessWarning {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                        .offset(y: 1)
                    Text(warning)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(PokerTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    private func pctChip(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(String(format: "%.1f%%", value))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(PokerTheme.textPrimary)
        }
    }

    private func equityBar(_ result: EquityResult) -> some View {
        GeometryReader { geo in
            HStack(spacing: 1.5) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(PokerTheme.accentGreen)
                    .frame(width: max(2, geo.size.width * result.winPct / 100))

                if result.tiePct > 0.3 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(PokerTheme.accentGold)
                        .frame(width: max(2, geo.size.width * result.tiePct / 100))
                }

                RoundedRectangle(cornerRadius: 3)
                    .fill(PokerTheme.accentRed.opacity(0.65))
                    .frame(width: max(2, geo.size.width * result.losePct / 100))

                Spacer(minLength: 0)
            }
        }
        .frame(height: 10)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(PokerTheme.slotBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Stats Grid

    private func statsGrid(_ result: EquityResult) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()),
            GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 8) {
            statCard("Pot Odds",
                     game.potOdds.map { String(format: "%.1f : 1", $0) } ?? "--",
                     PokerTheme.accentBlue)
            statCard("EV (BB)",
                     game.evInBB.map { String(format: "%+.1f", $0) } ?? "--",
                     evColor)
            statCard("SPR",
                     game.stackToPot.map { String(format: "%.1f", $0) } ?? "--",
                     PokerTheme.accentPurple)
            statCard("Risk:Reward",
                     game.riskReward ?? "--",
                     PokerTheme.accentGold)
        }
    }

    private func statCard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(PokerTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(PokerTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PokerTheme.elevatedBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Play Suggestion

    private func playSuggestion(_ result: EquityResult) -> some View {
        let suggestion = StrategyAdvisor.playSuggestion(
            equity: result.equity,
            potOddsPct: game.potOddsPct,
            hand: result.handRank.category,
            street: game.currentStreet
        )

        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 11))
                .foregroundColor(PokerTheme.accentGold)
                .offset(y: 1)
            Text(suggestion)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(PokerTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PokerTheme.accentGold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PokerTheme.accentGold.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - States

    private var calculatingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(PokerTheme.accentGreen)
            Text("Running \(game.simulationCount.formatted()) simulations...")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(PokerTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 24))
                .foregroundColor(PokerTheme.textMuted.opacity(0.4))
            Text("Select two hero cards to begin analysis")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(PokerTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    // MARK: - Helpers

    private func equityColor(_ eq: Double) -> Color {
        if eq >= 60 { return PokerTheme.accentGreen }
        if eq >= 40 { return PokerTheme.accentGold }
        return PokerTheme.accentRed
    }

    private func handColor(_ cat: HandCategory) -> Color {
        switch cat.tier {
        case 3:  return PokerTheme.accentGold
        case 2:  return PokerTheme.accentGreen
        case 1:  return PokerTheme.accentBlue
        default: return PokerTheme.textSecondary
        }
    }

    private var evColor: Color {
        guard let ev = game.evInBB else { return PokerTheme.textMuted }
        return ev >= 0 ? PokerTheme.accentGreen : PokerTheme.accentRed
    }

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

// MARK: - Strategy Panel

struct StrategyPanelView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            betSizingSection
            mRatioSection
        }
    }

    // MARK: Bet Sizing

    private var betSizingSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                let tier = game.equityResult?.handRank.category.tier ?? 0
                let guides = StrategyAdvisor.betSizingGuide(
                    street: game.currentStreet, handTier: tier)

                ForEach(Array(guides.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(PokerTheme.accentBlue)
                            .frame(width: 4, height: 4)
                            .offset(y: 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(PokerTheme.textPrimary)
                            Text(item.detail)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(PokerTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(PokerTheme.accentGreen)
                Text("Bet Sizing \u{2014} \(game.currentStreet)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(PokerTheme.textPrimary)
            }
        }
        .tint(PokerTheme.textSecondary)
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

    // MARK: M-Ratio

    private var mRatioSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                if let m = game.mRatio {
                    let zone = StrategyAdvisor.mZone(m)

                    // M value + zone badge
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("M-Ratio")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(PokerTheme.textMuted)
                            Text(String(format: "%.1f", m))
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(PokerTheme.textPrimary)
                        }

                        Capsule()
                            .fill(zoneColor(zone.color))
                            .frame(width: 60, height: 22)
                            .overlay(
                                Text(zone.name)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )

                        Spacer()

                        // Visual gauge
                        mGauge(m)
                    }

                    // Strategy tip
                    Text(zone.advice)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(PokerTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Zone reference
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ZONE REFERENCE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(PokerTheme.textMuted)
                            .tracking(1)
                        zoneRow("Green",  "M > 20",   "Full strategy", .green)
                        zoneRow("Yellow", "10 < M \u{2264} 20", "Tighten range", .yellow)
                        zoneRow("Orange", "5 < M \u{2264} 10",  "Push/fold approaching", .orange)
                        zoneRow("Red",    "1 < M \u{2264} 5",   "Push/fold only", .red)
                        zoneRow("Dead",   "M \u{2264} 1",       "Shove any two", .gray)
                    }
                    .padding(.top, 4)
                } else {
                    Text("Set blind and stack sizes to calculate M-ratio.")
                        .font(.system(size: 11))
                        .foregroundColor(PokerTheme.textMuted)
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.needle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(PokerTheme.accentPurple)
                Text("M-Ratio Tournament Guide")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(PokerTheme.textPrimary)
            }
        }
        .tint(PokerTheme.textSecondary)
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

    // MARK: Helpers

    private func mGauge(_ m: Double) -> some View {
        let clamped = min(m, 30)
        let fraction = clamped / 30
        return ZStack(alignment: .leading) {
            Capsule().fill(PokerTheme.slotBg).frame(width: 60, height: 6)
            Capsule()
                .fill(zoneColor(StrategyAdvisor.mZone(m).color))
                .frame(width: 60 * fraction, height: 6)
        }
    }

    private func zoneRow(_ name: String, _ range: String, _ desc: String,
                         _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(name).font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(PokerTheme.textPrimary).frame(width: 42, alignment: .leading)
            Text(range).font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(PokerTheme.textMuted).frame(width: 70, alignment: .leading)
            Text(desc).font(.system(size: 9))
                .foregroundColor(PokerTheme.textSecondary)
        }
    }

    private func zoneColor(_ name: String) -> Color {
        switch name {
        case "green":  return PokerTheme.accentGreen
        case "yellow": return PokerTheme.accentGold
        case "orange": return .orange
        case "red":    return PokerTheme.accentRed
        default:       return .gray
        }
    }
}

// MARK: - Losing Hands View

struct LosingHandsView: View {
    @EnvironmentObject var game: GameViewModel

    var body: some View {
        let groups = game.losingHandGroups
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                header(groups)
                ForEach(groups) { group in
                    groupRow(group)
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

    private func header(_ groups: [LosingHandGroup]) -> some View {
        let totalLosing = groups.reduce(0) { $0 + $1.count }
        let totalCombos = groups.first?.totalCombos ?? 1
        return HStack {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(PokerTheme.accentRed)
                Text("LOSING TO")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(PokerTheme.textSecondary)
                    .tracking(1.2)
            }
            Spacer()
            Text("\(totalLosing) of \(totalCombos) combos")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(PokerTheme.accentRed.opacity(0.8))
        }
    }

    private func groupRow(_ group: LosingHandGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(group.category.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(categoryColor(group.category))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(categoryColor(group.category).opacity(0.12))
                    )

                Spacer()

                Text("\(group.count) combos")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(PokerTheme.textMuted)

                Text(String(format: "%.1f%%", group.pct))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(categoryColor(group.category).opacity(0.85))
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(PokerTheme.slotBg)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(categoryColor(group.category).opacity(0.55))
                        .frame(width: max(4, geo.size.width * group.pct / 100))
                }
            }
            .frame(height: 5)

            if !group.examples.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(group.examples.enumerated()), id: \.offset) { _, hand in
                        exampleHand(hand)
                    }
                    if group.count > group.examples.count {
                        Text("+ \(group.count - group.examples.count) more")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(PokerTheme.textMuted)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PokerTheme.elevatedBg)
        )
    }

    private func exampleHand(_ cards: [Card]) -> some View {
        HStack(spacing: 3) {
            ForEach(cards) { card in
                Text(card.display)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(card.suit.color)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(PokerTheme.slotBg)
        )
    }

    private func categoryColor(_ cat: HandCategory) -> Color {
        switch cat.tier {
        case 3:  return PokerTheme.accentRed
        case 2:  return Color(red: 1.0, green: 0.45, blue: 0.1)
        case 1:  return PokerTheme.accentGold
        default: return PokerTheme.textSecondary
        }
    }
}
