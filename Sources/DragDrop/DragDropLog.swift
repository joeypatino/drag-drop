import Foundation

/// Replaces the DLog macro from PrefixHeader.pch. The trace points it feeds
/// document the flow through the rearrange and swap state machines.
@inline(__always)
func DLog(_ message: @autoclosure () -> String = "", function: StaticString = #function) {
    #if DEBUG
    let text = message()
    print(text.isEmpty ? "\(function)" : "\(function) \(text)")
    #endif
}
