/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// `==` function and `hash(into:)` functions will use the same properties. To
/// include a property decorate it with the ``HashableKey()`` macro.
///
/// - parameter finalHashInto: When `true`, and the macro is attached to a
///   class, the `hash(into:)` function will be marked `final`. This helps avoid
///   a pitfall when subclassing an `Equatable` class: the `==` function cannot
///   be overridden in a subclass and `==` will always use the superclass.
@available(swift 5.9.2)
@attached(member, conformances: Hashable, Equatable, names: named(hash), named(==))
@attached(extension, conformances: Hashable, Equatable, names: named(hash), named(==))
public macro CustomHashable(finalHashInto: Bool = true) = #externalMacro(module: "CustomHashableMacros", type: "CustomHashable")

@attached(peer)
public macro HashableKey() = #externalMacro(module: "CustomHashableMacros", type: "HashableKey")
