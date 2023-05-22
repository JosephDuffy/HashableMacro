/// A protocol that the `CustomHashable` macro adds a conformance for. This is used
/// to work around a bug with the compiler that prevents it from accounting for an `==`
/// function added by the macro when checking `Equatable` conformance.
///
/// The macro still adds conformance to `Equatable` but the `==` function is added via
/// an extension here.
public protocol CustomEqualityProviding {
    static func customEquals(lhs: Self, rhs: Self) -> Bool
}

public extension Equatable where Self: CustomEqualityProviding {
    static func == (lhs: Self, rhs: Self) -> Bool {
        customEquals(lhs: lhs, rhs: rhs)
    }
}
