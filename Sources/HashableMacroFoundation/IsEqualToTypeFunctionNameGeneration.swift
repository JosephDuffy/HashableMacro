#if canImport(ObjectiveC)
/// How to generate the name of the Objective-C function used to compare 2
/// instances of the same type.
public enum IsEqualToTypeFunctionNameGeneration: Sendable {
    /// Use an automatically generated name for the Objective-C function, e.g.
    /// for a class named `Person` this would use `isEqualToPerson:`.
    case automatic

    /// Use the provided name for the Objective-C function.
    ///
    /// - parameter objectiveCName: The name of the function when used from
    ///   Objective-C. This should include a trailing colon.
    case custom(_ objectiveCName: String)
}
#endif
