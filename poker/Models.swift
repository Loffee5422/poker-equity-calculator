import SwiftUI

// MARK: - Suit

enum Suit: Int, CaseIterable, Identifiable, Comparable, Hashable, Sendable {
    case spades = 0, hearts, diamonds, clubs

    var id: Int { rawValue }
    static func < (lhs: Suit, rhs: Suit) -> Bool { lhs.rawValue < rhs.rawValue }

    var symbol: String {
        switch self {
        case .spades:   return "♠"
        case .hearts:   return "♥"
        case .diamonds: return "♦"
        case .clubs:    return "♣"
        }
    }

    var name: String {
        switch self {
        case .spades:   return "Spades"
        case .hearts:   return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs:    return "Clubs"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }
    var color: Color { isRed ? PokerTheme.suitRed : PokerTheme.suitLight }
}

// MARK: - Rank

enum Rank: Int, CaseIterable, Identifiable, Comparable, Hashable, Sendable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    var id: Int { rawValue }
    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var symbol: String {
        switch self {
        case .ten:   return "T"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        default:     return "\(rawValue)"
        }
    }

    var longName: String {
        switch self {
        case .two:   return "Deuce"
        case .three: return "Three"
        case .four:  return "Four"
        case .five:  return "Five"
        case .six:   return "Six"
        case .seven: return "Seven"
        case .eight: return "Eight"
        case .nine:  return "Nine"
        case .ten:   return "Ten"
        case .jack:  return "Jack"
        case .queen: return "Queen"
        case .king:  return "King"
        case .ace:   return "Ace"
        }
    }

    var pluralName: String {
        switch self {
        case .six:   return "Sixes"
        case .two:   return "Deuces"
        default:     return longName + "s"
        }
    }
}

// MARK: - Card

struct Card: Identifiable, Hashable, Comparable, Sendable {
    let rank: Rank
    let suit: Suit

    var id: Int { suit.rawValue * 13 + rank.rawValue - 2 }
    var display: String { "\(rank.symbol)\(suit.symbol)" }

    static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.rank != rhs.rank ? lhs.rank < rhs.rank : lhs.suit < rhs.suit
    }

    static var fullDeck: [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in Card(rank: rank, suit: suit) }
        }
    }
}

// MARK: - Hand Category

enum HandCategory: Int, CaseIterable, Comparable, Sendable {
    case highCard = 0, onePair, twoPair, threeOfAKind
    case straight, flush, fullHouse, fourOfAKind, straightFlush

    static func < (lhs: HandCategory, rhs: HandCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var name: String {
        switch self {
        case .highCard:      return "High Card"
        case .onePair:       return "One Pair"
        case .twoPair:       return "Two Pair"
        case .threeOfAKind:  return "Three of a Kind"
        case .straight:      return "Straight"
        case .flush:         return "Flush"
        case .fullHouse:     return "Full House"
        case .fourOfAKind:   return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        }
    }

    var tier: Int {
        switch self {
        case .straightFlush, .fourOfAKind: return 3   // Monster
        case .fullHouse, .flush, .straight: return 2   // Strong
        case .threeOfAKind, .twoPair: return 1         // Decent
        default: return 0                               // Marginal
        }
    }
}

// MARK: - Hand Rank (comparable evaluation result)

struct HandRank: Comparable, Equatable, Sendable {
    let category: HandCategory
    let ranks: [Int]

    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.category != rhs.category { return lhs.category < rhs.category }
        for (l, r) in zip(lhs.ranks, rhs.ranks) {
            if l != r { return l < r }
        }
        return false
    }

    private static func rankWord(_ v: Int) -> String {
        switch v {
        case 14: return "Ace"
        case 13: return "King"
        case 12: return "Queen"
        case 11: return "Jack"
        case 10: return "Ten"
        case 9:  return "Nine"
        case 8:  return "Eight"
        case 7:  return "Seven"
        case 6:  return "Six"
        case 5:  return "Five"
        case 4:  return "Four"
        case 3:  return "Three"
        case 2:  return "Deuce"
        default: return "\(v)"
        }
    }

    private static func rankPlural(_ v: Int) -> String {
        switch v {
        case 6:  return "Sixes"
        case 2:  return "Deuces"
        default: return rankWord(v) + "s"
        }
    }

