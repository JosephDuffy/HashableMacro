import SwiftSyntax
import XCTest

#if canImport(HashableMacroMacros)
@testable import HashableMacroMacros

final class LabeledExprListSyntaxExtensionsTests: XCTestCase {
    func testAddingUnknownArgumentToEmptyList() {
        var list = LabeledExprListSyntax([])
        list.addOrUpdateArgument(
            label: "test",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: []
        )
        XCTAssertEqual(String(describing: list), "test: false")
    }

    func testAddingUnknownArgumentToNonEmptyList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true)
            ),
        ])
        list.addOrUpdateArgument(
            label: "test",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: []
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, test: false")
    }

    func testAddingKnownArgumentToStartOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "secondParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "thirdParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "firstParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: true),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, secondParameter: false, thirdParameter: false")
    }

    func testUpdatingKnownArgumentAtStartOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "secondParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "thirdParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "firstParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: false, secondParameter: true, thirdParameter: false")
    }

    func testAddingKnownArgumentToMiddleOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "thirdParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "secondParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, secondParameter: false, thirdParameter: false")
    }

    func testUpdatingKnownArgumentInMiddleOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "secondParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "thirdParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "secondParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, secondParameter: false, thirdParameter: false")
    }

    func testAddingKnownArgumentToEndOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "secondParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "thirdParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: false),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, secondParameter: false, thirdParameter: false")
    }

    func testUpdatingKnownArgumentToEndOfList() {
        var list = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: "firstParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "secondParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: true),
                trailingComma: .commaToken(trailingTrivia: .space)
            ),
            LabeledExprSyntax(
                label: "thirdParameter",
                colon: .colonToken(trailingTrivia: .space),
                expression: BooleanLiteralExprSyntax(booleanLiteral: false)
            ),
        ])
        list.addOrUpdateArgument(
            label: "thirdParameter",
            expression: BooleanLiteralExprSyntax(booleanLiteral: true),
            allArguments: [
                LabeledExprSyntax(
                    label: "firstParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: false)
                ),
                LabeledExprSyntax(
                    label: "secondParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
                LabeledExprSyntax(
                    label: "thirdParameter",
                    colon: .colonToken(trailingTrivia: .space),
                    expression: BooleanLiteralExprSyntax(booleanLiteral: true)
                ),
            ]
        )
        XCTAssertEqual(String(describing: list), "firstParameter: true, secondParameter: true, thirdParameter: true")
    }
}
#endif
