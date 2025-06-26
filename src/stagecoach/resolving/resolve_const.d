module stagecoach.resolving.resolve_const;

import stagecoach.all;

/**
 * Resolve n to a Number
 */
void resolveConstNumber(Expression n, ResolveState state) {
    if(!n.isResolved() || n.isA!Number) return;

    if(Identifier id = n.as!Identifier) {
        if(id.target.isConst()) {
            if(Number num = id.target.var.initialiser().as!Number) {
                rewriteToNodeRef(state, n, num);
                return;
            }
        }
    }
}
