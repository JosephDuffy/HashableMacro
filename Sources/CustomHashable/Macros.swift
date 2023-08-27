@attached(member, names: named(hash), named(==))
@attached(extension, conformances: Hashable)
public macro CustomHashable() = #externalMacro(module: "CustomHashablePlugin", type: "CustomHashable")

@attached(peer)
public macro HashableKey() = #externalMacro(module: "CustomHashablePlugin", type: "HashableKey")
