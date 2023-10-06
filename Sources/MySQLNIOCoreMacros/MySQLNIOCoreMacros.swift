import SwiftDiagnostics
import SwiftSyntax
import SwiftCompilerPlugin
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MySQLNIOCoreMacrosPlugin: CompilerPlugin {
    var providingMacros: [any Macro.Type] = [StateMachineStateConditions.self]
}

public struct StateMachineStateConditions: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [.declIsNotEnum(declaration, node: node)])
        }
        
        let access = enumDecl.modifiers.first { TokenKind.accessSpecifierKeywords.contains($0.name.tokenKind) }
        
        if access?.name.tokenKind == .keyword(.public) {
            context.diagnose(.publicDecl(node: node))
        }
        
        let plainCases = enumDecl.caseElements.map { $0.with(\.parameterClause, nil) }
        
        return plainCases.map { """
            var is\(raw: $0.name.withInitialUppercased): Bool {
                switch self {
                case .\(raw: $0.name): true
                default: false
                }
            }
            """
        }
    }
}

extension Diagnostic {
    static func declIsNotEnum(_ decl: some DeclGroupSyntax, node: some SyntaxProtocol) -> Self {
        .init(node: Syntax(node), message: DeclNotEnumDiagnostic(kind: decl.descriptiveDeclKind(withArticle: true)))
    }
    
    static func publicDecl(node: some SyntaxProtocol) -> Self {
        .init(node: Syntax(node), message: DeclIsPublicDiagnostic())
    }
}

struct DeclNotEnumDiagnostic: DiagnosticMessage {
    let kind: String

    var message: String { "'StateMachineStateConditions' can only be attached to an enum, not \(self.kind)" }
    var diagnosticID: MessageID { .init(domain: "StateMachineStateConditionsDiagnostic", id: "notAnEnum") }
    var severity: DiagnosticSeverity { .error }
}

struct DeclIsPublicDiagnostic: DiagnosticMessage {
    var message: String { "'StateMachineStateConditions' is not intended to be attached to 'public' declarations" }
    var diagnosticID: MessageID { .init(domain: "StateMachineStateConditionsDiagnostic", id: "publicDecl") }
    var severity: DiagnosticSeverity { .warning }
}
