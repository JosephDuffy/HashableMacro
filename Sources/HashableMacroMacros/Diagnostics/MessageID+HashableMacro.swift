import SwiftDiagnostics

extension MessageID {
    static func makeHashableMacroMessageID(id: String) -> MessageID {
        MessageID(domain: "uk.josephduffy.HashableMacro", id: id)
    }
}
