import Foundation

// MARK: - Hand Evaluator

struct HandEvaluator {

    /// Evaluate the best 5-card hand from 5-7 cards.
    static func evaluate(_ cards: [Card]) -> HandRank {
        guard cards.count >= 5 else {
            let sorted = cards.map { $0.rank.rawValue }.sorted(by: >)
            return HandRank(category: .highCard, ranks: sorted)
        }
        if cards.count == 5 { return evaluate5(cards) }

        var best: HandRank?
        let n = cards.count
        // Avoid combinations array allocations by generating indices directly
        for i0 in 0 ..< n - 4 {
            for i1 in i0 + 1 ..< n - 3 {
                for i2 in i1 + 1 ..< n - 2 {
                    for i3 in i2 + 1 ..< n - 1 {
                        for i4 in i3 + 1 ..< n {
                            let combo = [cards[i0], cards[i1], cards[i2], cards[i3], cards[i4]]
                            let rank = evaluate5(combo)
                            if best == nil || rank > best! { best = rank }
                        }
                    }
                }
            }
        }
        return best!
    }

    // MARK: Five-card evaluation

    private static func evaluate5(_ cards: [Card]) -> HandRank {
        let values = cards.map { $0.rank.rawValue }
        let suits  = cards.map { $0.suit }

        let isFlush = Set(suits).count == 1

        // Straight detection
        let unique = Array(Set(values)).sorted(by: >)
        var isStraight = false
        var straightHigh = 0

        if unique.count == 5 {
            if unique[0] - unique[4] == 4 {
                isStraight = true
                straightHigh = unique[0]
            }
            // Wheel: A-2-3-4-5
            if Set(unique) == Set([14, 5, 4, 3, 2]) {
                isStraight = true
                straightHigh = 5
            }
        }

        // Group by rank count
        var counts: [Int: Int] = [:]
        for v in values { counts[v, default: 0] += 1 }
        let groups = counts.sorted { a, b in
            a.value != b.value ? a.value > b.value : a.key > b.key
        }

        // Classify
        if isStraight && isFlush {
            return HandRank(category: .straightFlush, ranks: [straightHigh])
        }
        if groups[0].value == 4 {
            return HandRank(category: .fourOfAKind,
                            ranks: [groups[0].key, groups[1].key])
        }
        if groups[0].value == 3 && groups.count >= 2 && groups[1].value == 2 {
            return HandRank(category: .fullHouse,
                            ranks: [groups[0].key, groups[1].key])
        }
        if isFlush {
            return HandRank(category: .flush,
                            ranks: Array(unique.prefix(5)))
        }
        if isStraight {
            return HandRank(category: .straight, ranks: [straightHigh])
        }
        if groups[0].value == 3 {
            let kickers = groups.dropFirst().map(\.key).sorted(by: >)
            return HandRank(category: .threeOfAKind,
                            ranks: [groups[0].key] + Array(kickers.prefix(2)))
        }
        if groups[0].value == 2 && groups.count >= 2 && groups[1].value == 2 {
            let hi = max(groups[0].key, groups[1].key)
            let lo = min(groups[0].key, groups[1].key)
            let kicker = groups.dropFirst(2).map(\.key).max() ?? 0
            return HandRank(category: .twoPair, ranks: [hi, lo, kicker])
        }
        if groups[0].value == 2 {
            let kickers = groups.dropFirst().map(\.key).sorted(by: >)
            return HandRank(category: .onePair,
                            ranks: [groups[0].key] + Array(kickers.prefix(3)))
        }
        return HandRank(category: .highCard,
                        ranks: Array(unique.prefix(5)))
    }

    // MARK: Combinations

    static func combinations<T>(_ array: [T], choose k: Int) -> [[T]] {
        guard k > 0, k <= array.count else {
            return k == 0 ? [[]] : []
        }
        if k == array.count { return [array] }
        var result: [[T]] = []
        result.reserveCapacity(binomial(array.count, k))

        func build(_ start: Int, _ current: inout [T]) {
            if current.count == k { result.append(current); return }
            let remaining = k - current.count
            for i in start ... (array.count - remaining) {
                current.append(array[i])
                build(i + 1, &current)
                current.removeLast()
            }
        }
        var buf: [T] = []
        build(0, &buf)
        return result
    }

