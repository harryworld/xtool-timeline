import SwiftUI

/// Run a state change with animations explicitly disabled, overriding any inherited transaction.
@MainActor
func withoutAnimation(_ body: () -> Void) {
    var t = Transaction(animation: nil)
    t.disablesAnimations = true
    withTransaction(t, body)
}

/// Grow a page window on settle only, far from the visible page, so nothing shifts mid-gesture.
struct PageWindow: Equatable {
    var lower: Int
    var upper: Int
    let chunk: Int
    let margin: Int

    init(around p: Int, chunk: Int, margin: Int) {
        self.chunk = chunk; self.margin = margin
        lower = p - chunk; upper = p + chunk
    }

    mutating func include(_ p: Int) {
        if p - lower < margin { lower = p - chunk }
        if upper - p < margin { upper = p + chunk }
    }
}
