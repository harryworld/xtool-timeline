import SwiftUI

enum EventEmoji {
    static func for_(_ title: String) -> String {
        let t = title.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }
        if has(["birthday", "生日", "bday"]) { return "🎂" }
        if has(["dinner", "lunch", "breakfast", "brunch", "food", "meal", "飯", "餐", "食"]) { return "🍽️" }
        if has(["coding", "code", "dev", "hack", "swift", "ios", "app", "程式"]) { return "💻" }
        if has(["class", "班", "課", "lesson", "course", "study", "學"]) { return "📚" }
        if has(["meeting", "sync", "call", "1:1", "standup", "會議", "chat"]) { return "💬" }
        if has(["gym", "run", "yoga", "workout", "運動"]) { return "🏃" }
        if has(["flight", "trip", "travel"]) { return "✈️" }
        if has(["coffee", "咖啡", "tea"]) { return "☕️" }
        return "✨"
    }
}