    private static func binomial(_ n: Int, _ k: Int) -> Int {
        if k > n { return 0 }
        if k == 0 || k == n { return 1 }
        var result = 1
        for i in 0 ..< min(k, n - k) {
            result = result * (n - i) / (i + 1)
        }
        return result
    }
}

// MARK: - Fast PRNG

struct Xoroshiro128Plus {
    var state0: UInt64
    var state1: UInt64
    
    init() {
        state0 = UInt64.random(in: 1...UInt64.max)
        state1 = UInt64.random(in: 1...UInt64.max)
    }
    
    mutating func next() -> UInt64 {
        let s0 = state0
        var s1 = state1
        let result = s0 &+ s1
        s1 ^= s0
        state0 = ((s0 << 24) | (s0 >> 40)) ^ s1 ^ (s1 << 16)
        state1 = (s1 << 37) | (s1 >> 27)
        return result
    }
    
    mutating func next(upperBound: Int) -> Int {
        return Int(next() % UInt64(upperBound))
    }
}

// MARK: - Monte Carlo Engine

struct MonteCarloEngine {

    static func calculateEquityStream(
        hero: [Card],
        community: [Card],
        opponents: Int,
        simulations: Int = 20_000
    ) -> AsyncStream<EquityResult> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) {
                guard hero.count == 2, opponents >= 1 else {
                    continuation.yield(EquityResult(wins: 0, ties: 0, losses: 0, total: 0,
                                                    handRank: HandRank(category: .highCard, ranks: [])))
                    continuation.finish()
                    return
                }

                let known = Set(hero + community)
                var remaining = Card.fullDeck.filter { !known.contains($0) }
                let communityNeeded = 5 - community.count
                let cardsPerSim = communityNeeded + 2 * opponents

                guard remaining.count >= cardsPerSim else {
                    continuation.yield(EquityResult(wins: 0, ties: 0, losses: 0, total: 0,
                                                    handRank: HandEvaluator.evaluate(hero + community)))
                    continuation.finish()
                    return
                }

                var wins = 0, ties = 0, losses = 0
                let currentHand = HandEvaluator.evaluate(hero + community)
                var prng = Xoroshiro128Plus()
                
                let chunkSize = 1_000
                var iterationsDone = 0

                remaining.withUnsafeMutableBufferPointer { buffer in
                    // Safe fast extraction
                    let count = buffer.count
                    
                    while iterationsDone < simulations {
                        if Task.isCancelled { break }
                        
                        let currentChunk = min(chunkSize, simulations - iterationsDone)
                        
                        for _ in 0 ..< currentChunk {
                            // Partial Fisher-Yates with fast PRNG
                            for i in 0 ..< cardsPerSim {
                                let j = i + prng.next(upperBound: count - i)
                                buffer.swapAt(i, j)
                            }

                            // Build full board
                            var board = community
                            for i in 0 ..< communityNeeded {
                                board.append(buffer[i])
                            }

                            let heroRank = HandEvaluator.evaluate(hero + board)

                            // Find best opponent hand
                            var bestOpp: HandRank?
                            var idx = communityNeeded
                            for _ in 0 ..< opponents {
                                let opp = [buffer[idx], buffer[idx + 1]]
                                idx += 2
                                let oppRank = HandEvaluator.evaluate(opp + board)
                                if bestOpp == nil || oppRank > bestOpp! { bestOpp = oppRank }
                            }

                            if let best = bestOpp {
                                if heroRank > best      { wins += 1 }
                                else if heroRank == best { ties += 1 }
                                else                     { losses += 1 }
                            } else {
                                wins += 1
                            }
                        }
                        
                        iterationsDone += currentChunk
                        
                        continuation.yield(EquityResult(
                            wins: wins, ties: ties, losses: losses,
                            total: iterationsDone, handRank: currentHand
                        ))
                    }
                }
                
                continuation.finish()
            }
        }
    }
}

