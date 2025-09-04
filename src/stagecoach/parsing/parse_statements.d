module stagecoach.parsing.parse_statements;

import stagecoach.all;


void parseStatementsAtModuleScope(ParseState state) {

    updateLoggingContext(state.mod, LoggingStage.Parsing);

    state.mod.log("Parsing module");

    // Loop until all tokens are consumed or an error is found
    while(!state.eof() && !state.project.hasErrors()) {
        parseStatementAtModuleScope(state);
    }

    // If we get here and some of the attribute scopes were not closed we should report an error
    state.attributes.parse(state);
    foreach(a; state.attributes.getCurrentAttributes()) {
        syntaxError(state.mod, a.token, "This attribute scope was not closed");
    }
}
/**
 * Statements allowed at Module scope:
 *   - Import   
 *   - Struct   
 *   - Alias
 *   - Enum    
 *   - Union    *todo
 *
 *   - Function ::= fn foo(Types) -> Type {}
 *   - Variable ::= Type name = Expression
 */
void parseStatementAtModuleScope(ParseState state) {
    Module mod = state.mod;

    state.attributes.parse(state);

    // We can run out of statements here if the last thing was an #end
    if(state.eof()) return;

    // Consume public, private
    bool isPublic = parseVisibility(state, true, true);

    // Variable
    if(isType(state) || "const" == state.text()) {
        parseVariable(mod, state, isPublic);
    } else switch(state.tokenKind()) {
        case TokenKind.IDENTIFIER:
            switch(state.text()) {
                case "extern":
                case "fn":
                    parseFunction(mod, state, isPublic);
                    break;
                case "alias":
                    parseAlias(mod, state, isPublic);
                    break;
                case "enum":
                    parseEnum(mod, state, isPublic);
                    break;
                case "struct": 
                    parseStruct(mod, state, isPublic);
                    break; 
                case "import":
                    parseImport(mod, state, isPublic);
                    break;
                default: 
                    syntaxError(state, "Expected statement but found %s".format(state.token()));
                    break;
            }
            break;
        default:
            syntaxError(state, "Expected statement but found %s".format(state.token()));
            break;
    }
}

/**
 * Statements allowed at Function scope:
 *   - Assert
 *   - Return
 *   - Variable    
 *   - While        *todo        
 *   - For          *todo
 *   - Expression   
 */
