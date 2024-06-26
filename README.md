# HashableMacro

[![Tests](https://github.com/JosephDuffy/HashableMacro/actions/workflows/tests.yml/badge.svg)](https://github.com/JosephDuffy/HashableMacro/actions/workflows/tests.yml)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJosephDuffy%2FHashableMacro%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/JosephDuffy/HashableMacro)

> [!WARNING]
> This package requires Swift 5.9.2, which ships with Xcode 15.1. This package will fail to compile with Swift 5.9.0 (Xcode 15.0 and 15.0.1).

`@Hashable` is a Swift macro for adding `Hashable` conformance. It is particularly useful when synthesised conformance is not possible, such as with classes or a struct with 1 or more non-hashable properties.

The `@Hashable` macro is applied to the type that will conform to `Hashable` and the `Hashed` macro is applied to each of the properties that should contribute to the `Hashable` conformance.

```swift
import HashableMacro

/// A struct that uses the ``stringProperty`` and ``intProperty`` for `Hashable` conformance.
@Hashable
struct MyStruct {
    // Any property that is hashable is supported.
    @Hashed
    let stringProperty: String

    // Works on private properties, too.
    @Hashed
    private let intProperty: Int

    // Non-decorated properties are ignored
    let notHashableType: NotHashableType
}
```

All decorated properties are included in both the `==` and `hash(into:)` implementations, ensuring the [contract of `Hashable`](<https://developer.apple.com/documentation/swift/hashable#:~:text=Two%20instances%20that%20are%20equal%20must%20feed%20the%20same%20values%20to%20Hasher%20in%20hash(into%3A)%2C%20in%20the%20same%20order.>) is upheld:

> Two instances that are equal must feed the same values to `Hasher` in `hash(into:)`, in the same order.

[DocC documentation for HashableMacro is hosted by Swift Package Index](https://swiftpackageindex.com/JosephDuffy/HashableMacro/main/documentation/hashablemacro). Most of the implementation can be seen in the [Macros.swift file](./Sources/HashableMacro/Macros.swift).

## `@NotHashed` Macro

The `@NotHashed` macro can be applied to properties that _should not_ be included in the `Hashable` conformance. If this macro is used to decorate a property the `@Hashed` macro should not be used to decorate a property in the same type.

This can be useful for types that have a smaller number of non-hashable properties than hashable properties.

```swift
/// A struct that uses the ``stringProperty`` and ``intProperty`` for `Hashable` conformance.
@Hashable
struct MyStruct {
    // Implicitly used for `Hashable` conformance
    let stringProperty: String

    // Implicitly used for `Hashable` conformance
    private let intProperty: Int

    // Explicitly excluded from `Hashable` conformance
    @NotHashed
    let notHashableType: NotHashableType
}
```

## `@Hashable` Only

If the `@Hashable` macro is added but no properties are decorated with `@Hashed` or `@NotHashed` then all stored properties will be used.

```swift
/// A struct that uses the ``stringProperty`` and ``intProperty`` for `Hashable` conformance.
@Hashable
struct MyStruct {
    // Implicitly used for `Hashable` conformance
    let stringProperty: String

    // Implicitly used for `Hashable` conformance
    private let intProperty: Int

    // Implicitly excluded from `Hashable` conformance
    var computedProperty: Bool {
        intProperty > 0
    }
}
```

One (fairly minor) advantage of this over adding `Hashable` conformance without the macro is that you can see the code being produce via Right Click → Expand Macro.

## `NSObject` Support

When a type implements `NSObjectProtocol` (e.g. it inherits from `NSObject`) it should override `hash` and `isEqual(_:)`, not `hash(into:)` and `==`. `@Hashable` detects when it is attached to a type conforming to `NSObjectProtocol` and will provide the `hash` property and `isEqual(_:)` function instead.

`@Hashable` will also provide an `isEqual(to:)` function that takes a parameter that matches `Self`, which will also have an appropriately named Objective-C function.

```swift
import HashableMacro

@Hashable
final class Person: NSObject {
    @Hashed
    var name: String = ""
}

extension Person {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.name)
        return hasher.finalize()
    }
}

extension Person {
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Person else {
            return false
        }
        guard type(of: self) == type(of: object) else {
            return false
        }
        return self.isEqual(to: object)
    }
    @objc(isEqualToPerson:)
    func isEqual(to object: Person) -> Bool {
        return self.name == object.name
    }
}
```

## `final` `hash(into:)` Function

When the `@Hashable` macro is added to a class the generated `hash(into:)` function is marked `final`. This is because subclasses should not overload `==`. There are many reasons why this can be a bad idea, but specifically in Swift this does not work because:

- `!=` is not part of the `Equatable` protocol, but rather an extension on `Equatable`, causing it to always use the `==` implementation from the class that adds `Equatable` conformance
  - It is possible to overload `!=` but this is still not a good idea because...
- Anything that uses generics to compare the values, for example `XCTAssertEqual`, will use the `==` implementation from the class that adds `Equatable` conformance
  - It is possible to work around this by using a separate function, in a similar way to `NSObject`, which is then called from `==`

If this is an issue for your usage you can pass `finalHashInto: false` to the macro, but it will not attempt to call `super` or use properties from the superclass.

This is not something the macro aims to solve.

## License

[MIT](./LICENSE)
