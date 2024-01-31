#if compiler(>=5.9.2)
import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HashableMacroMacros)
import HashableMacroMacros

private let testMacros: [String: Macro.Type] = [
    "Hashable": HashableMacro.self,
    "Hashed": HashedMacro.self,
    "NotHashed": NotHashedMacro.self,
]
#endif

final class HashableMacroTests: XCTestCase {
    /// Test the usage of the `Hashable` API using a type decorated with the `@Hashable` macro
    /// that has been expanded by the compiler to check that the expanded implementation is honoured
    /// when compiled.
    ///
    /// See https://github.com/apple/swift/issues/66348
    func testHashableStructWithExplicitlyIncludedProperties() {
        let value1 = HashableStructWithExplicitlyIncludedProperties(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = HashableStructWithExplicitlyIncludedProperties(firstProperty: 1, secondProperty: 3, excludedProperty: 3)
        let value3 = HashableStructWithExplicitlyIncludedProperties(firstProperty: 1, secondProperty: 2, excludedProperty: 4)
        let value4 = HashableStructWithExplicitlyIncludedProperties(firstProperty: 2, secondProperty: 3, excludedProperty: 3)

        XCTAssertEqual(value1, value1)

        XCTAssertEqual(value2, value2)

        XCTAssertEqual(value3, value3)

        XCTAssertEqual(value4, value4)

        XCTAssertEqual(value1, value3, "Third property should not be included in equality check; synthesised conformance should not be used")
        XCTAssertEqual(value1.hashValue, value3.hashValue, "Third property should not be included in hash value; synthesised conformance should not be used")

        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)

        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
    }

    func testHashableStructWithExplicitlyExcludedProperty() {
        let value1 = HashableStructWithExplicitlyExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = HashableStructWithExplicitlyExcludedProperty(firstProperty: 1, secondProperty: 3, excludedProperty: 3)
        let value3 = HashableStructWithExplicitlyExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 4)
        let value4 = HashableStructWithExplicitlyExcludedProperty(firstProperty: 2, secondProperty: 3, excludedProperty: 3)

        XCTAssertEqual(value1, value1)

        XCTAssertEqual(value2, value2)

        XCTAssertEqual(value3, value3)

        XCTAssertEqual(value4, value4)

