import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct CustomHashable: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let hashableType = protocols.first else {
            // Hashable conformance has been explicitly added.
            return []
        }

        assert("\(hashableType.trimmed)" == "Hashable", "Only expected to add Hashable conformance")
        assert(protocols.count == 1, "Only expected to add conformance to a single protocol")

        return [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: InheritedTypeListSyntax(itemsBuilder: {
                        InheritedTypeSyntax(
                            type: hashableType
                        )
                    })
                ),
                memberBlockBuilder: {}
            )
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let namedDeclaration = declaration as? NamedDeclSyntax else {
            throw InvalidDeclarationTypeError()
        }

        let scope = ({
            for modifier in declaration.modifiers {
                switch (modifier.name.tokenKind) {
                case .keyword(.public):
                    return "public "
                case .keyword(.internal):
                    return "internal "
                case .keyword(.fileprivate):
                    return "fileprivate "
                case .keyword(.private):
                    // The added functions should never be private
                    return ""
                default:
                    break
                }
            }

            return ""
        })()

        let memberList = declaration.memberBlock.members

        let propertyNames = memberList.compactMap({ member -> String? in
            // is a property
            guard
                let propertyName = member.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                return nil
            }

            let hasHashableKeyMacro = member.decl.as(VariableDeclSyntax.self)?.attributes.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "HashableKey"
            }) == true

            if hasHashableKeyMacro {
                return propertyName
            } else {
                return nil
            }
        })

        var hashIntoImplementation: String =  """
            \(scope)func hash(into hasher: inout Hasher) {
        """

        var equalityImplementation: String =  """
            \(scope)static func ==(lhs: \(namedDeclaration.name.text), rhs: \(namedDeclaration.name.text)) -> Bool {
        """

        for (index, propertyName) in propertyNames.enumerated() {
            hashIntoImplementation += "\n"
            hashIntoImplementation += "hasher.combine(\(propertyName))"

            equalityImplementation += "\n"
            if index == 0 {
                equalityImplementation += "lhs.\(propertyName) == rhs.\(propertyName)"
            } else {
                equalityImplementation += "    && lhs.\(propertyName) == rhs.\(propertyName)"
            }
        }

        if propertyNames.isEmpty {
            equalityImplementation += "\n"
            equalityImplementation += "true"
        }

        hashIntoImplementation += "\n"
        hashIntoImplementation += "}"
        equalityImplementation += "\n"
        equalityImplementation += "}"

        return [
            "\(raw: hashIntoImplementation)",
            "\(raw: equalityImplementation)",
        ]
    }
}

private struct InvalidDeclarationTypeError: Error {}

private struct ErrorDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(id: String, message: String) {
        self.message = message
        diagnosticID = MessageID(domain: "uk.josephduffy.CustomHashable", id: id)
        severity = .error
    }
}
