module stagecoach.resolving.resolve_struct_literal;

import stagecoach.all;

void resolveStructLiteral(StructLiteral n, ResolveState state) {

    // Use the parent type if available.

    Type parentType = state.resolveTypeFromParent(n);
    if(parentType.isResolved()) {
        n.setType(parentType);
        return;
    }

    // Assume that the parent type will be available at some point.
}
