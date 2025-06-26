module stagecoach.checking.check;

import stagecoach.all;

bool checkAllModules(Project project) {
    foreach(m; project.allModules) {
        checkModule(m);
    }
    return !project.hasErrors();   
}

void checkModule(Module mod) {
    updateLoggingContext(mod, LoggingStage.Checking);
    log(mod, "Checking Module");

    checkChildren(mod);
}

void checkChildren(Node parent) {
    foreach(n; parent.children) {

        // check from the bottom up
        if(n.hasChildren()) {
            checkChildren(n);
        }

        switch(n.nodeKind()) {
            case NodeKind.ARRAY_LITERAL: checkArrayLiteral(n.as!ArrayLiteral); break;
            case NodeKind.AS: checkAs(n.as!As); break;
            case NodeKind.BINARY: checkBinary(n.as!Binary); break;
            case NodeKind.CALL: checkCall(n.as!Call); break;
            case NodeKind.FUNCTION: checkFunction(n.as!Function); break;
            case NodeKind.IDENTIFIER: checkIdentifier(n.as!Identifier); break;
            case NodeKind.STRUCT: checkStruct(n.as!Struct); break;
            case NodeKind.STRUCT_LITERAL: checkStructLiteral(n.as!StructLiteral); break;
            case NodeKind.VARIABLE: checkVariable(n.as!Variable); break;
            default: break;
        }
    }
}

void checkArrayLiteral(ArrayLiteral n) {
    //log(" Checking array literal");

    assert(n.getType().isArrayType());
    ArrayType at = n.getType().as!ArrayType;

    // Check that we have the correct number of elements
    if(n.elements().length != at.numElements()) {
        semanticError(n, ErrorKind.ARRAY_LITERAL_NUM_ELEMENTS);
    }

    // Check that the elements can be cast to the array element type
    Type elementType = n.elementType();
    foreach(e; n.elements()) {
        if(!e.getType().canImplicitlyCastTo(elementType)) {
            semanticError(e, ErrorKind.ARRAY_LITERAL_ELEMENT_TYPE_MISMATCH);
            break;
        }
    }
}

void checkBinary(Binary n) {
    if(n.op.isUnsigned()) {
        if(!n.leftType().isInteger() || !n.rightType().isInteger()) {
            semanticError(n, ErrorKind.BINARY_UNSIGNED_WITH_REAL);
        }
    }
    if(n.op.isAssign()) {

        // Check that the right hand side can be cast to the left hand side
        if(!n.rightType().canImplicitlyCastTo(n.leftType())) {
            log(n.getModule(), "Binary: Cannot cast %s to %s", n.rightType(), n.leftType());
            semanticError(n, ErrorKind.BINARY_ASSIGNMENT_TYPE_MISMATCH);
        }
    }
}

void checkCall(Call n) {
    //log(" Checking call %s", n.name);

    // Function f = n.target.func;
    // assert(f);

    Type[] paramTypes = n.target.paramTypes();
    Expression[] arguments = n.arguments();

    // Check that the arguments can be cast to the parameter types
    foreach(i, arg; arguments) {
        Type argType = arg.getType();
        if(i >= paramTypes.length) break;

        Type paramType = paramTypes[i];
        if(paramType.isVararg()) break;

        if(!argType.canImplicitlyCastTo(paramType)) {
            semanticError(arg, ErrorKind.CALL_ARGUMENT_TYPE_MISMATCH);
        }
    }
}


void checkStruct(Struct n) {
    if(n.name) {

    } else {
        // Anon struct
        if(n.parent.isA!Variable) {
            // This struct must have named Variables
            foreach(v; n.members()) {
                if(!v.name) {
                    semanticError(v, ErrorKind.STRUCT_MEMBER_UNNAMED);
                }
            }
        }
    }
}

void checkStructLiteral(StructLiteral n) {
    //log(" Checking struct literal");

    Struct st = n.getStruct();
    assert(st);

    // Mixing named and unnamed arguments
    if(n.hasNamedArguments() && n.hasUnnamedArguments()) {
        semanticError(n, ErrorKind.STRUCT_LITERAL_MIXED_ARGUMENTS);
        return;
    }

    Variable[] variables = st.members();
    Expression[] expressions = n.members();

    import std.algorithm : count;
    auto numNonConstMembers = variables.count!(v=>!v.isConst);

    // If number of arguments is greater than the number of (non-const) struct members then this is an error
    if(expressions.length > numNonConstMembers) {
        semanticError(n, ErrorKind.STRUCT_LITERAL_TOO_MANY_ARGUMENTS);
        return;
    }

    void checkConversion(Type vType, Expression e) {
        if(!e.getType().canImplicitlyCastTo(vType)) {
            semanticError(e, ErrorKind.STRUCT_LITERAL_MEMBER_TYPE_MISMATCH);
        }
    }

    if(n.hasNamedArguments()) {
        // Named arguments: (They must all be named if we get here)

        foreach(i, name; n.names) {
            assert(name);
            int index = st.getMemberIndex(name);
            // Check that the member name exists in the Struct
            if(index == -1) {
                semanticError(n.members()[i], ErrorKind.STRUCT_LITERAL_ARGUMENT_NOT_FOUND);
            } else {
                // Check that the argument can be cast to the struct member type
                Variable v = st.getMemberByIndex(index);
                Expression e = n.getMember(i.as!uint);

                checkConversion(v.getType(), e);

                if(!v.isPublic && v.getModule() !is n.getModule()) {
                    semanticError(e, -2, ErrorKind.STRUCT_LITERAL_ARGUMENT_NOT_VISIBLE);
                }
            }
        } 
    } else {
        // Unnamed arguments: (They must all be unnamed if we get here)

        if(st.isNamed()) {
            // Named structs must have named arguments
            semanticError(n, ErrorKind.STRUCT_LITERAL_UNNAMED_ARGUMENT);
            return;
        }

        // Check that the elements can be cast to the struct member type
        int vid = 0;
        foreach(e; expressions) {
            Variable v;
            do{ v = st.getMemberByIndex(vid++); }while(v.isConst);

            Type vt = v.getType();

            checkConversion(vt, e);
        }
    }
}


void checkAs(As n) {

    Type lt = n.leftType();
    Type rt = n.rightType();

    if(lt.isPointer() && rt.isPointer()) {
        // Allow pointer conversions
        return;
    }
    if(lt.isPointer() != rt.isPointer()) {
        semanticError(n, ErrorKind.CAST_INVALID);
    }
}
