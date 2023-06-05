import XCTest
import CustomHashable

final class CustomHashableTests: XCTestCase {
    func testCustomHashableStructWithExcludedProperty() {
        let value1 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = CustomHashableStructWithExcludedProperty(firstProperty: 2, secondProperty: 2, excludedProperty: 3)
        let value3 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 4)

        XCTAssertEqual(value1, value1)

        XCTAssertEqual(value2, value2)

        XCTAssertEqual(value3, value3)

        XCTAssertEqual(value1, value3, "Third property should not be included in equality check; synthesised conformance should not be used")
        XCTAssertEqual(value1.hashValue, value3.hashValue, "Third property should not be included in hash value; synthesised conformance should not be used")

        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value2.hashValue, value3.hashValue)

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
