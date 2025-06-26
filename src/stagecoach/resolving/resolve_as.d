module stagecoach.resolving.resolve_as;

import stagecoach.all;

void resolveAs(As n, ResolveState state) {
    
    Type lt = n.leftType();
    Type rt = n.rightType();
    assert(lt);
    assert(rt);

    if(!lt.isResolved() || !rt.isResolved()) return;

    checkExplicitCast(n, lt, rt);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void checkExplicitCast(As n, Type lt, Type rt) {
    if(lt.exactlyMatches(rt)) {
        // todo - rewrite to remove the As node because it is not necessary
        n.resolveEvaluated = true;
        return;
    }

    if(lt.isPointer() && rt.isPointer()) {
        // For now, allow any pointer to pointer conversion
        n.resolveEvaluated = true;
        return;
    }

    if(lt.isPointer() && rt.isValue()) {
        // Thie is ok if the right type is integer
        if(!rt.isInteger()) {
            semanticError(n, ErrorKind.CAST_INVALID);
            return;
        }
    }
    if(lt.isValue() && rt.isPointer()) {
        // This is ok if left type is an integer
        if(!lt.isInteger()) {
            semanticError(n, ErrorKind.CAST_INVALID);
            return;
        }
    }

    if(lt.isStruct() && rt.isStruct()) {
        assert(lt.isValue() && rt.isValue());

        // Techcically we could allow this if all of the following are true:
        //  - The sizes are the same
        //  - The number of members is the same
        //  - The members can be implicitly cast
        // but for now we will disallow this since it is unlikely to be useful and is not very efficient.

        semanticError(n, ErrorKind.CAST_INVALID);
        return;
    }

    if(lt.isEnum() && rt.isEnum()) {
        Enum leftEnum = lt.extract!Enum;
        Enum rightEnum = rt.extract!Enum;
        assert(leftEnum != rightEnum);

        // These must be different enums. Allow this if the element types are convertable
        checkExplicitCast(n, leftEnum.elementType(), rightEnum.elementType());
        return;
    }

    if(lt.isEnum()) {
        // Casting from an Enum to a non-Enum

    }

    if(rt.isEnum()) {
        // Casting from a non-Enum to an Enum
        checkExplicitCast(n, lt, rt.extract!Enum.elementType());
        return;
    }

    if(n.expr().isA!Number) {
        // todo - we can convert the Number to the correct type now and remove the As node
    }

    // If we get here then the cast is valid
    n.resolveEvaluated = true;
}