// MARK: - Strategy Advisor

struct StrategyAdvisor {

    static func playSuggestion(equity: Double, potOddsPct: Double?,
                               hand: HandCategory, street: String) -> String {
        guard let odds = potOddsPct else {
            return "Enter pot and bet sizes for action recommendations."
        }

        let profitable = equity > odds

        if equity > 80 {
            return "Dominant position. Raise for maximum value \u{2014} you want action."
        }
        if equity > 65 {
            return profitable
                ? "Strong equity edge. Calling is clearly profitable; raising for value is best."
                : "Strong hand, but the price is steep. Consider pot control or a smaller raise."
        }
        if equity > 50 {
            return profitable
                ? "Moderate edge. A call is +EV here. Size your bets to deny opponent odds."
                : "Thin margin at this price. Fold unless implied odds justify continuing."
        }
        if equity > 33 {
            return profitable
                ? "Drawing range. Pot odds support a call \u{2014} realize your equity."
                : "Behind with bad odds. Fold unless significant implied odds exist."
        }
        return "Weak equity. Fold unless this is a pure bluff spot with good fold equity."
    }

    // MARK: Bet sizing guide by street

    static func betSizingGuide(street: String, handTier: Int) -> [(label: String, detail: String)] {
        switch street {
        case "Preflop":
            return [
                ("Open Raise", "2.5\u{2013}3x BB from early position, 2.2\u{2013}2.5x from late position."),
                ("3-Bet", "3x the open in position, 3.5\u{2013}4x out of position."),
                ("4-Bet", "2\u{2013}2.5x the 3-bet, or shove if SPR < 3."),
                ("Limping", "Generally avoid. Open-raise or fold.")
            ]
        case "Flop":
            if handTier >= 2 {
                return [
                    ("Value Bet", "55\u{2013}75% pot with strong made hands on wet boards."),
                    ("Slow Play", "33% pot or check on dry boards to keep weaker hands in."),
                    ("Protection", "66\u{2013}80% pot when vulnerable to draws.")
                ]
            } else {
                return [
                    ("C-Bet Bluff", "25\u{2013}33% pot on dry boards; check wet boards without equity."),
                    ("Semi-Bluff", "55\u{2013}66% pot with flush/straight draws."),
                    ("Give Up", "Check-fold with no equity and no fold equity.")
                ]
            }
        case "Turn":
            return [
                ("Value", "66\u{2013}80% pot to charge draws and build the pot."),
                ("Polarize", "Large bets (75\u{2013}100%) with nutted hands or bluffs."),
                ("Pot Control", "Check or small bet (33%) with medium-strength hands.")
            ]
        case "River":
            return [
                ("Thin Value", "33\u{2013}50% pot when you beat most of villain's calling range."),
                ("Max Value", "66\u{2013}100% pot with the nuts or near-nuts."),
                ("Bluff", "75\u{2013}110% pot \u{2014} size to maximize fold equity.")
            ]
        default:
            return [("Waiting", "Select cards to see sizing advice.")]
        }
    }

    // MARK: M-Ratio

    static func mZone(_ m: Double) -> (name: String, color: String, advice: String) {
        if m > 20 {
            return ("Green", "green",
                    "Full flexibility. Play your optimal range, mix bluffs, leverage position and stack depth for post-flop play.")
        }
        if m > 10 {
            return ("Yellow", "yellow",
                    "Tighten opening range. Drop speculative hands. Focus on high-equity spots and avoid marginal post-flop situations.")
        }
        if m > 5 {
            return ("Orange", "orange",
                    "Push/fold approaching. Open-shove or fold. Minimize post-flop play. Target steal spots from late position.")
        }
        if m > 1 {
            return ("Red", "red",
                    "Push/fold only. Any reasonable hand is a shove: pairs, suited aces, broadway. Time is critical.")
        }
        return ("Dead", "gray",
                "Desperate. Shove any two cards with fold equity. Survival requires immediate action.")
    }
}
