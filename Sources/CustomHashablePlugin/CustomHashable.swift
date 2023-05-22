import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct CustomHashable: ConformanceMacro, MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        let inheritanceClause: TypeInheritanceClauseSyntax?

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            inheritanceClause = structDecl.inheritanceClause
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            inheritanceClause = classDecl.inheritanceClause
        } else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: ErrorDiagnosticMessage(
                        id: "unsupported-type",
                        message: "'CustomHashable' macro can only be applied to structs and classes"
                    )
                )
            )

            return []
        }

        if
            let inheritedTypes = inheritanceClause?.inheritedTypeCollection,
            inheritedTypes.contains(where: { inherited in inherited.typeName.trimmedDescription == "Hashable" })
        {
            // Hashable conformance has been added explicitly.
            return [("CustomEqualityProviding", nil)]
        }

        return [("CustomEqualityProviding", nil), ("Hashable", nil)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifiedDeclaration = declaration as? IdentifiedDeclSyntax else {
            throw InvalidDeclarationTypeError()
        }

        let scope = ({
            for modifier in declaration.modifiers ?? [] {
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

            let hasHashableKeyMacro = member.decl.as(VariableDeclSyntax.self)?.attributes?.contains(where: { element in
                element.as(AttributeSyntax.self)?.attributeName.as(SimpleTypeIdentifierSyntax.self)?.description == "HashableKey"
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
        \(scope)static func customEquals(lhs: \(identifiedDeclaration.identifier.text), rhs: \(identifiedDeclaration.identifier.text)) -> Bool {
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
