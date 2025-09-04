module stagecoach.scanning.scanner;

import stagecoach.all;

struct ScanResult {
    UDT[string] udts;
    ScanImport[] imports;

    string toString() {
        return ("\n" ~
            "UDTs (public):\n--------------------\n%s\n\n" ~
            "UDTs (private):\n--------------------\n%s\n\n" ~
            "Qualified imports:\n--------------------\n%s\n\n" ~
            "Unqualified imports:\n--------------------\n%s")
            .format(udts.values().filter!(it=>it.isPublic).map!(it => it.name).join("\n"),
                    udts.values().filter!(it=>!it.isPublic).map!(it => it.name).join("\n"),
                    imports.filter!(it=>it.alias_ !is null).map!(it => it.name).join("\n"), 
                    imports.filter!(it=>it.alias_ is null).map!(it => it.name).join("\n"));
    }
}

struct UDT {
    string name;
    bool isPublic;
}

struct ScanImport {
    string name;
    string alias_;
    Token aliasToken;
    Token moduleToken;
}

/**
 * Scan Module for user defined Types (struct, union, enum or alias) and imports.
 *
 * This is useful for parsing later otherwise it can be difficult to disambiguate
 * between a Type and an Identifier.
 */
ScanResult scanModule(Module mod) {

    updateLoggingContext(mod, LoggingStage.Scanning);

    mod.log("Scanning module");

    Token[] tokens = mod.tokens;
    ScanResult result;

    int brace = 0;
    int square = 0;
    int paren = 0;
    int angle = 0;
    int i;
    bool publicScope;

    Token peek(int offset = 0) { return i + offset >= tokens.length ? NO_TOKEN : tokens[i + offset]; }

    bool isPublicStmt() {
        bool pub = publicScope || peek(-2).text == "public";
        bool priv = peek(-2).text == "private";
        return pub && !priv;    
    }

    while(i < tokens.length) {
        Token tok = peek();
        switch(tok.kind) with(TokenKind) {
            case LBRACE: brace++; break;
            case RBRACE: brace--; break;
            case LSQUARE: square++; break;
            case RSQUARE: square--; break;
            case LPAREN: paren++; break;
            case RPAREN: paren--; break;
            case LANGLE: angle++; break;
            case RANGLE: angle--; break;    
            case IDENTIFIER: {

                // Ignore any identifier that is not at the top level
                if(brace != 0 || square != 0 || paren != 0 || angle != 0) break; 

                if(tok.text == "public" && peek(1).kind == TokenKind.COLON) {
                    publicScope = true;
                    break;
                }

                if(tok.text == "private" && peek(1).kind == TokenKind.COLON) {
                    publicScope = false;
                    break;
                }

                string name;

                if("struct" == tok.text && peek(1).kind == TokenKind.IDENTIFIER) {
                    i++;
                    name = peek().text;
                    result.udts[name] = UDT(name, isPublicStmt());
                } else if("union" == tok.text && peek(1).kind == TokenKind.IDENTIFIER) {
                    i++;
                    name = peek().text;
                    result.udts[name] = UDT(name, isPublicStmt());
                } else if("alias" == tok.text && peek(1).kind == TokenKind.IDENTIFIER) {
                    i++;
                    name = peek().text;
                    result.udts[name] = UDT(name, isPublicStmt());
                } else if("enum" == tok.text && peek(1).kind == TokenKind.IDENTIFIER) {
                    i++;
                    name = peek().text;
                    result.udts[name] = UDT(name, isPublicStmt());
                } else if("import" == tok.text) {
                    // import         name [ / name ... ]
                    // import alias = name [ / name ... ]
                    i++;
                    if(peek().kind == TokenKind.EQUAL) {
                        i+=2;
                    }
                    ScanImport imp;

                    if(peek(1).kind == TokenKind.EQUAL) {
                        imp.aliasToken = peek();
                        imp.alias_ = peek().text;
                        i+=2;
                    }

                    imp.moduleToken = peek();
                    imp.name ~= peek().text;

                    while(peek(1).kind == TokenKind.SLASH) {
                        i+=2;
                        imp.name ~= "/";
                        imp.name ~= peek().text;
                    }

                    result.imports ~= imp;
                }

                break;
            }
            default:
                break;
        }
        i++;
    }

    return result;
}
