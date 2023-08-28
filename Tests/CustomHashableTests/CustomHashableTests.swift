import CustomHashablePlugin
import XCTest
import CustomHashable
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

private let testMacros: [String: Macro.Type] = [
    "CustomHashable": CustomHashable.self,
    "HashableKey": HashableKey.self,
]

final class CustomHashableTests: XCTestCase {
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

        var hasher = Hasher()
        var hasher2 = hasher
        value1.hash(into: &hasher)
        1.hash(into: &hasher2)
        2.hash(into: &hasher2)
        3.hash(into: &hasher2)

        XCTAssertEqual(hasher.finalize(), hasher2.finalize())

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value3, value3)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value1, value2)
    }

    func testTypeNotExplicitlyConformingToHashable() {
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
            }
            """,
            expandedSource: """

            struct TypeNotExplicitlyConformingToHashable {
                var hashablePropery1: String
                var hashablePropery2: String
                let hashablePropery3: String

                var notHashablePropery: String

                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashablePropery1)
                    hasher.combine(self.hashablePropery2)
                    hasher.combine(self.hashablePropery3)
                }
            
                static func == (lhs: TypeNotExplicitlyConformingToHashable, rhs: TypeNotExplicitlyConformingToHashable) -> Bool {
                    return lhs.hashablePropery1 == rhs.hashablePropery1
                        && lhs.hashablePropery2 == rhs.hashablePropery2
                        && lhs.hashablePropery3 == rhs.hashablePropery3
                }
            }
            """,
            macros: testMacros
        )
    }
}

@CustomHashable
private struct CustomHashableStructWithExcludedProperty {
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