void parseStatementAtFunctionScope(Statement parent, ParseState state) {

    state.attributes.parse(state);

    if(state.tokenKind() == TokenKind.RBRACE) return;

    // Variable
    if(isType(state) || "const" == state.text()) {
        parseVariable(parent, state, false);
        return;
    }

    switch(state.tokenKind()) {
        case TokenKind.IDENTIFIER:
            if("return" == state.text()) {
                parseReturn(parent, state);
                return;
            }
            if("assert" == state.text()) {
                parseAssert(parent, state);
                return;
            }
            break;
        default:
            break;
    }

    // If we get here then it must be an Expression
    parseExpression(parent, state); 
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

/**
 * Consume visibility tokens if present.
 * Return true if public
 */
bool parseVisibility(ParseState state, bool atModuleScope, bool modifiersHereAreValid) {
    bool isPublic = atModuleScope ? state.insidePublicScopeModule : state.insidePublicScopeStruct;

    void check() {
        if(!modifiersHereAreValid) {
            syntaxError(state, "Visibility modifiers are not allowed here");
        }
    }

    while(!state.eof()) {
        if(state.text() == "public") {
            check();
            state.next();

            if(state.tokenKind() == TokenKind.COLON) {
                state.next();
                if(atModuleScope) state.insidePublicScopeModule = true;
                else state.insidePublicScopeStruct = true;
            }
            isPublic = true;

        } else if(state.text() == "private") {
            check();
            state.next();

            if(state.tokenKind() == TokenKind.COLON) {
                state.next();
                if(atModuleScope) state.insidePublicScopeModule = false;
                else state.insidePublicScopeStruct = false;
            }

            isPublic = false;
        } else {
            break;
        }
    }
    return isPublic;
}

/**
 * 'alias' name '=' Type
 */
void parseAlias(Node parent, ParseState state, bool isPublic) {
    auto a = makeNode!Alias(state);
    parent.add(a);

    a.isPublic = isPublic || state.hasAttribute("public");

    state.skip("alias");

    a.name = state.text(); state.next();

    state.skip(TokenKind.EQUAL);

    parseType(a, state);
}

/**
 * 'assert' '(' Expression ')'
 */
void parseAssert(Node parent, ParseState state) {
    auto a = makeNode!Assert(state);
    parent.add(a);

    state.skip("assert");

    state.skip(TokenKind.LPAREN);
    parseExpression(a, state);
    state.skip(TokenKind.RPAREN);
}

/**
 * ENUM        ::= 'enum' name [ ':' Type ] '{' { ENUM_MEMBER } '}'
 * ENUM_MEMBER ::= name [ '=' Expression ]
 */
void parseEnum(Node parent, ParseState state, bool isPublic) {
    auto e = makeNode!Enum(state);
    parent.add(e);

    e.isPublic = isPublic || state.hasAttribute("public");
    e.isUnqualified = state.hasAttribute("unqualified");

    state.skip("enum");

    e.name = state.text(); state.next();

    if(state.tokenKind() == TokenKind.COLON) {
        state.skip(TokenKind.COLON);
        parseType(e, state);
    } else {
        e.add(makeSimpleType(TypeKind.INT));
    }

    state.skip(TokenKind.LBRACE);

    while(state.tokenKind() != TokenKind.RBRACE) {

        if(state.tokenKind() != TokenKind.IDENTIFIER) {
            syntaxError(state, "Expected identifier");
        }

        auto em = makeNode!EnumMember(state);
        e.add(em);

        em.name = state.text(); state.next();

        if(state.tokenKind() == TokenKind.EQUAL) {
            state.skip(TokenKind.EQUAL);
            parseExpression(em, state);
        }

        if(state.tokenKind().isOneOf(TokenKind.SEMICOLON, TokenKind.COMMA)) {
            state.next();
        }
    }

    state.skip(TokenKind.RBRACE);
}

/**
 * fn foo(Types) -> Type {}
 */
void parseFunction(Module mod, ParseState state, bool isPublic) {
    auto f = makeNode!Function(state);
    mod.add(f);

    f.isPublic = isPublic || state.hasAttribute("public");

    if(string alias_ = state.getAttribute("name").value) {
        f.alias_ = alias_;
    }

    if(state.hasAttribute("ABI")) {
        string value = state.getAttribute("ABI").value; 
        if(value.isOneOf("C", "WIN64")) {
            f.callingConvention = value;
        } else {
            syntaxError(state, "Unrecognised ABI '%s'".format(value));
        }
    }

    // fn
    state.skip("fn");

    // Name
    f.name = state.token().text; state.next();

    if(mod.isMainModule) {
        f.isMain = f.name == "main";
    }

    // Parameters
    state.skip(TokenKind.LPAREN);
    while(state.tokenKind() != TokenKind.RPAREN) {
        parseParameter(f, state);
        f.numParams++;

        // ,
        if(state.tokenKind() == TokenKind.COMMA) {
            state.skip(TokenKind.COMMA);
        }
    }
    state.skip(TokenKind.RPAREN);

    // Return type
    if(state.tokenKind() == TokenKind.RARROW) {
        state.skip(TokenKind.RARROW);
        
        parseType(f, state);
    } else {
        // Assume return void
        f.add(makeSimpleType(TypeKind.VOID));
    }

    // Move the return type to the front
    if(f.numChildren() > 1) {
        Node returnType = f.last();
        f.addToFront(returnType);
    }

    // Body (optional if this is an extern function)
    if(state.tokenKind() == TokenKind.LBRACE) {
        state.skip(TokenKind.LBRACE);
        while(state.tokenKind() != TokenKind.RBRACE) {
            parseStatementAtFunctionScope(f, state);
        }
        state.skip(TokenKind.RBRACE);
    } else {
        f.isExtern = true;
    }
    if(f.isExtern && !f.callingConvention) {
        f.callingConvention = "C";
    }
}

/**
 * [ 'const' ] Type [ name ]
 */
void parseParameter(Function parent, ParseState state) {

    Variable v = makeNode!Variable(state);
    parent.add(v);

    v.vkind = VariableKind.PARAMETER;
    v.isConst = state.text() == "const";
    if(v.isConst) state.next();
    
    // Type
    parseType(v, state);

    Type type = v.last().as!Statement.getType();
    if(type.typeKind() == TypeKind.C_VARARGS) {
        parent.hasVarargParam = true;
    }

    // name
    if(state.tokenKind() != TokenKind.COMMA && state.tokenKind() != TokenKind.RPAREN) {
        v.name = state.token().text; state.next();
    }
}

/**
 * [ 'const' ] Type name [ '=' Expression ]
 */
void parseVariable(Node parent, ParseState state, bool isPublic) {

    auto v = makeNode!Variable(state);
    parent.add(v);

    v.isPublic = isPublic || state.hasAttribute("public");
    v.isConst = state.text() == "const";
    if(v.isConst) {
        state.next();

        if(Struct st = parent.as!Struct) {
            if(!st.isNamed()) {
                // Anon structs cannot have const members
                semanticError(state.project, state.mod, v, ErrorKind.VARIABLE_ANON_STRUCT_CONST);
            }
        }
    }

    string abi;

    if(state.hasAttribute("ABI")) {
        abi = state.getAttribute("ABI").value;
    }

    // Type
    parseType(v, state);

    if(abi) {
        assert(v.getType().isFunction());
        v.getType().extract!Function.callingConvention = abi;
    }

    if(state.tokenKind() == TokenKind.IDENTIFIER && !isType(state)) {
        v.name = state.token().text; state.next();
    }

    if(v.parent.isA!Function) {
        v.vkind = VariableKind.LOCAL;
    } else if(v.parent.isA!Struct) {
        v.vkind = VariableKind.MEMBER;
    } else {
        v.vkind = VariableKind.GLOBAL;
    }

    // Initialiser
    if(state.tokenKind() == TokenKind.EQUAL) {
        state.skip(TokenKind.EQUAL);
        parseExpression(v, state);
    } else if(v.isConst) {

        if(Struct st = parent.as!Struct) {
            // Don't complain yet. Check later to see if this is set to something
            return;
        }

        syntaxError(state, -1, "Const variables must be initialised");
    }
}

/**
 * 'return' [ Expression ]
 */
void parseReturn(Statement parent, ParseState state) {
    Return r = makeNode!Return(state);
    parent.add(r);

    state.skip("return");

    // If there is something on the same line then assume it is an expression
    if(state.isOnSameLine()) {
        parseExpression(r, state);
    }
}

/**
 * 'struct' name '{' { Variable } '}'
 */
void parseStruct(Node parent, ParseState state, bool isPublic) {
    Struct s = makeNode!Struct(state);
    parent.add(s);

    s.isPublic = isPublic || state.hasAttribute("public");

    if(state.hasAttribute("packed")) {
        s.isPacked = true;
    }

    state.skip("struct");

    s.name = state.token().text; state.next();

    state.skip(TokenKind.LBRACE);

    while(state.tokenKind() != TokenKind.RBRACE) {

        // Consume public, private
        bool isPublicMember = parseVisibility(state, false, s.isNamed());
        
        // Anon struct members are always public
        if(!s.isNamed()) {
            isPublicMember = true;
        }

        parseVariable(s, state, isPublicMember);

        if(state.tokenKind().isOneOf(TokenKind.SEMICOLON, TokenKind.COMMA)) {
            state.next();
        }
    }

    state.skip(TokenKind.RBRACE);
}

/**
 * 'import' [ name '=' ] moduleName { '/' moduleName }
 */
void parseImport(Node parent, ParseState state, bool isPublic) {
    // This Import type is not actually used anywhere as far as I remember. 
    // The scanner and Module between them hold all of this information. 
    // Maybe we can just remove Import and skip these tokens.

    Import i = makeNode!Import(state);
    parent.add(i);

    // todo - implement public imports

    state.skip("import");

    if(state.peek(1).kind == TokenKind.EQUAL) {
        i.name = state.text(); state.next();
        state.skip(TokenKind.EQUAL);
    }

    string moduleName = state.text(); state.next();

    while(state.tokenKind() == TokenKind.SLASH) {
        state.skip(TokenKind.SLASH);
        moduleName ~= "/";
        moduleName ~= state.text(); state.next();
    }

    state.mod.log("importing %s", moduleName);
    
    // This Module must exist otherwise the scanner would have failed
    i.fromModule = state.project.modulesByName[moduleName];
}
