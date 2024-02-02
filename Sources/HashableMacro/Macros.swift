#if canImport(ObjectiveC)
import ObjectiveC
import HashableMacroFoundation

/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// `==` function and `hash(into:)` functions will use the same properties. To
/// include a property decorate it with the ``Hashed()`` macro.
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
public macro Hashable(
    finalHashInto: Bool = true,
    nsObjectSubclassBehaviour: NSObjectSubclassBehaviour = .callSuperUnlessDirectSubclass
) = #externalMacro(module: "HashableMacroMacros", type: "HashableMacro")
#else
/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// `==` function and `hash(into:)` functions will use the same properties. To
/// include a property decorate it with the ``Hashed()`` macro.
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
public macro Hashable(
    finalHashInto: Bool = true
) = #externalMacro(module: "HashableMacroMacros", type: "HashableMacro")
#endif

/// A marker macro that should be attached to all properties of a type that are
/// included in the `Hashable` implementation.
@attached(peer)
public macro Hashed() = #externalMacro(module: "HashableMacroMacros", type: "HashedMacro")

/// A marker macro that should be attached to all properties of a type that are
/// excluded in the `Hashable` implementation.
@attached(peer)
public macro NotHashed() = #externalMacro(module: "HashableMacroMacros", type: "NotHashedMacro")
