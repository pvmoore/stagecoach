module stagecoach.resolving.resolve_builtin;

import stagecoach.all;

void resolveBuiltin(Builtin n, ResolveState state) {

    // Wait for all children to be resolved
    if(!areResolved(n.arguments())) return;

    Expression[] arguments = n.arguments();
    Expression arg0 = arguments[0];

    if("@debug" == n.name) {
        // Output the Expression to the console
        auto expr = n.first().as!Expression;
        rewriteToBool(state, n, true);

        string s = expr.isA!StringLiteral ? expr.as!StringLiteral.stringValue : expr.toString();
        consoleLog("DEBUG: %s", s);
    } else if("@isArray" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isA!ArrayType;
        rewriteToBool(state, n, result);
    } else if("@isEnum" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isEnum();
        rewriteToBool(state, n, result);
    } else if("@isFunction" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isFunction();
        rewriteToBool(state, n, result);
    } else if("@isInteger" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isInteger();
        rewriteToBool(state, n, result);
    } else if("@isReal" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isReal();
        rewriteToBool(state, n, result);
    } else if("@isBool" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isBool();
        rewriteToBool(state, n, result);  
    } else if("@isStruct" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isStruct();
        rewriteToBool(state, n, result);
    } else if("@isPacked" == n.name) {
        auto expr = n.first().as!Expression;
        if(Struct st = expr.getType().extract!Struct) {
            rewriteToBool(state, n, st.isPacked);
        } else {
            rewriteToBool(state, n, false);
        }
    } else if("@isVoid" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isVoidValue();
        rewriteToBool(state, n, result);
    } else if("@isPointer" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = expr.getType().isPointer();
        rewriteToBool(state, n, result);
    } else if("@isPublic" == n.name) {
        auto expr = n.first().as!Expression;
        rewriteToBool(state, n, isPublic(n, expr));
    } else if("@isConst" == n.name) {
        auto expr = n.first().as!Expression;
        rewriteToBool(state, n, isConst(n, expr));
    } else if("@isValue" == n.name) {
        auto expr = n.first().as!Expression;
        auto result = !expr.getType().isPointer();
        rewriteToBool(state, n, result);
    } else if("@sizeOf" == n.name) {
        auto expr = n.first().as!Expression;
        auto size = expr.getType().size();
        rewriteToInt(state, n, size);
    } else if("@alignOf" == n.name) {
        auto expr = n.first().as!Expression;
        auto align_ = expr.getType().alignment();
        rewriteToInt(state, n, align_);
    } else if("@offsetOf" == n.name) {

        Dot dot = arg0.as!Dot;

        if(!dot) {
            semanticError(arg0, ErrorKind.BUILTIN_OFFSET_OF_NOT_MEMBER);
            return;
        }

        Expression expr = dot.getEndOfChain();

        if(Identifier id = expr.as!Identifier) {

            if(id.target.isVariable()) {
                auto v = id.target.var;
                if(v.isMember()) {
                    auto st = v.parent.as!Struct;
                    auto index = st.getMemberIndex(v);
                    auto offset = st.getOffsetOfMember(index);
                    rewriteToLong(state, n, offset);
                    return;
                } else {
                    semanticError(n, ErrorKind.BUILTIN_OFFSET_OF_NOT_MEMBER);
                }
            }

        } else {

            log(state.mod, "expr is %s", n.first().nodeKind());

            semanticError(n, ErrorKind.BUILTIN_OFFSET_OF_NOT_IDENTIFIER);
        }
    } 
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

bool isConst(Builtin n, Node expr) {
    if(Number num = expr.extractNumber()) return true;
    if(Identifier id = expr.extractIdentifier()) return id.target.isConst();
    if(Index idx = expr.as!Index) return isConst(n, idx.expr());
    if(Dot d = expr.as!Dot) return isConst(n, d.member());

    semanticError(n, ErrorKind.BUILTIN_ISCONST_NOT_IDENTIFIER);
    return false;
}

bool isPublic(Builtin n, Node expr) {
    if(Identifier id = expr.extractIdentifier()) return id.target.isPublic();
    if(Index idx = expr.as!Index) return isPublic(n, idx.expr());
    if(Dot d = expr.as!Dot) return isPublic(n, d.member());

    semanticError(n, ErrorKind.BUILTIN_ISPUBLIC_NOT_IDENTIFIER);
    return false;
}
