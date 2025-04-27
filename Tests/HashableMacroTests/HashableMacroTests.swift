import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HashableMacroMacros)
@testable import HashableMacroMacros

private let testMacros: [String: Macro.Type] = Dictionary(
    uniqueKeysWithValues: HashableMacroPlugin()
        .providingMacros
        .map { macroType in
            (
                String(String(describing: macroType).dropLast("Macro".count)),
                macroType
            )
        }
    )
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
        let value1 = NSObjectSubclass(
            nsObjectSubclassProperty: "123"
        )
        let value2 = NSObjectSubclass(
            nsObjectSubclassProperty: "123-different"
        )
        let value3 = NSObjectSubclass(
            nsObjectSubclassProperty: "123"
        )

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value1.hashValue, value1.hashValue)
        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
        XCTAssertEqual(value1, value3)
        XCTAssertEqual(value1.hashValue, value3.hashValue)

        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value2.hashValue, value2.hashValue)
        XCTAssertNotEqual(value2, value1)
        XCTAssertNotEqual(value2.hashValue, value1.hashValue)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

        XCTAssertEqual(value3, value3)
        XCTAssertEqual(value3.hashValue, value3.hashValue)
        XCTAssertNotEqual(value3, value2)
        XCTAssertNotEqual(value3.hashValue, value2.hashValue)
        XCTAssertEqual(value3, value1)
        XCTAssertEqual(value3.hashValue, value1.hashValue)

        #else
        throw XCTSkip("NSObject detection is only possible when ObjectiveC is available")
        #endif
    }

    func testEmbeddedType() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            enum Outer {
                @Hashable(_disableNSObjectSubclassSupport: true)
                struct InnerStruct {
                    let hashedProperty: String
                }

                @Hashable(fullyQualifiedName: "Outer.InnerClass", _disableNSObjectSubclassSupport: true)
                class InnerClass {
                    @Hashed
                    let hashedProperty: String

                    init(hashedProperty: String) {
                        self.hashedProperty = hashedProperty
                    }
                }
            }
            """
        } expansion: {
            // This should be e.g. `extension Outer.InnerStruct` but the tester does not output this.
            """
            enum Outer {
                struct InnerStruct {
                    let hashedProperty: String
                }
                class InnerClass {
                    let hashedProperty: String

                    init(hashedProperty: String) {
                        self.hashedProperty = hashedProperty
                    }
                }
            }

            extension Outer.InnerStruct {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension Outer.InnerStruct {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }

            extension Outer.InnerClass {
                final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension Outer.InnerClass {
                static func ==(lhs: Outer.InnerClass, rhs: Outer.InnerClass) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicStruct() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            public struct PublicStruct {
                @Hashed
                var hashableProperty: String
            }
            """
        } expansion: {
            """
            public struct PublicStruct {
                var hashableProperty: String
            }

            extension PublicStruct {
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension PublicStruct {
                public static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testSkipStaticPropertiesOnStructs() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct StructWithStaticProperties {
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String
            }
            """
        } expansion: {
            """
            struct StructWithStaticProperties {
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String
            }

            extension StructWithStaticProperties {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension StructWithStaticProperties {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAddingHashedMacroToStaticAndClassVariables() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                @Hashed
                static var staticVar: String = "hello"
                @Hashed
                static let staticLet: String = "world"
                @Hashed
                class var classVar: String = "hello"
                @Hashed
                class let classLet: String = "world"
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                @Hashed
                ┬──────
                ╰─ ⚠️ The @Hashed macro is only supported on instance properties.
                   ✏️ Remove @Hashed
                static var staticVar: String = "hello"
                @Hashed
                ┬──────
                ╰─ ⚠️ The @Hashed macro is only supported on instance properties.
                   ✏️ Remove @Hashed
                static let staticLet: String = "world"
                @Hashed
                ┬──────
                ╰─ ⚠️ The @Hashed macro is only supported on instance properties.
                   ✏️ Remove @Hashed
                class var classVar: String = "hello"
                @Hashed
                ┬──────
                ╰─ ⚠️ The @Hashed macro is only supported on instance properties.
                   ✏️ Remove @Hashed
                class let classLet: String = "world"
            }
            """
        } fixes: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String = "world"
                class var classVar: String = "hello"
                class let classLet: String = "world"
            }
            """
        } expansion: {
            """
            class ClassWithStaticAndClassProperties {
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String = "world"
                class var classVar: String = "hello"
                class let classLet: String = "world"
            }

            extension ClassWithStaticAndClassProperties {
                final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension ClassWithStaticAndClassProperties {
                static func ==(lhs: ClassWithStaticAndClassProperties, rhs: ClassWithStaticAndClassProperties) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAddingNotHashedMacroToStaticAndClassVariables() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                @NotHashed
                static var staticVar: String = "hello"
                @NotHashed
                static let staticLet: String = "world"
                @NotHashed
                class var classVar: String = "hello"
                @NotHashed
                class let classLet: String = "world"
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is only supported on instance properties.
                   ✏️ Remove @NotHashed
                static var staticVar: String = "hello"
                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is only supported on instance properties.
                   ✏️ Remove @NotHashed
                static let staticLet: String = "world"
                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is only supported on instance properties.
                   ✏️ Remove @NotHashed
                class var classVar: String = "hello"
                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is only supported on instance properties.
                   ✏️ Remove @NotHashed
                class let classLet: String = "world"
            }
            """
        } fixes: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            class ClassWithStaticAndClassProperties {
                @Hashed
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String = "world"
                class var classVar: String = "hello"
                class let classLet: String = "world"
            }
            """
        } expansion: {
            """
            class ClassWithStaticAndClassProperties {
                var hashableProperty: String
                static var staticVar: String = "hello"
                static let staticLet: String = "world"
                class var classVar: String = "hello"
                class let classLet: String = "world"
            }

            extension ClassWithStaticAndClassProperties {
                final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension ClassWithStaticAndClassProperties {
                static func ==(lhs: ClassWithStaticAndClassProperties, rhs: ClassWithStaticAndClassProperties) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAddingHashedToUnsupportedDeclarations() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashed
            class ClassWithStaticAndClassProperties {
                @Hashed
                func testFunction() {}
            }

            @Hashed
            typealias MyString = String
            """
        } diagnostics: {
            """
            @Hashed
            ┬──────
            ╰─ ⚠️ The @Hashed macro is only supported on properties.
               ✏️ Remove @Hashed
            class ClassWithStaticAndClassProperties {
                @Hashed
                ┬──────
                ╰─ ⚠️ The @Hashed macro is only supported on properties.
                   ✏️ Remove @Hashed
                func testFunction() {}
            }

            @Hashed
            ┬──────
            ╰─ ⚠️ The @Hashed macro is only supported on properties.
               ✏️ Remove @Hashed
            typealias MyString = String
            """
        } fixes: {
            """
            class ClassWithStaticAndClassProperties {
                func testFunction() {}
            }
            typealias MyString = String
            """
        } expansion: {
            """
            class ClassWithStaticAndClassProperties {
                func testFunction() {}
            }
            typealias MyString = String
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAddingNotHashedToUnsupportedDeclarations() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @NotHashed
            class ClassWithStaticAndClassProperties {
                @NotHashed
                func testFunction() {}
            }

            @NotHashed
            typealias MyString = String
            """
        } diagnostics: {
            """
            @NotHashed
            ┬─────────
            ╰─ ⚠️ The @NotHashed macro is only supported on properties.
               ✏️ Remove @NotHashed
            class ClassWithStaticAndClassProperties {
                @NotHashed
                ┬─────────
                ╰─ ⚠️ The @NotHashed macro is only supported on properties.
                   ✏️ Remove @NotHashed
                func testFunction() {}
            }

            @NotHashed
            ┬─────────
            ╰─ ⚠️ The @NotHashed macro is only supported on properties.
               ✏️ Remove @NotHashed
            typealias MyString = String
            """
        } fixes: {
            """
            class ClassWithStaticAndClassProperties {
                func testFunction() {}
            }
            typealias MyString = String
            """
        } expansion: {
            """
            class ClassWithStaticAndClassProperties {
                func testFunction() {}
            }
            typealias MyString = String
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPackageStruct() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            package struct PackageStruct {
                @Hashed
                var hashableProperty: String
            }
            """
        } expansion: {
            """
            package struct PackageStruct {
                var hashableProperty: String
            }

            extension PackageStruct {
                package func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension PackageStruct {
                package static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitInternalStruct() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            internal struct ExplicitInternalStruct {
                @Hashed
                var hashableProperty: String
            }
            """
        } expansion: {
            """
            internal struct ExplicitInternalStruct {
                var hashableProperty: String
            }

            extension ExplicitInternalStruct {
                internal func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension ExplicitInternalStruct {
                internal static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testFileprivateStruct() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            fileprivate struct FileprivateStruct {
                @Hashed
                var hashableProperty: String
            }
            """
        } expansion: {
            """
            fileprivate struct FileprivateStruct {
                var hashableProperty: String
            }

            extension FileprivateStruct {
                fileprivate func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension FileprivateStruct {
                fileprivate static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPrivateStruct() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            private struct PrivateStruct {
                @Hashed
                var hashableProperty: String
            }
            """
        } expansion: {
            """
            private struct PrivateStruct {
                var hashableProperty: String
            }

            extension PrivateStruct {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashableProperty)
                }
            }

            extension PrivateStruct {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashableProperty == rhs.hashableProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.notHashedProperty == rhs.notHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testTypeWithExplicitHashableConformance() throws {
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
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
                public static func ==(lhs: Self, rhs: Self) -> Bool {
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
                internal static func ==(lhs: Self, rhs: Self) -> Bool {
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
                fileprivate static func ==(lhs: Self, rhs: Self) -> Bool {
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testHashedAttachedToMultiplePropertyDeclaration() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TestStruct {
                @Hashed
                var hashedProperty, secondHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TestStruct {
                @Hashed
                ┬──────
                ╰─ 🛑 peer macro can only be applied to a single variable
                var hashedProperty, secondHashedProperty: String
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    // 日本語での説明:
    // Swift 6.1とswift-syntax 600.0.xでは、ピアマクロ（@Hashedなど）は単一の変数宣言にのみ適用できるという制限があります。
    // 以前のバージョンでは、一行に複数のプロパティを宣言する場合（例：`var hashedProperty, secondHashedProperty: String`）でも
    // マクロが適用できましたが、Swift 6.1ではこれが不可能になりました。
    // 
    // このテストケースは元々、複数プロパティ宣言に対してマクロが正常に展開されることを期待していましたが、
    // Swift 6.1の制限により、代わりに診断エラーを期待するように変更しました。
    // 
    // これはSwiftのマクロシステムの根本的な変更であり、私たちの実装で修正することはできません。
    // テストの振る舞いを変更せざるを得なかったのはこのためです。

    func testStructWithAllExcludedProperties() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TestStruct {
                @NotHashed
                var hashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            ┬───────────────────────────────────────────────
            ╰─ ⚠️ No hashable properties were found. All instances will be equal to each other.
               ✏️ Add 'allowEmptyImplementation: true' to silence this warning.
            struct TestStruct {
                @NotHashed
                var hashedProperty: String
            }
            """
        } fixes: {
            """
            @Hashable(allowEmptyImplementation: true, _disableNSObjectSubclassSupport: true)
            struct TestStruct {
                @NotHashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            struct TestStruct {
                var hashedProperty: String
            }

            extension TestStruct {
                func hash(into hasher: inout Hasher) {
                }
            }

            extension TestStruct {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return true
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithAllExcludedPropertiesDisallowedEmptyImplementation() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(allowEmptyImplementation: false, _disableNSObjectSubclassSupport: true)
            struct TestStruct {
                @NotHashed
                var hashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable(allowEmptyImplementation: false, _disableNSObjectSubclassSupport: true)
            ┬────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 No hashable properties were found and 'allowEmptyImplementation' is 'false'.
            struct TestStruct {
                @NotHashed
                var hashedProperty: String
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

    func testExplicitFinalHashInto() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true, finalHashInto: true)
            public class TestClass {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            public class TestClass {
                var hashedProperty: String
            }

            extension TestClass {
                public final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TestClass {
                public static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitNotFinalHashInto() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true, finalHashInto: false)
            public class TestClass {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            public class TestClass {
                var hashedProperty: String
            }

            extension TestClass {
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TestClass {
                public static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitNotFinalHashIntoOpenClass() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true, finalHashInto: false)
            open class TestClass {
                @Hashed
                var hashedProperty: String
            }
            """
        } expansion: {
            """
            open class TestClass {
                var hashedProperty: String
            }

            extension TestClass {
                open func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TestClass {
                public static func ==(lhs: TestClass, rhs: TestClass) -> Bool {
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testComputedPropertyWithExplicitGet() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithComputedPropertt {
                @Hashed
                var hashedProperty: String

                var computedProperty: String {
                    get {
                        "computed"
                    }
                }
            }
            """
        } expansion: {
            """
            struct TypeWithComputedPropertt {
                var hashedProperty: String

                var computedProperty: String {
                    get {
                        "computed"
                    }
                }
            }

            extension TypeWithComputedPropertt {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                }
            }

            extension TypeWithComputedPropertt {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testStoredPropertyWithDidSet() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct TypeWithComputedPropertt {
                var hashedProperty: String

                var otherHashedProperty: String {
                    didSet {
                        // ... do something
                    }
                }
            }
            """
        } expansion: {
            """
            struct TypeWithComputedPropertt {
                var hashedProperty: String

                var otherHashedProperty: String {
                    didSet {
                        // ... do something
                    }
                }
            }

            extension TypeWithComputedPropertt {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.otherHashedProperty)
                }
            }

            extension TypeWithComputedPropertt {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                        && lhs.otherHashedProperty == rhs.otherHashedProperty
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
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashedProperty == rhs.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnum() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            enum TestEnum {
                case testCase
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            ┬───────────────────────────────────────────────
            ╰─ 🛑 '@Hashable' is not currently supported on enums.
            enum TestEnum {
                case testCase
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testClassWithoutHashedProperties() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable
            class TestClass {
                var notHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable
            ┬────────
            ╰─ 🛑 No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for classes.
            class TestClass {
                var notHashedProperty: String
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testActorWithoutHashedProperties() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable
            actor TestActor {
                var notHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable
            ┬────────
            ╰─ 🛑 No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for actors.
            actor TestActor {
                var notHashedProperty: String
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Edge cases

    func testPropertyAfterIfConfig() throws {
        // The `#if os(macOS)` will be parsed an attribute of the
        // `notHashedProperty` property.
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true)
            struct Test {
                @Hashed
                var hashablePropery: String

                #if os(macOS)
                @NotHashed
                #endif
                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            struct Test {
                var hashablePropery: String
                var notHashedProperty: String
            }

            extension Test {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery)
                }
            }

            extension Test {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    return lhs.hashablePropery == rhs.hashablePropery
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Impossible Scenarios
    // These should be impossible, e.g. the compiler will not call the macro for these.

    func testInvalidFinalHashIntoValue() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true, finalHashInto: 0)
            class Test {
                @Hashed
                var hashablePropery: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            class Test {
                var hashablePropery: String

                var notHashedProperty: String
            }

            extension Test {
                final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery)
                }
            }

            extension Test {
                static func ==(lhs: Test, rhs: Test) -> Bool {
                    return lhs.hashablePropery == rhs.hashablePropery
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testUnlabelledParameter() throws {
        #if canImport(HashableMacroMacros)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: true, "unlabelled")
            class Test {
                @Hashed
                var hashablePropery: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            class Test {
                var hashablePropery: String

                var notHashedProperty: String
            }

            extension Test {
                final func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery)
                }
            }

            extension Test {
                static func ==(lhs: Test, rhs: Test) -> Bool {
                    return lhs.hashablePropery == rhs.hashablePropery
                }
            }
            """
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testIsEqualToTypeFunctionNameInvalidType() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(isEqualToTypeFunctionName: 123, _disableNSObjectSubclassSupport: false)
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        } diagnostics: {
            """
            @Hashable(isEqualToTypeFunctionName: 123, _disableNSObjectSubclassSupport: false)
            ┬────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 'isEqualToTypeFunctionName' parameter was not of the expected type
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testIsEqualToTypeFunctionNameInvalidName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(isEqualToTypeFunctionName: .invalidName, _disableNSObjectSubclassSupport: false)
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        } diagnostics: {
            """
            @Hashable(isEqualToTypeFunctionName: .invalidName, _disableNSObjectSubclassSupport: false)
            ┬─────────────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 'invalidName' is not a known value for `IsEqualToTypeFunctionNameGeneration`.
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        }

        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testIsEqualToTypeFunctionNameInvalidCustomNameType() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(isEqualToTypeFunctionName: .custom(123), _disableNSObjectSubclassSupport: false)
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        } diagnostics: {
            """
            @Hashable(isEqualToTypeFunctionName: .custom(123), _disableNSObjectSubclassSupport: false)
            ┬─────────────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 Only option for 'custom' must be a string.
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testIsEqualToTypeFunctionNameInvalidCustomNameParameterCount() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(isEqualToTypeFunctionName: .custom("name1", "name2"), _disableNSObjectSubclassSupport: false)
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        } diagnostics: {
            """
            @Hashable(isEqualToTypeFunctionName: .custom("name1", "name2"), _disableNSObjectSubclassSupport: false)
            ┬──────────────────────────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 Only 1 argument is supported for 'custom'.
            class Test: NSObject {
                @Hashed
                var hashablePropery: String
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Objective-C

    func testOpenNSObjectSubclass() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            open class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                open var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            open class TestClass: NSObject {
                var hashedProperty: String
                open var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                public override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                open override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)

                public final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicNSObjectSubclass() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            public class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                public var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            public class TestClass: NSObject {
                var hashedProperty: String
                public var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                public override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                public override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)

                public final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testExplicitlyInternalNSObjectSubclass() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            internal class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                internal var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            internal class TestClass: NSObject {
                var hashedProperty: String
                internal var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                internal override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                internal override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)

                internal final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPrivateNSObjectSubclass() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            private class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                private var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            private class TestClass: NSObject {
                var hashedProperty: String
                private var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)
                final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNSObjectSubclassWithoutHashedProperties() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable
            class TestClass: NSObject {
                @NotHashed
                var notHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable
            ┬────────
            ╰─ 🛑 No properties marked with '@Hashed' were found. Synthesising Hashable conformance is not supported for classes.
            class TestClass: NSObject {
                @NotHashed
                var notHashedProperty: String
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicNSObjectSubclassWithCustomObjCName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            @objc(TestClassObjC)
            public class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                public var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            @objc(TestClassObjC)
            public class TestClass: NSObject {
                var hashedProperty: String
                public var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                public override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                public override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)

                public final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNSObjectSubclass_implicitAutomaticCustomEqualToTypeFunctionName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false)
            class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            class TestClass: NSObject {
                var hashedProperty: String
                var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)
                final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNSObjectSubclass_explicitAutomaticCustomEqualToTypeFunctionName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false, isEqualToTypeFunctionName: .automatic)
            class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                @Hashed
                var secondHashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            class TestClass: NSObject {
                var hashedProperty: String
                var secondHashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    hasher.combine(self.secondHashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(isEqualToTestClass:)
                final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                        && self.secondHashedProperty == object.secondHashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNSObjectSubclass_validCustomEqualToTypeFunctionName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false, isEqualToTypeFunctionName: .custom("myCustomName:"))
            public class TestClass: NSObject {
                @Hashed
                public var hashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            public class TestClass: NSObject {
                public var hashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                public override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                public override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(myCustomName:)

                public final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNSObjectSubclass_invalidCustomEqualToTypeFunctionName() throws {
        #if canImport(HashableMacroMacros)
        #if canImport(ObjectiveC)
        assertMacro(testMacros) {
            """
            @Hashable(_disableNSObjectSubclassSupport: false, isEqualToTypeFunctionName: .custom("myCustomName"))
            class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                var notHashedProperty: String
            }
            """
        } diagnostics: {
            """
            @Hashable(_disableNSObjectSubclassSupport: false, isEqualToTypeFunctionName: .custom("myCustomName"))
            ┬────────────────────────────────────────────────────────────────────────────────────────────────────
            ╰─ 🛑 Custom Objective-C function name must end with a colon.
               ✏️ Add ':'
            class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                var notHashedProperty: String
            }
            """
        } fixes: {
            """
            @Hashable(_disableNSObjectSubclassSupport: false, isEqualToTypeFunctionName: .custom("myCustomName:"))
            class TestClass: NSObject {
                @Hashed
                var hashedProperty: String

                var notHashedProperty: String
            }
            """
        } expansion: {
            """
            class TestClass: NSObject {
                var hashedProperty: String

                var notHashedProperty: String
            }

            extension TestClass {
                override var hash: Int {
                    var hasher = Hasher()
                    hasher.combine(self.hashedProperty)
                    return hasher.finalize()
                }
            }

            extension TestClass {
                override func isEqual(_ object: Any?) -> Bool {
                    guard let object = object as? TestClass else {
                        return false
                    }
                    guard type(of: self) == type(of: object) else {
                        return false
                    }
                    return self.isEqual(to: object)
                }
                @objc(myCustomName:)
                final func isEqual(to object: TestClass) -> Bool {
                    return self.hashedProperty == object.hashedProperty
                }
            }
            """
        }
        #else
        throw XCTSkip("This expansion requires Objective-C")
        #endif
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
