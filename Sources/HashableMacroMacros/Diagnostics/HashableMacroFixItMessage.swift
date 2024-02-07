import SwiftDiagnostics

struct HashableMacroFixItMessage: FixItMessage {
    let fixItID: MessageID
    let message: String

    init(id: String, message: String) {
        fixItID = MessageID.makeHashableMacroMessageID(id: id)
        self.message = message
    }
}