    var description: String {
        switch category {
        case .straightFlush:
            return ranks[0] == 14 ? "Royal Flush" : "Straight Flush, \(Self.rankWord(ranks[0]))-high"
        case .fourOfAKind:
            return "Four \(Self.rankPlural(ranks[0]))"
        case .fullHouse:
            return "\(Self.rankPlural(ranks[0])) full of \(Self.rankPlural(ranks[1]))"
        case .flush:
            return "Flush, \(Self.rankWord(ranks[0]))-high"
        case .straight:
            return "Straight, \(Self.rankWord(ranks[0]))-high"
        case .threeOfAKind:
            return "Three \(Self.rankPlural(ranks[0]))"
        case .twoPair:
            return "\(Self.rankPlural(ranks[0])) and \(Self.rankPlural(ranks[1]))"
        case .onePair:
            return "Pair of \(Self.rankPlural(ranks[0]))"
        case .highCard:
            return "\(Self.rankWord(ranks[0]))-high"
        }
    }
}

// MARK: - Losing Hand Group

struct LosingHandGroup: Identifiable, Sendable {
    let id = UUID()
    let category: HandCategory
    let count: Int        // villain combos from remaining deck that make this hand and beat hero
    let totalCombos: Int  // C(remaining, 2) — denominator for the percentage bar
    let examples: [[Card]]

    var pct: Double { Double(count) / Double(max(totalCombos, 1)) * 100 }
}

// MARK: - Equity Result

struct EquityResult: Sendable {
    let wins: Int
    let ties: Int
    let losses: Int
    let total: Int
    let handRank: HandRank

    var winPct: Double  { Double(wins)   / Double(max(total, 1)) * 100 }
    var tiePct: Double  { Double(ties)   / Double(max(total, 1)) * 100 }
    var losePct: Double { Double(losses) / Double(max(total, 1)) * 100 }
    var equity: Double  { (Double(wins) + Double(ties) / 2.0) / Double(max(total, 1)) * 100 }
}

// MARK: - Starting Hand Helper

struct StartingHand {
    static func name(for cards: [Card]) -> String {
        guard cards.count == 2 else { return "" }
        let sorted = cards.sorted { $0.rank > $1.rank }
        let hi = sorted[0], lo = sorted[1]
        if hi.rank == lo.rank { return "Pocket \(hi.rank.pluralName)" }
        let suitedness = hi.suit == lo.suit ? "Suited" : "Offsuit"
        return "\(hi.rank.longName)-\(lo.rank.longName) \(suitedness)"
    }
}

// MARK: - Theme

struct PokerTheme {
    // Backgrounds
    static let appBg       = Color(red: 0.047, green: 0.055, blue: 0.082)
    static let panelBg     = Color(red: 0.072, green: 0.085, blue: 0.125)
    static let cardBg      = Color(red: 0.110, green: 0.130, blue: 0.180)
    static let slotBg      = Color(red: 0.085, green: 0.100, blue: 0.145)
    static let elevatedBg  = Color(red: 0.095, green: 0.112, blue: 0.160)

    // Accent
    static let accentGreen  = Color(red: 0.000, green: 0.820, blue: 0.420)
    static let accentRed    = Color(red: 1.000, green: 0.275, blue: 0.340)
    static let accentGold   = Color(red: 1.000, green: 0.720, blue: 0.100)
    static let accentBlue   = Color(red: 0.310, green: 0.580, blue: 1.000)
    static let accentPurple = Color(red: 0.600, green: 0.400, blue: 1.000)

    // Suits
    static let suitRed   = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let suitLight = Color(red: 0.820, green: 0.850, blue: 0.890)

    // Text
    static let textPrimary   = Color(red: 0.933, green: 0.953, blue: 0.973)
    static let textSecondary = Color(red: 0.580, green: 0.640, blue: 0.720)
    static let textMuted     = Color(red: 0.380, green: 0.430, blue: 0.500)

    // Borders
    static let border      = Color(red: 0.150, green: 0.178, blue: 0.240)
    static let borderLight = Color(red: 0.200, green: 0.230, blue: 0.300)

    // Gradients
    static let panelGradient = LinearGradient(
        colors: [panelBg, Color(red: 0.060, green: 0.072, blue: 0.108)],
        startPoint: .top, endPoint: .bottom
    )
    static let greenGradient = LinearGradient(
        colors: [accentGreen, Color(red: 0.000, green: 0.650, blue: 0.350)],
        startPoint: .leading, endPoint: .trailing
    )
    static let redGradient = LinearGradient(
        colors: [accentRed, Color(red: 0.800, green: 0.200, blue: 0.280)],
        startPoint: .leading, endPoint: .trailing
    )
}
