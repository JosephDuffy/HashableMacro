@available(swift 5.9.2)
@attached(member, conformances: Hashable, Equatable, names: named(hash), named(==))
@attached(extension, conformances: Hashable, Equatable, names: named(hash), named(==))
public macro CustomHashable() = #externalMacro(module: "CustomHashableMacros", type: "CustomHashable")

@attached(peer)
public macro HashableKey() = #externalMacro(module: "CustomHashableMacros", type: "HashableKey")
