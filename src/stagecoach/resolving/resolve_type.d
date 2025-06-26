module stagecoach.resolving.resolve_type;

import stagecoach.all;

void resolveArrayType(ArrayType n, ResolveState state) {
    resolveConstNumber(n.numElementsExpr(), state);
}

void resolveEnum(Enum n, ResolveState state) {
    if(n.elementType().isResolved()) {
        // Update the member values (for integer or real enums)
        Type elementType = n.elementType();
        if(!elementType.isInteger() && !elementType.isReal()) {

            // If there are any missing initialisers this is an error
            if(!n.allMembersHaveInitialisers()) {
                semanticError(n, ErrorKind.ENUM_MISSING_INITIALISERS);
            }
            n.resolveEvaluated = true;
            return;
        }

        // The element type is an integer or real. Generate the missing initialisers

        if(elementType.isInteger() || elementType.isReal()) {
            int value = 0;
            foreach(i, m; n.members()) {

                if(m.hasInitialiser()) {
                    // Set value to the initialiser value
                    if(Number num = m.first().as!Number) {
                        value = num.getValueAsInt();
                    } else {
                        // We can't evaluate this yet. Bail out and try again in the next pass
                        return;
                    }

                    if(!m.value().getType().exactlyMatches(elementType)) {
                        rewriteToAs(state, m.value(), m.value().as!Expression, makeTypeRef(elementType));
                    }
                    
                } else {
                    // Create a new Number node with the correct value
                    Number num = makeNode!Number(m.tokenIndex);
                    num.setType(elementType);
                    num.setValue(value);
                    m.add(num);
                }
                value++;
            }
        }

        n.resolveEvaluated = true;
    }
}

void resolveTypeOf(TypeOf n, ResolveState state) {
    if(!n.expr().isResolved()) return;

    Type type = n.expr().getType();

    rewriteToTypeRef(state, n, type);
}

void resolveTypeRef(TypeRef n, ResolveState state) {
    assert(!n.type.isResolved());

    Module mod = state.mod;
    bool includeImports = true;
    bool requirePublic = false;

    if(n.fromModule) {
        mod = n.fromModule;
        includeImports = false;
        requirePublic = true;
    }

    if(auto t = mod.getUDT(n.name, includeImports)) {
        if(requirePublic) {
            if(!isPublic(t)) {
                warn(n, "Type %s is not public".format(n.name));
                return;
            }
        }
        n.type = t;
    }
}
