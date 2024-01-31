# HashableMacro

> [!WARNING]
> This package requires Swift 5.9.2, which ships with Xcode 15.1. It is possible to add this package in Xcode 15.0 and 15.0.1 but the `@Hashable` macro will not be available.

`HashableMacro` is a Swift macro for adding `Hashable` conformance. It is particularly useful when synthesised conformance is not possible, such as with classes or a struct with 1 or more non-hashable properties.

The `@Hashable` macro is applied to the type that will conform to `Hashable` and the `Hashed` macro is applied to each of the properties that should contribute to the `Hashable` conformance.

```swift
/// A struct that uses the ``stringProperty`` and ``intProperty`` for the `Hashable` conformance.
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

## `NSObject` Support

When a type inherits from `NSObject` it should override `hash` and `isEqual(_:)`, not `hash(into:)` and `==`. `HashableMacro` detects when it is attached to a type conforming to `NSObjectProtocol` and will provide the `hash` property and `isEqual(_:)` function instead.

By default `HashableMacro` will incorporate `super.isEqual(_:)` and `super.hash`, unless the type is a direct subclass of `NSObject`. This behaviour can be changed with the `nsObjectSubclassBehaviour` parameter.

## `final` `hash(into:)` Function

When the `HashableMacro` macro is added to a class the generated `hash(into:)` function is marked `final`. This is because subclasses should not overload `==`. There are many reasons why this can be a bad idea, but specifically in Swift this does not work because:

- `!=` is not part of the `Equatable` protocol, but rather an extension on `Equatable`, causing it to always use the `==` implementation from the class that adds `Equatable` conformance
  - It is possible to overload `!=` but this is still not a good idea because...
- Anything that uses generics to compare the values, for example `XCTAssertEqual`, will use the `==` implementation from the class that adds `Equatable` conformance
  - It is possible to work around this by using a separate function, in a similar way to `NSObjectProtocol`, which is then called from `==`, but this requires extra decisions to be made that shouldn't be made by this library, e.g. what to do when a subclass is compared to its superclass.

If this is an issue for your usage you can pass `finalHashInto: false` to the macro, but it will not attempt to call `super` or use the properties annotated with `@Hashed` from the superclass.

## License

[MIT](./LICENSE)
