#if canImport(ObjectiveC)
/// The behaviour applied to the `Hashable` implementation of a type that
/// conforms to `NSObjectProtocol`.
public enum NSObjectSubclassBehaviour: Sendable {
    /// Never call `super.isEqual(to:)` and do not incorporate `super.hash`.
    case neverCallSuper

    /// Call `super.isEqual(to:)` and incorporate `super.hash` only when the
    /// type is not a direct subclass of `NSObject`.
    case callSuperUnlessDirectSubclass

    /// Always call `super.isEqual(to:)` and incorporate `super.hash`.
    case alwaysCallSuper
}
#endif
