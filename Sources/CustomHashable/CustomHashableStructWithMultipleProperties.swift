@CustomHashable
public struct CustomHashableStructWithExcludedProperty {
    @HashableKey
    let firstProperty: Int

    @HashableKey
    private let secondProperty: Int

    let excludedProperty: Int

    public init(firstProperty: Int, secondProperty: Int, excludedProperty: Int) {
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

    public init(firstProperty: Int, secondProperty: Int, privateProperty: Int) {
        self.firstProperty = firstProperty
        self.secondProperty = secondProperty
        self.privateProperty = privateProperty
    }
}