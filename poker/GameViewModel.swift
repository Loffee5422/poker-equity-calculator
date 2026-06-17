import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Card Slots

    @Published var heroCards: [Card?] = [nil, nil]
    @Published var communityCards: [Card?] = [nil, nil, nil, nil, nil]
    @Published var activeSlot: Int = 0   // 0-1 hero, 2-6 community, 7 = all full

    // MARK: - Table Parameters

    @Published var numOpponents: Int = 1
    @Published var potSize: Double = 10.0
    @Published var betToCall: Double = 2.0
    @Published var heroStack: Double = 100.0
    @Published var bigBlind: Double = 1.0
    @Published var smallBlind: Double = 0.5
    @Published var antes: Double = 0.0
    @Published var simulationCount: Int = 10_000

    // MARK: - Results

    @Published var equityResult: EquityResult?
    @Published var isCalculating = false
    @Published var losingHandGroups: [LosingHandGroup] = []
    private var calculationTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var selectedCards: Set<Card> {
        var s = Set<Card>()
        for c in heroCards where c != nil      { s.insert(c!) }
        for c in communityCards where c != nil  { s.insert(c!) }
        return s
    }

    var heroComplete: Bool { heroCards.allSatisfy { $0 != nil } }

    var allCommunityCards: [Card] { communityCards.compactMap { $0 } }

    var currentStreet: String {
        switch allCommunityCards.count {
        case 0:  return "Preflop"
        case 3:  return "Flop"
        case 4:  return "Turn"
        case 5:  return "River"
        default: return "Dealing"
        }
    }

    var activeSlotName: String {
        switch activeSlot {
        case 0: return "Hero 1"
        case 1: return "Hero 2"
        case 2: return "Flop 1"
        case 3: return "Flop 2"
        case 4: return "Flop 3"
        case 5: return "Turn"
        case 6: return "River"
        default: return "Done"
        }
    }

    var startingHandName: String {
        let hero = heroCards.compactMap { $0 }
        return hero.count == 2 ? StartingHand.name(for: hero) : ""
    }

    // MARK: - Card Selection

    func selectCard(_ card: Card) {
        if selectedCards.contains(card) {
            deselectCard(card)
            return
        }
        guard activeSlot < 7 else { return }

        if activeSlot < 2 {
            heroCards[activeSlot] = card
        } else {
            communityCards[activeSlot - 2] = card
        }
        advanceSlot()

        if heroComplete { calculateEquity() }
    }

    func deselectCard(_ card: Card) {
        for i in 0 ..< 2 where heroCards[i] == card {
            heroCards[i] = nil
            activeSlot = i
            equityResult = nil
            return
        }
        for i in 0 ..< 5 where communityCards[i] == card {
            communityCards[i] = nil
            activeSlot = i + 2
            if heroComplete { calculateEquity() }
            return
        }
    }

    func tapSlot(_ index: Int) {
        if index < 2 {
            if heroCards[index] != nil {
                heroCards[index] = nil
                equityResult = nil
            }
        } else if communityCards[index - 2] != nil {
            communityCards[index - 2] = nil
            if heroComplete { calculateEquity() }
        }
        activeSlot = index
    }

    private func advanceSlot() {
        for offset in 1 ... 7 {
            let idx = (activeSlot + offset) % 8
            if idx >= 7 { continue }
            if idx < 2 && heroCards[idx] == nil        { activeSlot = idx; return }
            if idx >= 2 && communityCards[idx - 2] == nil { activeSlot = idx; return }
        }
        activeSlot = 7
    }

    // MARK: - Equity Calculation

    func calculateEquity() {
        guard heroComplete else { return }
        computeLosingHands()

        calculationTask?.cancel()
        equityResult = nil
        isCalculating = true
        let hero = heroCards.compactMap { $0 }
        let community = allCommunityCards
        let opps = numOpponents
        let sims = simulationCount

        calculationTask = Task { @MainActor in
            // Listen to chunked results
            for await result in MonteCarloEngine.calculateEquityStream(
                hero: hero, community: community,
                opponents: opps, simulations: sims
            ) {
                if Task.isCancelled { break }
                self.equityResult = result
            }
            
            if !Task.isCancelled {
                self.isCalculating = false
            }
        }
    }

    func reset() {
        calculationTask?.cancel()
        heroCards = [nil, nil]
        communityCards = [nil, nil, nil, nil, nil]
        activeSlot = 0
        equityResult = nil
        isCalculating = false
        losingHandGroups = []
    }

    // MARK: - Losing Hand Analysis

    private func computeLosingHands() {
        let board = allCommunityCards
        guard board.count >= 3 else { losingHandGroups = []; return }

        let hero = heroCards.compactMap { $0 }
        let heroRank = HandEvaluator.evaluate(hero + board)
        let known = Set(hero + board)
        let remaining = Card.fullDeck.filter { !known.contains($0) }
        let n = remaining.count

        var groups: [HandCategory: (count: Int, examples: [[Card]])] = [:]
        var totalCombos = 0

        for i in 0 ..< n {
            for j in i + 1 ..< n {
                totalCombos += 1
                let opp = [remaining[i], remaining[j]]
                let oppRank = HandEvaluator.evaluate(opp + board)
                if oppRank > heroRank {
                    let cat = oppRank.category
                    var entry = groups[cat] ?? (0, [])
                    entry.count += 1
                    if entry.examples.count < 3 { entry.examples.append(opp) }
                    groups[cat] = entry
                }
            }
        }

        losingHandGroups = groups
            .map { cat, data in
                LosingHandGroup(category: cat, count: data.count,
                                totalCombos: totalCombos, examples: data.examples)
            }
            .sorted { $0.category > $1.category }
    }

    func updateOpponents(_ delta: Int) {
        let new = numOpponents + delta
        guard (1...8).contains(new) else { return }
        numOpponents = new
    }

    // MARK: - Statistics

    var potOdds: Double? {
        guard betToCall > 0, potSize > 0 else { return nil }
        return potSize / betToCall
    }

    var potOddsPct: Double? {
        guard betToCall > 0, potSize > 0 else { return nil }
        return betToCall / (potSize + betToCall) * 100
    }

    var expectedValue: Double? {
        guard let eq = equityResult, betToCall > 0 else { return nil }
        let eqFrac = eq.equity / 100
        return eqFrac * (potSize + betToCall) - betToCall
    }

    var evInBB: Double? {
        guard let ev = expectedValue, bigBlind > 0 else { return nil }
        return ev / bigBlind
    }

    var stackToPot: Double? {
        guard potSize > 0 else { return nil }
        return heroStack / potSize
    }

    var riskReward: String? {
        guard betToCall > 0, potSize > 0 else { return nil }
        let ratio = potSize / betToCall
        return String(format: "1 : %.1f", ratio)
    }

    var mRatio: Double? {
        let orbital = smallBlind + bigBlind + antes
        guard orbital > 0 else { return nil }
        return heroStack / orbital
    }

    // MARK: - Board Texture

    /// 0–10 wetness score. Counts connected card pairs (within 4 ranks) plus
    /// flush bonuses. High scores (≥7) mean random-hand equity overstates
    /// real villain-range equity significantly.
    var boardWetness: Int {
        let cards = allCommunityCards
        guard cards.count >= 3 else { return 0 }
        let values = cards.map { $0.rank.rawValue }.sorted()
        let n = cards.count

        var score = 0
        for i in 0 ..< n {
            for j in i + 1 ..< n {
                if values[j] - values[i] <= 4 { score += 1 }
            }
        }

        let suitCounts = Dictionary(grouping: cards, by: { $0.suit }).values.map(\.count)
        for count in suitCounts where count >= 3 { score += count }

        return min(score, 10)
    }

    var boardWetnessWarning: String? {
        guard boardWetness >= 7,
              currentStreet == "Turn" || currentStreet == "River" else { return nil }
        return "Wet board \u{2014} equity shown is vs. random hands. Against a real range (straights, flushes, two-pair), your actual equity may be significantly lower."
    }
}
