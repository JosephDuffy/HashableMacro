# CustomHashable

> [!WARNING]
> This package requires Swift 5.9.2, which ships with Xcode 15.1. It is possible to add this package in Xcode 15.0 and 15.0.1 but the produced implement will not be honoured. See https://github.com/apple/swift/issues/66348
>
> Hopefully this can be fixed in the future by updating the swift-tools-version or adding `swiftVersion` to the package, but currently this prevents is building in the Xcode 15.1 beta.

`CustomHashable` is a Swift macro for adding `Hashable` conformance. It is particularly useful when synthesised conformance is not possible, such as with classes or a struct with 1 or more non-hashable properties.

The `CustomHashable` macro is applied to the type that will conform to `Hashable` and the `HashableKey` macro is applied to each of the properties that should contribute to the `Hashable` conformance.

```swift
/// A struct that uses the ``stringProperty`` and ``intProperty`` for the `Hashable` conformance.
@CustomHashable
struct MyStruct {
    // Any property that is hashable is supported.
    @HashableKey
    let stringProperty: String

    // Works on private properties, too.
    @HashableKey
    private let intProperty: Int

    // Non-decorated properties are ignored
    let notHashableType: NotHashableType
}
```

All decorated properties are included in both the `==` and `hash(into:)` implementations, ensuring the [contract of `Hashable`](<https://developer.apple.com/documentation/swift/hashable#:~:text=Two%20instances%20that%20are%20equal%20must%20feed%20the%20same%20values%20to%20Hasher%20in%20hash(into%3A)%2C%20in%20the%20same%20order.>) is upheld:

> Two instances that are equal must feed the same values to Hasher in hash(into:), in the same order.

## License

[MIT](./LICENSE)
