module stagecoach.resolving.resolve_array_literal;

import stagecoach.all;

void resolveArrayLiteral(ArrayLiteral n, ResolveState state) {

    // Use the parent type if available.

    Type parentType = state.resolveTypeFromParent(n);
    if(parentType.isResolved()) {
        n.setType(parentType);
        return;
    }

    // Assume that the parent type will be available at some point.
}

private:

Type getTypeFromElements(ArrayLiteral n, ResolveState state) {
    if(n.elements().length == 0) return makeUnknownType();

    Type elementType = n.first().as!Expression.getType();
    if(!elementType.isResolved()) return makeUnknownType();

    return makeArrayType(elementType, n.elements().length.as!uint);
}