        XCTAssertEqual(value1, value3, "Third property should not be included in equality check; synthesised conformance should not be used")
        XCTAssertEqual(value1.hashValue, value3.hashValue, "Third property should not be included in hash value; synthesised conformance should not be used")

        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)

        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
    }

    func testHashableStructWithNoDecorations() {
        let value1 = HashableStructWithNoDecorations(firstProperty: 1, secondProperty: 2)
        let value2 = HashableStructWithNoDecorations(firstProperty: 1, secondProperty: 3)
        let value3 = HashableStructWithNoDecorations(firstProperty: 1, secondProperty: 2)
        let value4 = HashableStructWithNoDecorations(firstProperty: 2, secondProperty: 3)

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value1, value3)
        XCTAssertEqual(value1.hashValue, value3.hashValue)

        XCTAssertEqual(value2, value2)

        XCTAssertEqual(value3, value3)

        XCTAssertEqual(value4, value4)

        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)

        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
    }

    func testHashableStructWithExplictlyHashedComputedProperty() {
        let value1 = HashableStructWithExplictlyHashedComputedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = HashableStructWithExplictlyHashedComputedProperty(firstProperty: 1, secondProperty: 3, excludedProperty: 3)
        let value3 = HashableStructWithExplictlyHashedComputedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 4)
        let value4 = HashableStructWithExplictlyHashedComputedProperty(firstProperty: 2, secondProperty: 3, excludedProperty: 3)

        XCTAssertEqual(value1, value1)

        XCTAssertEqual(value2, value2)

        XCTAssertEqual(value3, value3)

        XCTAssertEqual(value4, value4)

        XCTAssertEqual(value1, value3, "Third property should not be included in equality check; synthesised conformance should not be used")
        XCTAssertEqual(value1.hashValue, value3.hashValue, "Third property should not be included in hash value; synthesised conformance should not be used")

        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)

        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
    }

    func testHashableClassWithPrivateProperty() {
        let value1 = HashableClassWithPrivateProperty(firstProperty: 1, secondProperty: 2, privateProperty: 3)
        let value2 = HashableClassWithPrivateProperty(firstProperty: 2, secondProperty: 2, privateProperty: 3)
        let value3 = HashableClassWithPrivateProperty(firstProperty: 1, secondProperty: 2, privateProperty: 4)

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value1.hashValue, value1.hashValue)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value2.hashValue, value2.hashValue)
        XCTAssertEqual(value3, value3)
        XCTAssertEqual(value3.hashValue, value3.hashValue)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value1.hashValue, value3.hashValue)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)
        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
    }

    func testNSObjectSubclassing() throws {
        #if canImport(ObjectiveC)
        let value1 = NSObjectSubclassSubclass(
            nsObjectSubclassProperty: "123",
            nsObjectSubclassSubclassProperty: "456"
        )
        let value2 = NSObjectSubclassSubclass(
            nsObjectSubclassProperty: "123-different",
            nsObjectSubclassSubclassProperty: "456"
        )
        let value3 = NSObjectSubclassSubclass(
            nsObjectSubclassProperty: "123",
            nsObjectSubclassSubclassProperty: "456-different"
        )
        let value4 = NSObjectSubclassSubclass(
            nsObjectSubclassProperty: "123-different",
            nsObjectSubclassSubclassProperty: "456-different"
        )
        let value5 = NSObjectSubclass(nsObjectSubclassProperty: "123")
        let value6 = NSObjectSubclassSubclass(
            nsObjectSubclassProperty: "123",
            nsObjectSubclassSubclassProperty: "456"
        )

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value1.hashValue, value1.hashValue)
        XCTAssertEqual(value1, value6)
        XCTAssertEqual(value1.hashValue, value6.hashValue)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value2.hashValue, value2.hashValue)
        XCTAssertEqual(value3, value3)
        XCTAssertEqual(value3.hashValue, value3.hashValue)
        XCTAssertEqual(value4, value4)
        XCTAssertEqual(value4.hashValue, value4.hashValue)
        XCTAssertEqual(value5, value5)
        XCTAssertEqual(value5.hashValue, value5.hashValue)
        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value1, value4)
        XCTAssertNotEqual(value1, value5)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
        XCTAssertNotEqual(value1.hashValue, value3.hashValue)
        XCTAssertNotEqual(value1.hashValue, value4.hashValue)
        XCTAssertNotEqual(value1.hashValue, value5.hashValue)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2, value5)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)
        XCTAssertNotEqual(value2.hashValue, value5.hashValue)
        XCTAssertNotEqual(value3, value4)
        XCTAssertNotEqual(value3, value5)
        XCTAssertNotEqual(value3.hashValue, value4.hashValue)
        XCTAssertNotEqual(value3.hashValue, value5.hashValue)
        XCTAssertNotEqual(value5, value1)
        XCTAssertNotEqual(value5, value2)
        XCTAssertNotEqual(value5, value3)
        XCTAssertNotEqual(value5, value4)
        #else
        throw XCTSkip("NSObject detection is only possible when ObjectiveC is available")
        #endif
    }

    func testTypeNotExplicitlyConformingToHashable() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeNotExplicitlyConformingToHashable {
                @Hashed
                var hashablePropery1: String

                @Hashed
                var hashablePropery2: String

                @Hashed
                let hashablePropery3: String

                var notHashablePropery: String

                func extraFunction() {}
            }
            """
        } expansion: {
            """
            struct TypeNotExplicitlyConformingToHashable {
                var hashablePropery1: String
                var hashablePropery2: String
                let hashablePropery3: String

                var notHashablePropery: String

                func extraFunction() {}
            }

            extension TypeNotExplicitlyConformingToHashable {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery1)
                    hasher.combine(self.hashablePropery2)
                    hasher.combine(self.hashablePropery3)
                }
            }

            extension TypeNotExplicitlyConformingToHashable {
                static func ==(lhs: TypeNotExplicitlyConformingToHashable, rhs: TypeNotExplicitlyConformingToHashable) -> Bool {
                    return lhs.hashablePropery1 == rhs.hashablePropery1
                        && lhs.hashablePropery2 == rhs.hashablePropery2
                        && lhs.hashablePropery3 == rhs.hashablePropery3
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithoutAnyHashedProperties() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithoutHashableKeys {
                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            struct TypeWithoutHashableKeys {
                var notHashedProperty: String
            }

            extension TypeWithoutHashableKeys {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.notHashedProperty)
                }
            }

            extension TypeWithoutHashableKeys {
                static func ==(lhs: TypeWithoutHashableKeys, rhs: TypeWithoutHashableKeys) -> Bool {
                    return lhs.notHashedProperty == rhs.notHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testTypeWithExplicitHashableConformation() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithExplicitHashableConformation: Hashable {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            struct TypeWithExplicitHashableConformation: Hashable {
                var hashedProperty: String
            }

            extension TypeWithExplicitHashableConformation {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TypeWithExplicitHashableConformation {
                static func ==(lhs: TypeWithExplicitHashableConformation, rhs: TypeWithExplicitHashableConformation) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            public struct PublicType {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            public struct PublicType {
                var hashedProperty: String
            }

            extension PublicType {
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension PublicType {
                public static func ==(lhs: PublicType, rhs: PublicType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitlyInternalType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            internal struct ExplicitlyInternalType {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            internal struct ExplicitlyInternalType {
                var hashedProperty: String
            }

            extension ExplicitlyInternalType {
                internal func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension ExplicitlyInternalType {
                internal static func ==(lhs: ExplicitlyInternalType, rhs: ExplicitlyInternalType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testFilePrivateType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            fileprivate struct FilePrivateType {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            fileprivate struct FilePrivateType {
                var hashedProperty: String
            }

            extension FilePrivateType {
                fileprivate func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension FilePrivateType {
                fileprivate static func ==(lhs: FilePrivateType, rhs: FilePrivateType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPrivateType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            private struct PrivateType {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            private struct PrivateType {
                var hashedProperty: String
            }

            extension PrivateType {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension PrivateType {
                static func ==(lhs: PrivateType, rhs: PrivateType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicFinalType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            public final class PublicFinalType {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            public final class PublicFinalType {
                var hashedProperty: String
            }

            extension PublicFinalType {
                public final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension PublicFinalType {
                public static func ==(lhs: PublicFinalType, rhs: PublicFinalType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testComputedProperty() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithComputedPropertt {
                @Hashed
                var hashedProperty: String

                var computedProperty: String { "computed" }
            }
            """
        } expansion: {
            """
            struct TypeWithComputedPropertt {
                var hashedProperty: String

                var computedProperty: String { "computed" }
            }

            extension TypeWithComputedPropertt {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TypeWithComputedPropertt {
                static func ==(lhs: TypeWithComputedPropertt, rhs: TypeWithComputedPropertt) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testMixedHashedNotHashedDiagnostic() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithMixedHashedNotHashed {
                @Hashed
                var hashedProperty: String

                @NotHashed
                var notHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithMixedHashedNotHashed {
                @Hashed
                var hashedProperty: String

                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is redundant when 1 or more properties are decorated @Hashed. It will be ignored
                   ✏️ Remove @NotHashed
                var notHashedProperty: String
            }
            """
        } fixes: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithMixedHashedNotHashed {
                @Hashed
                var hashedProperty: String
                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            struct TypeWithMixedHashedNotHashed {
                var hashedProperty: String
                var notHashedProperty: String
            }

            extension TypeWithMixedHashedNotHashed {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TypeWithMixedHashedNotHashed {
                static func ==(lhs: TypeWithMixedHashedNotHashed, rhs: TypeWithMixedHashedNotHashed) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
#endif
