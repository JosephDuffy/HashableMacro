#if compiler(>=5.9.2)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

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

    // `assertMacroExpansion` used to be used here but the expansion is added in
    // an extension because that's necessary to detect `NSObject` subclasses.
    // The test library does not pass any protocols to the macro function, which
    // is interpreted as the macro being attached to an `NSObject` subclass.
}
#endif
