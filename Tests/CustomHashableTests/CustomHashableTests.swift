import XCTest
import CustomHashable

final class CustomHashableTests: XCTestCase {
    func testCustomHashableStructMultipleProperties() {
        @CustomHashable
        struct CustomHashableType: Hashable {
            @HashableKey
            let firstProperty: Int

            @HashableKey
            let secondProperty: Int

            @HashableKey
            let thirdProperty: Int
        }

        let value1 = CustomHashableType(firstProperty: 1, secondProperty: 2, thirdProperty: 3)
        let value2 = CustomHashableType(firstProperty: 2, secondProperty: 2, thirdProperty: 3)
        let value3 = CustomHashableType(firstProperty: 3, secondProperty: 3, thirdProperty: 4)

        XCTAssertEqual(value1, value1)
        XCTAssertEqual(value2, value2)
        XCTAssertEqual(value3, value3)
        XCTAssertNotEqual(value1, value3)
        XCTAssertNotEqual(value2, value3)
        XCTAssertNotEqual(value1, value2)
    }
}
