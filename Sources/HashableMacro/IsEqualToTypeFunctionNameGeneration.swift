#if canImport(HashableMacroFoundation)
#if canImport(ObjectiveC)
import HashableMacroFoundation

public typealias IsEqualToTypeFunctionNameGeneration = HashableMacroFoundation.IsEqualToTypeFunctionNameGeneration
#else
#warning("ObjectiveC should be importable when HashableMacroFoundation can be imported")
#endif
