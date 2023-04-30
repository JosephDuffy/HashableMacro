import XCTest
import CustomHashable

struct NotHashableType {}

@CustomHashable
struct CustomHashableStructWithMultipleProperties: Hashable {
    @HashableKey
    let firstProperty: Int

    @HashableKey
    let secondProperty: Int

    @HashableKey
    private let thirdProperty: Int

    init(firstProperty: Int, secondProperty: Int, thirdProperty: Int) {
        self.firstProperty = firstProperty
            self.secondProperty = secondProperty
self.thirdProperty = thirdProperty
    }
}

@CustomHashable
struct CustomHashableStructWithExcludedProperty: Hashable {
    @HashableKey
    let firstProperty: Int

    @HashableKey
    let secondProperty: Int

    let excludedProperty: Int

    init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
        self.firstProperty = firstProperty
            self.secondProperty = secondProperty
self.excludedProperty = excludedProperty
    }
}

final class CustomHashableTests: XCTestCase {
    func testCustomHashableStructMultipleProperties() {
        let value1 = CustomHashableStructWithMultipleProperties(firstProperty: 1, secondProperty: 2, thirdProperty: 3)
        let value2 = CustomHashableStructWithMultipleProperties(firstProperty: 2, secondProperty: 2, thirdProperty: 3)
        let value3 = CustomHashableStructWithMultipleProperties(firstProperty: 1, secondProperty: 2, thirdProperty: 4)

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value3, value3)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value1, value2)
    }

    func testCustomHashableStructWithExcludedProperty() {
        let value1 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 3)
        let value2 = CustomHashableStructWithExcludedProperty(firstProperty: 2, secondProperty: 2, excludedProperty: 3)
        let value3 = CustomHashableStructWithExcludedProperty(firstProperty: 1, secondProperty: 2, excludedProperty: 4)

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value3, value3)
        XCTAssertEqual(value1, value3, "Third property should not be included in equality check; synthesised conformance should not be used")
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value1, value2)
    }
}