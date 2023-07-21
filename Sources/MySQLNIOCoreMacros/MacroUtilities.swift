import SwiftDiagnostics
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftCompilerPlugin
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension TokenKind {
    static var accessSpecifierKeywords: Set<TokenKind> {
        .init([
            .open,
            .public,
            .package,
            .internal,
            .fileprivate,
            .private
        ].map(TokenKind.keyword(_:)))
    }
}

extension DeclGroupSyntax {
    func descriptiveDeclKind(withArticle article: Bool = false) -> String {
        switch self {
        case is ActorDeclSyntax:     "\(article ? "an " : "")actor"
        case is ClassDeclSyntax:     "\(article ? "a "  : "")class"
        case is ExtensionDeclSyntax: "\(article ? "an " : "")extension"
        case is ProtocolDeclSyntax:  "\(article ? "a "  : "")protocol"
        case is StructDeclSyntax:    "\(article ? "a "  : "")struct"
        case is EnumDeclSyntax:      "\(article ? "an " : "")enum"
        default:                     fatalError("Unknown DeclGroupSyntax")
        }
    }
}

extension EnumDeclSyntax {
    var caseElements: [EnumCaseElementSyntax] {
        self.memberBlock.members
            .lazy
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap(\.elements)
    }
}

extension TokenKind {
    var withInitialUppercased: TokenKind {
        guard case .identifier(let text) = self else { return self }
        
        return .identifier("\(text.prefix(1).uppercased())\(text.dropFirst())")
    }
}

extension TokenSyntax {
    var withInitialUppercased: TokenSyntax {
        .init(self.tokenKind.withInitialUppercased, presence: self.presence)
    }
}
