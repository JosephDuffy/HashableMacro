// This file contains some types that use the @CustomHashable macro directly because the
// SwiftSyntaxMacrosTestSupport does not provide a way to check for which protocol conformances have
// been added, and the Swift compiler had a bug relating to this:
// https://github.com/apple/swift/issues/66348
import CustomHashable

#if swift(>=5.9.2)
@CustomHashable
struct CustomHashableStructWithExcludedProperty {
    @HashableKey
    let firstProperty: Int

    @HashableKey
    private let secondProperty: Int

    let excludedProperty: Int

    init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.excludedProperty = excludedProperty
    }
}

@CustomHashable
public class CustomHashableClassWithPrivateProperty {
    @HashableKey
    let firstProperty: Int

    @HashableKey
    let secondProperty: Int

    @HashableKey
    private let privateProperty: Int

    init(firstProperty: Int, secondProperty: Int, privateProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.privateProperty = privateProperty
    }
}

/// A type that explicitly conforms to `Hashable`; the macro should not try to
/// add conformance (but it should still add the implementation required).
@CustomHashable
public class TypeExplicitlyConformingToHashable: Hashable {}

/// A type that includes multiple properties declared on the same line.
///
/// The macro supports this but using `assertMacroExpansion` raises an error:
///
/// _swift-syntax applies macros syntactically and there is no way to represent a variable declaration with multiple bindings that have accessors syntactically. While the compiler allows this expansion, swift-syntax cannot represent it and thus disallows it._
@CustomHashable
struct TypeWithMultipleVariablesOnSameLine {
    @HashableKey
    var hashablePropery1: String

    @HashableKey
    var hashablePropery2: String

    @HashableKey
    let hashablePropery3, hashablePropery4: String

    var notHashablePropery: String
}

@CustomHashable
fileprivate struct FilePrivateType {
    @HashableKey
    var hashablePropery1: String
}

@CustomHashable
private struct PrivateType {
    @HashableKey
    var hashedProperty: String
}

@CustomHashable
public final class PublicFinalType {
    @HashableKey
    var hashedProperty: String = ""
}

@CustomHashable
struct ExplicitEquatableStruct: Equatable {
    @HashableKey
    var hashedProperty: String = ""
}

@CustomHashable
struct CustomEqualityStruct {
    @HashableKey
    var hashedProperty: String = ""
}

#if canImport(ObjectiveC)
import ObjectiveC

@CustomHashable
class NSObjectSubclassWithoutExtraProperties: NSObject {}

@CustomHashable
class NSObjectSubclass: NSObject {
    @HashableKey
    var nsObjectSubclassProperty: String
    
    init(nsObjectSubclassProperty: String) {
        self.nsObjectSubclassProperty = nsObjectSubclassProperty
    }
}

@CustomHashable
class NSObjectSubclassSubclass: NSObjectSubclass {
    @HashableKey
    var nsObjectSubclassSubclassProperty: String

    init(
        nsObjectSubclassProperty: String,
        nsObjectSubclassSubclassProperty: String
    ) {
        self.nsObjectSubclassSubclassProperty = nsObjectSubclassSubclassProperty

        super.init(nsObjectSubclassProperty: nsObjectSubclassProperty)
    }
}
#endif
#endif
