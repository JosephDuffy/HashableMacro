// This file contains some types that use the @Hashable macro directly because the
// SwiftSyntaxMacrosTestSupport does not provide a way to check for which protocol conformances have
// been added, and the Swift compiler had a bug relating to this:
// https://github.com/apple/swift/issues/66348
import HashableMacro
import Foundation

#if compiler(>=5.9.2)
@Hashable
struct HashableStructWithExplicitlyIncludedProperties {
    @Hashed
    let firstProperty: Int

    @Hashed
    private let secondProperty: Int

    // Should be implicitly ignored.
    var computedProperty: Int {
        // Return a random value so that tests will fail if this is used in Hashable conformance
        .random(in: 0 ..< .max)
    }

    let excludedProperty: Int

    init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.excludedProperty = excludedProperty
    }
}

@Hashable
struct HashableStructWithExplicitlyExcludedProperty {
    let firstProperty: Int

    private let secondProperty: Int

    // Should be implicitly ignored.
    var computedProperty: Int {
        // Return a random value so that tests will fail if this is used in Hashable conformance
        .random(in: 0 ..< .max)
    }

    @NotHashed
    let excludedProperty: Int

    init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.excludedProperty = excludedProperty
    }
}

@Hashable
struct HashableStructWithNoDecorations {
    let firstProperty: Int

    private let secondProperty: Int

    // Should be implicitly ignored.
    var computedProperty: Int {
        // Return a random value so that tests will fail if this is used in Hashable conformance
        .random(in: 0 ..< .max)
    }

    init(firstProperty: Int, secondProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
    }
}

@Hashable
struct HashableStructWithExplictlyHashedComputedProperty {
    let firstProperty: Int

    private let secondProperty: Int

    @Hashed
    var firstAndSecondProperty: String {
        "\(firstProperty)-\(secondProperty)"
    }

    // Should be implicitly ignored.
    var computedProperty: Int {
        // Return a random value so that tests will fail if this is used in Hashable conformance
        .random(in: 0 ..< .max)
    }

    let excludedProperty: Int

    init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.excludedProperty = excludedProperty
    }
}

@Hashable
public class HashableClassWithPrivateProperty: Hashable {
    @Hashed
    let firstProperty: Int

    @Hashed
    let secondProperty: Int

    @Hashed
    private let privateProperty: Int

    init(firstProperty: Int, secondProperty: Int, privateProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.privateProperty = privateProperty
    }
}

/// A type that explicitly conforms to `Hashable`; the macro should not try to
/// add conformance (but it should still add the implementation required).
@Hashable
public class TypeExplicitlyConformingToHashable: Hashable {}

/// A type that includes multiple properties declared on the same line.
///
/// The macro supports this but using `assertMacroExpansion` raises an error:
///
/// _swift-syntax applies macros syntactically and there is no way to represent a variable declaration with multiple bindings that have accessors syntactically. While the compiler allows this expansion, swift-syntax cannot represent it and thus disallows it._
@Hashable
struct TypeWithMultipleVariablesOnSameLine {
    @Hashed
    var hashablePropery1: String

    @Hashed
    var hashablePropery2: String

    @Hashed
    let hashablePropery3, hashablePropery4: String

    var notHashablePropery: String
}

@Hashable
fileprivate struct FilePrivateType {
    @Hashed
    var hashablePropery1: String
}

@Hashable
private struct PrivateType {
    @Hashed
    var hashedProperty: String
}

@Hashable
public final class PublicFinalType {
    @Hashed
    var hashedProperty: String = ""
}

@Hashable
struct ExplicitEquatableStruct: Equatable {
    @Hashed
    var hashedProperty: String = ""
}

@Hashable
struct CustomEqualityStruct {
    @Hashed
    var hashedProperty: String = ""
}

#if canImport(ObjectiveC)
import ObjectiveC

@Hashable
class NSObjectSubclassWithoutExtraProperties: NSObject {}

@Hashable
class NSObjectSubclass: NSObject {
    @Hashed
    var nsObjectSubclassProperty: String
    
    init(nsObjectSubclassProperty: String) {
        self.nsObjectSubclassProperty = nsObjectSubclassProperty
    }
}

@Hashable
class NSObjectSubclassSubclass: NSObjectSubclass {
    @Hashed
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
