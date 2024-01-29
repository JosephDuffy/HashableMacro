#if canImport(ObjectiveC)
import ObjectiveC

/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// `==` function and `hash(into:)` functions will use the same properties. To
/// include a property decorate it with the ``HashableKey()`` macro.
///
/// If this is attached to a type conforming to `NSObjectProtocol` this will
/// instead override the `hash` property and `isEqual(_:)` function.
///
/// - parameter finalHashInto: When `true`, and the macro is attached to a
///   class that doesn't implement `NSObjectProtocol`, the `hash(into:)`
///   function will be marked `final`. This helps avoid a pitfall when
///   subclassing an `Equatable` class: the `==` function cannot be overridden
///   in a subclass and `==` will always use the superclass.
@attached(extension, conformances: Hashable, Equatable, NSObjectProtocol, names: named(hash), named(==), named(isEqual(_:)), named(hash))
@available(swift 5.9.2)
public macro CustomHashable(
    finalHashInto: Bool = true,
    nsObjectSubclassBehaviour: NSObjectSubclassBehaviour = .callSuperUnlessDirectSubclass
) = #externalMacro(module: "CustomHashableMacros", type: "CustomHashable")

public enum NSObjectSubclassBehaviour: Sendable {
    /// Never call `super.isEqual(to:)` and do not incorporate `super.hash`.
    case neverCallSuper

    /// Call `super.isEqual(to:)` and incorporate `super.hash` only when the
    /// type is not a direct subclass of `NSObject`.
    case callSuperUnlessDirectSubclass

    /// Always call `super.isEqual(to:)` and incorporate `super.hash`.
    case alwaysCallSuper
}
#else
/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// `==` function and `hash(into:)` functions will use the same properties. To
/// include a property decorate it with the ``HashableKey()`` macro.
///
/// If this is attached to a type conforming to `NSObjectProtocol` this will
/// instead override the `hash` property and `isEqual(_:)` function.
///
/// - parameter finalHashInto: When `true`, and the macro is attached to a
///   class, the `hash(into:)` function will be marked `final`. This helps avoid
///   a pitfall when subclassing an `Equatable` class: the `==` function cannot
///   be overridden in a subclass and `==` will always use the superclass.
@attached(extension, conformances: Hashable, Equatable, names: named(hash), named(==))
@available(swift 5.9.2)
public macro CustomHashable(
    finalHashInto: Bool = true
) = #externalMacro(module: "CustomHashableMacros", type: "CustomHashable")
#endif

@attached(peer)
public macro HashableKey() = #externalMacro(module: "CustomHashableMacros", type: "HashableKey")
