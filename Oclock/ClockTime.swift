import Foundation

/// Une heure sur 12 heures, avec sa lecture anglaise past/to.
struct ClockTime: Hashable, Codable {
    let hour: Int    // 1...12
    let minute: Int  // 0...59

    init(hour: Int, minute: Int) {
        self.hour = ((hour - 1) % 12 + 12) % 12 + 1
        self.minute = (minute % 60 + 60) % 60
    }

    private var nextHour: Int { hour % 12 + 1 }
    private var isTo: Bool { minute > 30 }
    private var namedHour: Int { isTo ? nextHour : hour }

    var digital: String { String(format: "%d:%02d", hour, minute) }

    var phrase: String {
        switch minute {
        case 0: return "\(Self.word(hour)) o'clock"
        case 15: return "quarter past \(Self.word(hour))"
        case 30: return "half past \(Self.word(hour))"
        case 45: return "quarter to \(Self.word(nextHour))"
        case 1..<30: return "\(Self.count(minute)) past \(Self.word(hour))"
        default: return "\(Self.count(60 - minute)) to \(Self.word(nextHour))"
        }
    }

    /// Le raisonnement en français, affiché après chaque réponse.
    var explanation: String {
        switch minute {
        case 0: return "\(hour) h pile : o'clock"
        case 15: return "Un quart d'heure après \(hour) h : past"
        case 30: return "La demie après \(hour) h : half past"
        case 45: return "Un quart d'heure avant \(nextHour) h : to"
        case 1..<30: return "\(Self.minutes(minute)) après \(hour) h : past"
        default: return "\(Self.minutes(60 - minute)) avant \(nextHour) h : to"
        }
    }

    /// Pourquoi `wrong` n'est pas la bonne lecture de cette heure.
    func reason(forChoosing wrong: ClockTime) -> String {
        if minute == 0 || minute == 30 {
            if wrong.minute != minute {
                return minute == 0
                    ? "La grande aiguille est sur le 12 : c'est o'clock, pas half past."
                    : "La grande aiguille est sur le 6 : c'est half past, pas o'clock."
            }
            return minute == 0
                ? "La petite aiguille est sur le \(hour), pas sur le \(wrong.hour)."
                : "La petite aiguille est entre le \(hour) et le \(nextHour) : half past garde l'heure passée, \(hour)."
        }

        var reasons: [String] = []
        if isTo != wrong.isTo {
            reasons.append(
                "La grande aiguille est à \(isTo ? "gauche" : "droite") du cadran : "
                    + "on dit \(isTo ? "to" : "past"), pas \(wrong.isTo ? "to" : "past")."
            )
        }
        if namedHour != wrong.namedHour {
            reasons.append(
                isTo
                    ? "Avec to, on annonce l'heure qui arrive : \(namedHour), pas \(wrong.namedHour)."
                    : "Avec past, on annonce l'heure qui vient de passer : \(namedHour), pas \(wrong.namedHour)."
            )
        }
        return reasons.joined(separator: " ")
    }

    /// Les pièges classiques : past/to inversés et heure décalée.
    var distractors: [ClockTime] {
        if minute == 0 || minute == 30 {
            return [
                ClockTime(hour: hour + 1, minute: minute),
                ClockTime(hour: hour - 1, minute: minute),
                ClockTime(hour: hour, minute: minute + 30),
            ]
        }
        let shift = minute < 30 ? -1 : 1
        return [
            ClockTime(hour: hour + shift, minute: 60 - minute),
            ClockTime(hour: hour, minute: 60 - minute),
            ClockTime(hour: hour - shift, minute: minute),
        ]
    }

    private static func minutes(_ n: Int) -> String {
        n == 1 ? "1 minute" : "\(n) minutes"
    }

    private static func count(_ n: Int) -> String {
        if n % 5 == 0 { return word(n) }
        return n == 1 ? "one minute" : "\(word(n)) minutes"
    }

    private static func word(_ n: Int) -> String {
        let units = [
            "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
            "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
            "eighteen", "nineteen", "twenty",
        ]
        return n <= 20 ? units[n] : "twenty-\(units[n - 20])"
    }
}
