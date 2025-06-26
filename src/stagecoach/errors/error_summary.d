module stagecoach.errors.error_summary;

import stagecoach.all;

string getSummaryMessage(CompilationError error) {
    Statement stmt = error.stmt;

    switch(error.kind()) {
        case ErrorKind.SYNTAX:
            return error.extraInfo.as!StringErrorExtraInfo.msg;

        case ErrorKind.FUNCTION_NOT_FOUND: 
            return "Function not found: %s".format(stmt.as!Call().name); 
        case ErrorKind.IDENTIFIER_NOT_FOUND: {
            Identifier id = stmt.as!Identifier();   
            Struct st = id.parent.isA!Dot ? id.parent.as!Dot.container().getType().extract!Struct : null;
            if(st) {
                string structName = st ? st.name : id.parent.as!Dot.container().getType().toString();
                return "Member %s not found for struct %s".format(id.name, structName);
            } 
            return "Identifier not found: %s".format(id.name);
        }
        case ErrorKind.CALL_AMBIGUOUS_FUNCTION: {
            return "Ambiguous function call: %s".format(stmt.as!Call().name);
            //string s2 = formatAmbiguousFunction(stmt.as!Call());
            //return s1 ~ "\n" ~ s2; 
        }
        case ErrorKind.IDENTIFIER_NOT_VISIBLE:
            return "Identifier is not visible: %s".format(stmt.as!Identifier().name);

        case ErrorKind.FUNCTION_MISSING_RETURN:
            return "This function is missing a return statement";

        case ErrorKind.ADDRESS_OF_CONSTANT:
            return "Cannot take the address of a constant";

        case ErrorKind.ARRAY_LITERAL_NUM_ELEMENTS: {
            ArrayLiteral al = error.stmt.as!ArrayLiteral; assert(al);
            ArrayType at = al.getType().as!ArrayType; assert(at);
            return "Array literal has %s elements, but the array type requires %s".format(al.elements().length, at.numElements());
        }
        case ErrorKind.ARRAY_LITERAL_ELEMENT_TYPE_MISMATCH: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            ArrayLiteral al = ele.parent.as!ArrayLiteral; assert(al);
            ArrayType at = al.getType().as!ArrayType; assert(at);
            return "Cannot implicitly convert %s to the array element type %s".format(ele.getType(), at.elementType());    
        }
        case ErrorKind.VARIABLE_INITIALISER_TYPE_MISMATCH: {
            Expression initialiser = error.stmt.as!Expression; assert(initialiser);
            Variable v = initialiser.parent.as!Variable; assert(v);
            return "Cannot implicitly convert %s to %s".format(initialiser.getType().shortName(), v.getType().shortName());    
        }
        case ErrorKind.IF_MISSING_THEN_EXPRESSION:
            return "If expression requires an expression at the end of the 'then' block";
        case ErrorKind.IF_MISSING_ELSE_EXPRESSION:
            return "If expression requires an expression at the end of the 'else' block";
        case ErrorKind.IF_EXPRESSION_TYPE_MISMATCH:
            return "If expression requires the 'then' and 'else' expressions to be castable to the same type";
        case ErrorKind.CAST_INVALID: {
            As a = error.stmt.as!As; assert(a);
            return "Cannot cast %s to %s".format(a.leftType().shortName(), a.rightType().shortName());
        }
        case ErrorKind.IS_TYPE_MISMATCH: {
            Is i = error.stmt.as!Is; assert(i);
            if(i.left().isA!Type) {
                return "(Type is Expression) is not valid. Use ::typeOf() here instead";
            }
            return "(Expression is Type) is not valid. Use ::typeOf() here instead";
        }
        case ErrorKind.STRUCT_LITERAL_MEMBER_TYPE_MISMATCH: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            StructLiteral sl = ele.parent.as!StructLiteral; assert(sl);
            Struct st = sl.getStruct(); assert(st);
            int index = sl.members().indexOf(ele);
            Variable var = st.members()[index];
            return "Cannot implicitly convert %s to the struct member type %s".format(ele.getType(), var.getType());
        }
        case ErrorKind.STRUCT_LITERAL_ARGUMENT_NOT_FOUND: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            StructLiteral sl = ele.parent.as!StructLiteral; assert(sl);
            int index = sl.members().indexOf(ele);
            string name = sl.names[index];
            return "Struct member '%s' not found".format(name);
        }
        case ErrorKind.STRUCT_LITERAL_ARGUMENT_NOT_VISIBLE: {
            Token nameTok = error.mod.getToken(error.stmt.tokenIndex - 2);
            if(nameTok.kind == TokenKind.IDENTIFIER) {
                return "Struct member '%s' is not visible".format(nameTok.text);
            }
            return "Struct member is not visible";
        }
        case ErrorKind.STRUCT_LITERAL_MIXED_ARGUMENTS:
            return "Cannot mix named and unnamed arguments in a struct literal";
        case ErrorKind.STRUCT_LITERAL_TOO_MANY_ARGUMENTS:
            return "Struct literal has too many arguments";
        case ErrorKind.STRUCT_LITERAL_UNNAMED_ARGUMENT:
            return "Named struct literals require all arguments to be named";

        case ErrorKind.BINARY_UNSIGNED_WITH_REAL:
            return "Cannot use unsigned operator with real numbers";
        case ErrorKind.BINARY_ASSIGNMENT_TYPE_MISMATCH:
            return "Cannot assign %s to %s".format(error.stmt.as!Binary.rightType().shortName(), error.stmt.as!Binary.leftType().shortName());    
        case ErrorKind.BINARY_MODIFYING_CONSTANT:
            return "Constant is modified";
        
        case ErrorKind.BUILTIN_OFFSET_OF_NOT_MEMBER:
            return "@offsetOf() requires a struct member as the first argument";  
        case ErrorKind.BUILTIN_ISCONST_NOT_IDENTIFIER:
            return "::isConst() requires an identifier as the first argument";    
        case ErrorKind.BUILTIN_ISPUBLIC_NOT_IDENTIFIER:
            return "::isPublic() requires an identifier as the first argument";

        case ErrorKind.STRUCT_MEMBER_UNNAMED:
            return "Expecting this Struct member to be named";
        case ErrorKind.CALL_ARGUMENT_TYPE_MISMATCH: {
            Expression arg = error.stmt.as!Expression; assert(arg);
            Call call = arg.parent.as!Call; assert(call);
            int index = call.arguments().indexOf(arg);
            Type paramType = call.target.func.paramTypes()[index];
            return "Cannot implicitly convert %s to the parameter type %s".format(arg.getType().shortName(), paramType.shortName());
        }
        case ErrorKind.FUNCTION_NON_EXTERN_MISSING_BODY:
            return "Non-extern function must have a body";

        case ErrorKind.VARIABLE_SHADOWING: {
            Variable v = error.stmt.as!Variable; assert(v);
            return "Variable '%s' shadows another variable in the same scope".format(v.name);
        }
        case ErrorKind.VARIABLE_UNINITIALISED_CONST:
            return "Const variable is not initialised";
        case ErrorKind.VARIABLE_PARAMETER_INITIALISER:
            return "Default parameter values are not allowed";
        case ErrorKind.VARIABLE_ANON_STRUCT_CONST:
            return "Anonymous structs cannot have const members";

        case ErrorKind.ENUM_MISSING_INITIALISERS:
            return "Enum members must be explicitly initialised when the element type is not an integer or real";

        default: 
            return "Generic Error: %s".format(error.kind());
    }
}
