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
            return []
        }

        // TODO: Fix compilation when adding conformance to a struct; adding `Hashable` conformance in a extension is not supported.
        return [("Hashable", nil)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifiedDeclaration = declaration as? IdentifiedDeclSyntax else {
            throw InvalidDeclarationTypeError()
        }

        let inheritanceClause: TypeInheritanceClauseSyntax?

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            inheritanceClause = structDecl.inheritanceClause
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            inheritanceClause = classDecl.inheritanceClause
        } else {
            inheritanceClause = nil
        }

        var hasSuperclass = false

        if let inheritanceClause {
            for (index, inheritedType) in inheritanceClause.inheritedTypeCollection.enumerated() {
                print("ArrayTypeSyntax", inheritedType.typeName.is(ArrayTypeSyntax.self))
                print("AttributedTypeSyntax", inheritedType.typeName.is(AttributedTypeSyntax.self))
                print("ClassRestrictionTypeSyntax", inheritedType.typeName.is(ClassRestrictionTypeSyntax.self))
                print("CompositionTypeSyntax", inheritedType.typeName.is(CompositionTypeSyntax.self))
                print("ConstrainedSugarTypeSyntax", inheritedType.typeName.is(ConstrainedSugarTypeSyntax.self))
                print("DictionaryTypeSyntax", inheritedType.typeName.is(DictionaryTypeSyntax.self))
                print("FunctionTypeSyntax", inheritedType.typeName.is(FunctionTypeSyntax.self))
                print("ImplicitlyUnwrappedOptionalTypeSyntax", inheritedType.typeName.is(ImplicitlyUnwrappedOptionalTypeSyntax.self))
                print("MemberTypeIdentifierSyntax", inheritedType.typeName.is(MemberTypeIdentifierSyntax.self))
                print("MetatypeTypeSyntax", inheritedType.typeName.is(MetatypeTypeSyntax.self))
                print("MissingTypeSyntax", inheritedType.typeName.is(MissingTypeSyntax.self))
                print("NamedOpaqueReturnTypeSyntax", inheritedType.typeName.is(NamedOpaqueReturnTypeSyntax.self))
                print("OptionalTypeSyntax", inheritedType.typeName.is(OptionalTypeSyntax.self))
                print("PackExpansionTypeSyntax", inheritedType.typeName.is(PackExpansionTypeSyntax.self))
                print("PackReferenceTypeSyntax", inheritedType.typeName.is(PackReferenceTypeSyntax.self))
                print("SimpleTypeIdentifierSyntax", inheritedType.typeName.is(SimpleTypeIdentifierSyntax.self))
                print("TupleTypeSyntax", inheritedType.typeName.is(TupleTypeSyntax.self))
                print("TypeSyntax", inheritedType.typeName.is(TypeSyntax.self))

                // TODO: When `index == 0` check if the inherited type is a class or implicitly adds Hashable conformance
            }
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
                    return "private "
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
            \(scope)\(hasSuperclass ? "override " : "")func hash(into hasher: inout Hasher) {
        """

        if hasSuperclass {
            hashIntoImplementation += "\n"
            hashIntoImplementation += "    super.hash(into: &hasher))"
        }

        var equalityImplementation: String =  """
            \(scope)\(hasSuperclass ? "override " : "")static func ==(lhs: \(identifiedDeclaration.identifier.text), rhs: \(identifiedDeclaration.identifier.text)) -> Bool {
        """

        for (index, propertyName) in propertyNames.enumerated() {
            hashIntoImplementation += "\n"
            hashIntoImplementation += "    hasher.combine(\(propertyName))"
            equalityImplementation += "\n"
            if index == 0 {
                if hasSuperclass {
                    hashIntoImplementation += "\n"
                    hashIntoImplementation += "    super.==(lhs: lhs, rhs: rhs)"
                    equalityImplementation += "        && lhs.\(propertyName) == rhs.\(propertyName)"
                } else {
                    equalityImplementation += "    lhs.\(propertyName) == rhs.\(propertyName)"
                }
            } else {
                equalityImplementation += "        && lhs.\(propertyName) == rhs.\(propertyName)"
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
            DeclSyntax(stringLiteral: hashIntoImplementation),
            DeclSyntax(stringLiteral: equalityImplementation),
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
