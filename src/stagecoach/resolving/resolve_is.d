module stagecoach.resolving.resolve_is;

import stagecoach.all;

void resolveIs(Is n, ResolveState state) {
    
    // Wait for both sides to be resolved
    if(!n.left().isResolved() || !n.right().isResolved()) return;

    //log("resolving is: %s is %s", n.left(), n.right());
    
    n.resolveEvaluated = true;
    
    Type lt = n.leftType();
    Type rt = n.rightType();
    Expression left = n.left();
    Expression right = n.right();
    
    // Type is Type
    if(left.isA!Type && right.isA!Type) {
        // Rewrite to bool Number

        //log("Type (%s) is Type (%s) %s", lt, rt, lt.exactlyMatches(rt));

        // Type (TypeRef intptr) is Type (TypeRef 'intptr', intptr) false

        bool result = lt.exactlyMatches(rt);
        if(n.negate) result = !result;

        rewriteToBool(state, n, result);
        return;
    }

    // Type is Expression
    // Expression is Type
    if(left.isA!Type != right.isA!Type) {
        semanticError(n, ErrorKind.IS_TYPE_MISMATCH);
        return;
    }

    // Pointer is Pointer
    if(lt.isPointer() && rt.isPointer()) {
        // Rewrite to Binary ==
        rewriteToBinary(state, n, n.negate ? Operator.NOT_EQUAL : Operator.EQUAL, left, right, makeBoolType());
        return;
    }

    // Pointer is Value is always false
    if(lt.isPointer() != rt.isPointer()) {
        rewriteToBool(state, n, n.negate);
        return;
    }

    // Expression is Expression
    if(lt.isValue() && rt.isValue()) {

        // if(state.mod.name == "tests/enum/test_enums") 
        //     log("[%s:%s] %s is %s", state.mod.name, n.startToken.line, lt, rt);

        if(lt.isArrayType() != rt.isArrayType()) {
            rewriteToBool(state, n, n.negate);
            return;
        }

        if(lt.isStruct() != rt.isStruct()) {
            rewriteToBool(state, n, n.negate);
            return;
        }

        if(lt.isEnum() != rt.isEnum()) {
            rewriteToBool(state, n, n.negate);
            return;
        }

        // If the Types of left and right are different sizes then they must be different
        // if(lt.size() != rt.size()) {
        //     rewriteToBool(state, n, n.negate);
        //     return;
        // }

        if(lt.isStruct()) {

            // If the structs are different then this is false
            if(!lt.exactlyMatches(rt)) {
                rewriteToBool(state, n, n.negate);
                return;
            }

            //log("rewrite Struct to memcmp. Struct is %s", lt.extract!Struct);

            // Rewrite to memcmp
            ulong size = lt.extract!Struct.getSize();
            auto leftPtr = makeAs(makeAddressOf(left), makeBytePointerType());
            auto rightPtr = makeAs(makeAddressOf(right), makeBytePointerType());
            auto length = makeLongNumber(size);

            rewriteToMemcmp(state, n, leftPtr, rightPtr, length, !n.negate);
            return;
        }

        // Array comparison. The sizes must be the same otherwise we would have caught it above 
        // Rewrite to Binary ==
        if(lt.isArrayType()) {
            
            // Element Types are different
            if(!lt.as!ArrayType.elementType().exactlyMatches(rt.as!ArrayType.elementType())) {
                rewriteToBool(state, n, n.negate);
                return;
            }

            // Assume left and right are both of the same ArrayType so we need to check the contents

            // Rewrite this to memcmp

            auto leftPtr = makeAs(makeAddressOf(left), makeBytePointerType());
            auto rightPtr = makeAs(makeAddressOf(right), makeBytePointerType());

            // Multiply num elements by sizeof (numElements should be a Number at this point)
            auto numElements = makeIntNumber(lt.as!ArrayType.numElements());
            auto size = makeIntNumber(lt.as!ArrayType.elementType().size());
            auto length = makeBinary(Operator.MUL, numElements, size, makeIntType());

            rewriteToMemcmp(state, n, leftPtr, rightPtr, length, !n.negate);
            return;
        }

        rewriteToBinary(state, n, n.negate ? Operator.NOT_EQUAL : Operator.EQUAL, left, right, makeBoolType());
        return;
    }

}
