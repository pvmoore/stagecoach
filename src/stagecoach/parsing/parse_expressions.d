module stagecoach.parsing.parse_expressions;

import stagecoach.all;

/**
 * Parse an expression
 */
void parseExpression(Node parent, ParseState state) {
    parseSingle(parent, state);
    parseInfix(parent, state);
}   

/**
 * Parse an expression. This overload ensures that any new Expressions do not get reordered above the current parent.
 */
void parseExpressionWithUpperBound(Node parent, ParseState state) {

    auto p = makeNode!Parens(state);

    parseSingle(p, state);
    parseInfix(p, state);

    assert(p.numChildren() == 1);
    parent.add(p.first());
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * Parse an Expression left hand side.
 *
 *   - AddressOf
 *   - ArrayLiteral
 *   - Builtin
 *   - Call
 *   - Identifier
 *   - If
 *   - ModuleRef
 *   - Null
 *   - Number
 *   - Parens
 *   - StringLiteral
 *   - StructLiteral
 *   - Type
 *   - Unary
 *   - ValueOf
 */
void parseSingle(Node parent, ParseState state) {

    if(isType(state)) {
        parseType(parent, state);
        return;
    }

    switch(state.tokenKind()) {
        case TokenKind.IDENTIFIER:
            if("if" == state.text()) {
                parseIf(parent, state);
                return;
            }
            if("null" == state.text()) {
                parseNull(parent, state);
                return;
            }
            if("true" == state.text() || "false" == state.text()) {
                parseNumber(parent, state);
                return;
            }
            if("not" == state.text()) {
                syntaxError(state, "Boolean 'not' should be replaced with 'is false'");
                return;
            }
            if(state.text().startsWith("@")) {
                syntaxError(state, "Builtin functions must be called as ::name()");
                return;
            }
            // Function call
            if(state.peek(1).kind == TokenKind.LPAREN) {
                parseCall(parent, state);
                return;
            }
            // Module alias
            if(state.mod.isModuleAlias(state.text())) {
                parseModuleRef(parent, state);
                return;
            }
            // Local variable
            parseIdentifier(parent, state);
            return;
        case TokenKind.NUMBER:
            parseNumber(parent, state);
            return;
        case TokenKind.TILDE:
        case TokenKind.MINUS:
            parseUnary(parent, state);
            return;
        case TokenKind.LPAREN:
            parseParens(parent, state);
            return;    
        case TokenKind.STRING:
            parseStringLiteral(parent, state);
            return;
        case TokenKind.LSQUARE:
            parseArrayLiteral(parent, state);
            return;
        case TokenKind.AMPERSAND:
            parseAddressOf(parent, state);
            return;
        case TokenKind.STAR:
            parseValueOf(parent, state);
            return;
        case TokenKind.BANG:
            syntaxError(state, "Use 'not' instead of '!' for boolean negation");
            return;
        case TokenKind.COLON2:
            parseBuiltin(parent, state);
            return;
        case TokenKind.LBRACE:
            parseStructLiteral(parent, state);
            return;
        default:
            break;
    }
    syntaxError(state, "Expecting expression but found %s".format(state.token()));
}

/**
 * Optional Expression infix / middle:
 *  - Binary
 *  - As
 *  - Is
 *  - Index
 *  - Dot
 */
void parseInfix(Node parent, ParseState state) {
    while(!state.eof()) {
        switch(state.tokenKind()) {
            case TokenKind.NONE:
            case TokenKind.LBRACE:
            case TokenKind.RBRACE:
            case TokenKind.LPAREN:
            case TokenKind.RPAREN:
            case TokenKind.RSQUARE:
            case TokenKind.SEMICOLON:
            case TokenKind.COMMA:
            case TokenKind.NUMBER:
            case TokenKind.STRING:
            case TokenKind.QUESTION:
            case TokenKind.AT:
            case TokenKind.HASH:
            case TokenKind.DOLLAR:
            case TokenKind.COLON2:
                return;
            case TokenKind.IDENTIFIER:
                switch(state.text()) {
                    case "is": {
                        auto i = parseAndReturnIs(state);
                        parent = attachAndRead(parent, i, state, true);
                        break;
                    }
                    case "as": {
                        auto a = parseAndReturnAs(state);
                        parent = attachAndRead(parent, a, state, true);
                        break;
                    }
                    case "and":
                    case "or": 
                    case "udiv":
                    case "umod":
                    case "ult":
                    case "ugt":
                    case "ulte":
                    case "ugte":
                    case "ushr": {
                        auto b = parseAndReturnBinary(state);
                        parent = attachAndRead(parent, b, state, true);
                        break;
                    }
                    default: 
                        return;   
                }
                break;
            case TokenKind.EQUAL2:
                syntaxError(state, "Use 'is' for equality comparison");
                return;
            case TokenKind.BANG_EQUAL:
                syntaxError(state, "Use 'is not' for inequality comparison");
                return;

            case TokenKind.PLUS:
            case TokenKind.MINUS:
            case TokenKind.STAR:
            case TokenKind.SLASH:
            case TokenKind.PERCENT:
            case TokenKind.HAT:
            case TokenKind.AMPERSAND:
            case TokenKind.PIPE:

            case TokenKind.EQUAL:
            case TokenKind.LANGLE:
            case TokenKind.RANGLE:
            case TokenKind.LANGLE_EQUAL:
            case TokenKind.RANGLE_EQUAL:
            case TokenKind.LANGLE2:
            case TokenKind.RANGLE2:
            case TokenKind.LANGLE2_EQUAL:
            case TokenKind.RANGLE2_EQUAL:
            
            case TokenKind.PLUS_EQUAL:
            case TokenKind.MINUS_EQUAL:
            case TokenKind.STAR_EQUAL:
            case TokenKind.SLASH_EQUAL:
            case TokenKind.PERCENT_EQUAL:
            case TokenKind.HAT_EQUAL:
            case TokenKind.AMPERSAND_EQUAL:
            case TokenKind.PIPE_EQUAL:
            case TokenKind.TILDE_EQUAL:
                // exit if this token is on the next line
                if(!state.isOnSameLine()) return;

                auto b = parseAndReturnBinary(state);
                parent = attachAndRead(parent, b, state, true);
                break;
            case TokenKind.LSQUARE: {
                auto i = parseAndReturnIndex(state); 
                parent = attachAndRead(parent, i, state, false);
                break;
            }
            case TokenKind.DOT: {
                auto d = parseAndReturnDot(state);
                parent = attachAndRead(parent, d, state, true);
                break;
            }
            default: throwIf(true, "Unhandled infix %s", state.token());
        }
    }
}

Expression attachAndRead(Node parent, Expression newExpr, ParseState state, bool andRead) {

    Node prev = parent;

    // Check for ambiguous boolean and/or expressions
    if(Binary b = newExpr.as!Binary) {
        if(b.op == Operator.BOOL_AND || b.op == Operator.BOOL_OR) {
            if(Binary b2 = parent.as!Binary) {
                if((b2.op == Operator.BOOL_AND || b2.op == Operator.BOOL_OR) && b2.op != b.op) {
                    syntaxError(state, -1, "Use parentheses to clarify the intended meaning of this boolean expression");
                }
            }
        }
    }

    if(Is i = newExpr.as!Is) {
        if(parent.isA!Is) {
            int offset = state.peek(-1).text == "not" ? -2 : -1;
            syntaxError(state, offset, "This 'is' expression is ambiguous. Use parentheses to clarify the intended meaning");
        }
    }

    // Swap expressions according to operator precedence
    if(Expression prevExpr = prev.as!Expression) {

        // Adjust to account for operator precedence
        while(prevExpr.parent && newExpr.precedence() >= prevExpr.precedence()) {

            if(!prevExpr.parent.isA!Expression) {
                prev = prevExpr.parent;
                break;
            }

            prevExpr = prevExpr.parent.as!Expression;
            prev     = prevExpr;
        }
    }

    newExpr.add(prev.last());

    prev.add(newExpr);

    if(andRead) {
        parseSingle(newExpr, state);
    }

    return newExpr;
}

/**
 * '&' Expression
 */
void parseAddressOf(Node parent, ParseState state) {
    auto a = makeNode!AddressOf(state);
    parent.add(a);

    state.skip(TokenKind.AMPERSAND);

    parseExpression(a, state);
}

/**
 * '[' { Expression [ ',' ] } ']'
 */
void parseArrayLiteral(Node parent, ParseState state) {
    ArrayLiteral a = makeNode!ArrayLiteral(state);
    parent.add(a);

    state.skip(TokenKind.LSQUARE);

    while(state.tokenKind() != TokenKind.RSQUARE) {
        parseExpression(a, state);

        // ,
        if(state.tokenKind() == TokenKind.COMMA) {
            state.skip(TokenKind.COMMA);
        }
    }

    state.skip(TokenKind.RSQUARE);
}

/**
 * '::' name '(' Expression ')'
 */
void parseBuiltin(Node parent, ParseState state) {
    auto b = makeNode!Builtin(state);
    parent.add(b);

    state.skip(TokenKind.COLON2);
    b.name = "@" ~ state.text(); 
    state.next();

    switch(b.name) {
        case "@alignOf":
        case "@debug":
        case "@isArray":
        case "@isBool":
        case "@isConst":
        case "@isEnum":
        case "@isFunction":
        case "@isInteger":
        case "@isPacked":
        case "@isPointer":
        case "@isPublic":
        case "@isReal":
        case "@isStruct":
        case "@isUnion":
        case "@isValue":
        case "@isVoid":
        case "@offsetOf":
        case "@sizeOf":
            state.skip(TokenKind.LPAREN);
            parseExpressionWithUpperBound(b, state);
            state.skip(TokenKind.RPAREN);
            break;
        default:
            syntaxError(state, "Unknown builtin function %s".format(b.name));
    }
}

/**
 * name '(' { Expression } ')' 
 */
void parseCall(Node parent, ParseState state) {
    Call c = makeNode!Call(state);
    c.target.call = c;
    parent.add(c);

    c.name = state.text(); state.next();

    // Arguments
    state.skip(TokenKind.LPAREN);

    while(state.tokenKind() != TokenKind.RPAREN) {
        parseExpressionWithUpperBound(c, state);

        // ,
        if(state.tokenKind() == TokenKind.COMMA) {
            state.skip(TokenKind.COMMA);
        }
    }

    state.skip(TokenKind.RPAREN);
}

/**
 * name
 */
void parseIdentifier(Node parent, ParseState state) {
    Identifier i = makeNode!Identifier(state);
    i.target.identifier = i;
    i.name = state.text();
    parent.add(i);

    state.next();
}

/**
 * if        ::= 'if' condition then [ else ] 
 * condition ::= '(' Expression ')' 
 * then      ::= [ '{ ] { Statement } [ '}' ]
 * else      ::= 'else' [ '{' ] { Statement } [ '}' ]
 */
void parseIf(Node parent, ParseState state) {
    If i = makeNode!If(state);
    parent.add(i);

    state.skip("if");

    // Condition
    state.skip(TokenKind.LPAREN);
    parseExpression(i, state);
    state.skip(TokenKind.RPAREN);

    // 'then' branch (required)
    if(state.tokenKind() == TokenKind.LBRACE) {
        // Statement block
        state.skip(TokenKind.LBRACE);

        while(state.tokenKind() != TokenKind.RBRACE) {
            parseStatementAtFunctionScope(i, state);
        }

        state.skip(TokenKind.RBRACE);
    } else {
        // Single then Statement
        parseStatementAtFunctionScope(i, state);
    }

    i.numThenStatements = i.numChildren() - 1;

    // 'else' branch (optional)
    if("else" == state.text()) {
        i.hasElse = true;
        state.skip("else");

        if(state.tokenKind() == TokenKind.LBRACE) {
            // Statement block
            state.skip(TokenKind.LBRACE);

            while(state.tokenKind() != TokenKind.RBRACE) {
                parseStatementAtFunctionScope(i, state);
            }
            state.skip(TokenKind.RBRACE);
        } else {
            // Single else Statement
            parseStatementAtFunctionScope(i, state);
        }
    }
}

/**
 * moduleAlias
 */
void parseModuleRef(Node parent, ParseState state) {
    ModuleRef m = makeNode!ModuleRef(state);
    parent.add(m);

    m.mod = state.mod.importedModulesQualified[state.text()];
    state.next();
}

/**
 * 123
 * 123.4
 */
void parseNumber(Node parent, ParseState state) {
    Number n = makeNode!Number(state);
    n.stringValue = state.text(); state.next();

    parent.add(n);
}

/**
 * null
 */
void parseNull(Node parent, ParseState state) {
    Null n = makeNode!Null(state);
    parent.add(n);

    state.next();
}

/**
 * '(' Expression ')'
 */
void parseParens(Node parent, ParseState state) {
    Parens p = makeNode!Parens(state);
    parent.add(p);

    state.skip(TokenKind.LPAREN);

    // todo - handle empty or double parens
    //if(state.kind()==TokenKind.LPAREN) errorBadSyntax(module_, t, "Empty parenthesis");

    parseExpression(p, state);

    state.skip(TokenKind.RPAREN);
}

/**
 * "string"
 * "string" "string"
 * "string"z
 */
void parseStringLiteral(Node parent, ParseState state) {
    StringLiteral s = makeNode!StringLiteral(state);
    parent.add(s);

    string value = state.text(); state.next();

    if(value.endsWith("z")) {
        value = value[1..$-2];
        s.isCString = true;
    } else {

        value = value[1..$-1];

        // This is a string struct string literal. 
        // Consume multiple string literals as long as they are not c-strings
        while(state.tokenKind() == TokenKind.STRING) {
            if(state.text().endsWith("z")) break;

            // Append the string literal
            value ~= state.text()[1..$-1];
            state.next();
        }
    }  

    s.stringValue = value;
}

/**
 * '{' { [name ':'] Expression } [',' Expression ] '}'
 */
void parseStructLiteral(Node parent, ParseState state) {
    StructLiteral s = makeNode!StructLiteral(state);
    parent.add(s);

    state.skip(TokenKind.LBRACE);

    while(state.tokenKind() != TokenKind.RBRACE) {

        // Named argument:
        if(state.tokenKind() == TokenKind.IDENTIFIER && state.peek(1).kind == TokenKind.COLON) {
            s.names ~= state.text(); state.next();
            state.skip(TokenKind.COLON);
        } else {
            s.names ~= null;
        }

        parseExpressionWithUpperBound(s, state);

        // ,
        if(state.tokenKind() == TokenKind.COMMA) {
            state.skip(TokenKind.COMMA);
        }
    }

    state.skip(TokenKind.RBRACE);
}  

/**
 * not | ~ | -
 */
void parseUnary(Node parent, ParseState state) {

    auto u = makeNode!Unary(state);
    parent.add(u);

    /// - ~
    if(state.tokenKind()==TokenKind.TILDE) {
        u.op = Operator.BIT_NOT;
    } else if(state.tokenKind()==TokenKind.MINUS) {
        u.op = Operator.NEG;
    } else assert(false, "How did we get here?");

    state.next();

    // Parse the expression
    parseExpression(u, state);
}

/**
 * '*' Expression
 */
void parseValueOf(Node parent, ParseState state) {
    auto v = makeNode!ValueOf(state);
    parent.add(v);

    state.skip(TokenKind.STAR);

    parseExpression(v, state);
}

/**
 * 'as' Type
 */
Expression parseAndReturnAs(ParseState state) {

    auto a = makeNode!As(state);

    state.skip("as");

    return a;
}

/**
 * 'is' [ 'not' ] Type
 */
Expression parseAndReturnIs(ParseState state) {

    auto a = makeNode!Is(state);

    state.skip("is");

    if("not" == state.text()) {
        a.negate = true;
        state.next();

        if("not" == state.text()) {
            syntaxError(state, "Double negation is not allowed");
        }
    }

    return a;
}

/**
 * + - * / % ^ & | etc...
 */
Binary parseAndReturnBinary(ParseState state) {
    Binary b = makeNode!Binary(state);
    string text = state.text();

    switch(text) {
        case "ushr":
            if(state.peek(1).kind == TokenKind.EQUAL) {
                b.op = Operator.USHR_ASSIGN;
                state.next();
            } else {
                b.op = Operator.USHR;
            } 
            break;
        case "udiv":
            if(state.peek(1).kind == TokenKind.EQUAL) {
                b.op = Operator.UDIV_ASSIGN;
                state.next();
            } else {
                b.op = Operator.UDIV;
            } 
            break;
        case "umod":
            if(state.peek(1).kind == TokenKind.EQUAL) {
                b.op = Operator.UMOD_ASSIGN;
                state.next();
            } else {
                b.op = Operator.UMOD;
            } 
            break;
        case "ult": b.op = Operator.ULT; break;
        case "ugt": b.op = Operator.UGT; break;
        case "ulte": b.op = Operator.ULTE; break;
        case "ugte": b.op = Operator.UGTE; break;
        case "and": b.op = Operator.BOOL_AND; break;
        case "or": b.op = Operator.BOOL_OR; break;
        default: b.op = toOperator(state.tokenKind()); break;
    }

    state.next();
    return b;
}

/**
 * '[' Expression ']'
 */
Index parseAndReturnIndex(ParseState state) {
    Index i = makeNode!Index(state);
    state.skip(TokenKind.LSQUARE);

    parseExpression(i, state);

    state.skip(TokenKind.RSQUARE);
    return i;
}

/**
 * '.' 
 */
Dot parseAndReturnDot(ParseState state) {
    Dot d = makeNode!Dot(state);
    state.skip(TokenKind.DOT);

    return d;
}
