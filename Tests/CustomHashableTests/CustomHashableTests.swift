#if compiler(>=5.9.2)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

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

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value1.hashValue, value1.hashValue)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value2.hashValue, value2.hashValue)
        XCTAssertEqual(value3, value3)
        XCTAssertEqual(value3.hashValue, value3.hashValue)
        XCTAssertEqual(value4, value4)
        XCTAssertEqual(value4.hashValue, value4.hashValue)
        XCTAssertNotEqual(value1, value2)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value1, value4)
        XCTAssertNotEqual(value1.hashValue, value2.hashValue)
        XCTAssertNotEqual(value1.hashValue, value3.hashValue)
        XCTAssertNotEqual(value1.hashValue, value4.hashValue)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2, value4)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)
        XCTAssertNotEqual(value2.hashValue, value4.hashValue)
        XCTAssertNotEqual(value3, value4)
        XCTAssertNotEqual(value3.hashValue, value4.hashValue)
        #else
        throw XCTSkip("NSObject detection is only possible when ObjectiveC is available")
        #endif
    }

    // `assertMacroExpansion` used to be used here but the expansion is added in
    // an extension because that's necessary to detect `NSObject` subclasses.
    // The test library does not pass any protocols to the macro function, which
    // is interpreted as the macro being attached to an `NSObject` subclass.
}
#endif
