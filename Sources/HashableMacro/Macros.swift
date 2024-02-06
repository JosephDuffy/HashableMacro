#if canImport(ObjectiveC)
import ObjectiveC
import HashableMacroFoundation

/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// hash generation and equality checks will use the same properties. To include
/// a property decorate it with the ``Hashed()`` macro. Alternatively the
/// ``NotHashed()`` can be used with struct properties to opt-out a subset of
/// properties, rather then opt-in.
///
/// When attached to a struct with only hashable properties the ``Hashed()`` and
/// ``NotHashed()`` macros can be omitted and all properties will be used.
///
/// When attached to a Swift type this macro will provide the `hash(into:)`
/// function and the `==(lhs:rhs:)` function. When attached to a type conforming
/// to `NSObjectProtocol` this will produce a `hash` property, an `isEqual(_:)`
/// function, and as `isEqualToType(_:)`-style function
///
/// For types conforming to `NSObjectProtocol` another object will only compare
/// equal if it of the same class (e.g. subclasses and superclasses will never
/// compare equal) and all annotated properties are equal.
///
/// - parameter finalHashInto: When `true`, and the macro is attached to a
///   class, the `hash(into:)` function will be marked `final`. This helps avoid
///   a pitfall when subclassing an `Equatable` class: the `==` function cannot
///   be overridden in a subclass and `==` will always use the superclass.
/// - parameter isEqualToTypeFunctionName: The name to use when using the
///  `isEqual(to:)` function from Objective-C. Defaults to using the name of the
///  class the macro is attached to. This only applies to types that conform to
///  `NSObjectProtocol`.
@attached(
    extension, 
    conformances: Hashable, Equatable, NSObjectProtocol, 
    names: named(hash(into:)), named(==), named(hash), named(isEqual(_:)), named(isEqual(to:)), arbitrary
)
@available(swift 5.9.2)
public macro Hashable(
    finalHashInto: Bool = true,
    isEqualToTypeFunctionName: IsEqualToTypeFunctionNameGeneration = .automatic
) = #externalMacro(module: "HashableMacroMacros", type: "HashableMacro")
#else
/// A macro that adds `Hashable` conformance to the type it is attached to. The
/// hash generation and equality checks will use the same properties. To include
/// a property decorate it with the ``Hashed()`` macro. Alternatively the
/// ``NotHashed()`` can be used with struct properties to opt-out a subset of
/// properties, rather then opt-in.
///
/// When attached to a struct with only hashable properties the ``Hashed()`` and
/// ``NotHashed()`` macros can be omitted and all properties will be used.
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
