import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if swift(>=5.9.2)
#if canImport(CustomHashableMacros)
import CustomHashableMacros

private let testMacros: [String: Macro.Type] = [
    "CustomHashable": CustomHashable.self,
    "HashableKey": HashableKey.self,
]
#endif

final class CustomHashableTests: XCTestCase {
    /// Test the usage of the `Hashable` API using a type decorated with the `@CustomHashable` macro
    /// that has been expanded by the compiler to check that the expanded implementation is honoured
    /// when compiled.
    ///
    /// See https://github.com/apple/swift/issues/66348
    func testCustomHashableStructWithExcludedProperty() {
        let value1 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 3, excludedProperty: 3)
        let value3 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 4)
        let value4 = CustomHashableStructWithExcludedProperty(firstProperty: 2, secondProperty: 3, excludedProperty: 3)

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

    func testCustomHashableClassWithPrivateProperty() {
        let value1 = CustomHashableClassWithPrivateProperty(firstProperty: 1, secondProperty: 2, privateProperty: 3)
        let value2 = CustomHashableClassWithPrivateProperty(firstProperty: 2, secondProperty: 2, privateProperty: 3)
        let value3 = CustomHashableClassWithPrivateProperty(firstProperty: 1, secondProperty: 2, privateProperty: 4)

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

    func testTypeNotExplicitlyConformingToHashable() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            struct TypeNotExplicitlyConformingToHashable {
                @HashableKey
                var hashablePropery1: String

                @HashableKey
                var hashablePropery2: String

                @HashableKey
                let hashablePropery3: String

                var notHashablePropery: String

                func extraFunction() {}
            }
            """,
            expandedSource: """

            struct TypeNotExplicitlyConformingToHashable {
                var hashablePropery1: String
                var hashablePropery2: String
                let hashablePropery3: String

                var notHashablePropery: String

                func extraFunction() {}

                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery1)
                    hasher.combine(self.hashablePropery2)
                    hasher.combine(self.hashablePropery3)
                }
            
                static func ==(lhs: TypeNotExplicitlyConformingToHashable, rhs: TypeNotExplicitlyConformingToHashable) -> Bool {
                    return lhs.hashablePropery1 == rhs.hashablePropery1
                        && lhs.hashablePropery2 == rhs.hashablePropery2
                        && lhs.hashablePropery3 == rhs.hashablePropery3
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testTypeWithoutAnyHashableKeys() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            struct TypeWithoutHashableKeys {
                var notHashedProperty: String
            }
            """,
            expandedSource: """

            struct TypeWithoutHashableKeys {
                var notHashedProperty: String

                func hash(into hasher: inout Hasher) {
                }

                static func ==(lhs: TypeWithoutHashableKeys, rhs: TypeWithoutHashableKeys) -> Bool {
                    return true
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testTypeWithExplicitHashableConformation() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            struct TypeWithExplicitHashableConformation: Hashable {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            struct TypeWithExplicitHashableConformation: Hashable {
                var hashedProperty: String

                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                static func ==(lhs: TypeWithExplicitHashableConformation, rhs: TypeWithExplicitHashableConformation) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicType() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            public struct PublicType {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            public struct PublicType {
                var hashedProperty: String

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                public static func ==(lhs: PublicType, rhs: PublicType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitlyInternalType() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            internal struct ExplicitlyInternalType {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            internal struct ExplicitlyInternalType {
                var hashedProperty: String

                internal func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                internal static func ==(lhs: ExplicitlyInternalType, rhs: ExplicitlyInternalType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testFilePrivateType() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            fileprivate struct FilePrivateType {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            fileprivate struct FilePrivateType {
                var hashedProperty: String

                fileprivate func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                fileprivate static func ==(lhs: FilePrivateType, rhs: FilePrivateType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPrivateType() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            private struct PrivateType {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            private struct PrivateType {
                var hashedProperty: String

                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                static func ==(lhs: PrivateType, rhs: PrivateType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicFinalType() throws {
        #if canImport(CustomHashableMacros)
        assertMacroExpansion(
            """
            @CustomHashable
            public final class PublicFinalType {
                @HashableKey
                var hashedProperty: String
            }
            """,
            expandedSource: """

            public final class PublicFinalType {
                var hashedProperty: String

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }

                public static func ==(lhs: PublicFinalType, rhs: PublicFinalType) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
#endif
