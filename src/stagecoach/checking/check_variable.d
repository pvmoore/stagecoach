module stagecoach.checking.check_variable;

import stagecoach.all;

void checkVariable(Variable v) {

    Type type = v.getType();

    varargsChecks(v, type);
    initialiserChecks(v, type);
    shadowingChecks(v);
}

final class VariableErrorExtraInfo : ErrorExtraInfo {
    Variable[] duplicateVariables;
    this(Variable[] dupes) {
        this.duplicateVariables = dupes;
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * - C_VARARGS can only be a parameter
 * - It must be the last parameter
 * - The function must be extern
 */
void varargsChecks(Variable v, Type type) {
    if(type.typeKind() == TypeKind.C_VARARGS) {

        // Must only be used as a parameter
        if(v.vkind != VariableKind.PARAMETER) {
            semanticError(v, ErrorKind.VARIABLE_C_VARARGS_NOT_PARAMETER);
        } else {
            // This C_VARARGS is a parameter

            // Check that it is the last parameter
            Function f = v.parent.as!Function;
            if(f.params()[$-1] !is v) {
                semanticError(v, ErrorKind.VARIABLE_C_VARARGS_NOT_LAST);
            }

            // Check that the function is extern
            if(!f.isExtern) {
                semanticError(v, ErrorKind.VARIABLE_C_VARARGS_NOT_EXTERN);
            }
        }
    }
}

/**
 * If there is an initialiser, check that the type can be converted to the Variable type
 */
void initialiserChecks(Variable v, Type type) {
    Module mod = v.getModule();
    if(v.hasInitialiser()) {

        Expression init = v.initialiser();
        Type initType = init.getType();
        
        if(v.isParameter()) {
            // Don't allow default parameters 
            semanticError(init, ErrorKind.VARIABLE_PARAMETER_INITIALISER);
            return;
        }

        if(!initType.canImplicitlyCastTo(type)) {

            if(initType.isFunction()) {
                log(mod, "init is a Function: %s", initType);
                log(mod, "endOfChain = %s", init.getEndOfChain().nodeKind());
            }


            if(Dot d = init.as!Dot) {
                log(mod, "Dot: %s %s", d.container(), d.member());
            }

            log(mod, "Variable: Cannot cast %s to %s", initType, type);
            semanticError(init, ErrorKind.VARIABLE_INITIALISER_TYPE_MISMATCH);
        }
    } else {
        if(v.isParameter()) {
            return;
        }
        if(v.isConst) {
            // if(Struct st = v.parent.as!Struct) {
            //     // This variable is a struct member. Don't complain here
            //     return;
            // }
            semanticError(v, ErrorKind.VARIABLE_UNINITIALISED_CONST);
        } else {
            // If the type is a struct then error if any of the members are const
            // if(Struct st = type.extract!Struct) {
            //     foreach(m; st.members()) {
            //         if(m.isConst) {
            //             semanticError(m, ErrorKind.VARIABLE_UNINITIALISED_CONST);
            //             break;
            //         }
            //     }
            // }
        }
    }
}

/**
 * Check for any duplicate Variables visible within the same scope.
 * Ignore struct/union members here. They will be checked elsewhere 
 */
void shadowingChecks(Variable v) {
    if(v.isMember()) return;

    Variable[] dupes;

    if(v.vkind == VariableKind.LOCAL || v.vkind == VariableKind.PARAMETER) {
        // Check earlier locals and parameters
        Node n = v.prev(false);
        while(n) {
            if(Variable v2 = n.as!Variable) {
                if(v2.name && v2.name == v.name) {
                    dupes ~= v2;
                }
            }
            n = n.prev(false);
        }
    }

    // Check globals
    Module mod = v.getModule();
    foreach(v2; mod.childrenOfType!Variable()) {

        // We only need to check earlier globals
        if(v2 == v) break;
        
        if(v2.name == v.name) {
            dupes ~= v2;
        }
    }

    if(dupes.length > 0) {
        semanticError(v, ErrorKind.VARIABLE_SHADOWING, new VariableErrorExtraInfo(dupes));
    }
}
