module stagecoach.resolving.resolve_variable;

import stagecoach.all;

void resolveVariable(Variable n, ResolveState state) {
    if(n.hasInitialiser()) {
        // If the initialiser is the same as the default initialiser then we can remove it

        Expression init = n.initialiser();
        if(!init.isResolved()) return;

        Type type =n.getType();
        bool canRemove = false;

        if(type.isPointer()) {
            if(init.isA!Null) {
                canRemove = true;
            }
        } else if(type.isInteger() || type.isReal()) {
            if(Number num = init.as!Number) {
                if(num.isZero()) {
                    canRemove = true;
                }
            }
        }

        if(canRemove) {
            state.mod.log("Removing explicit Variable initialiser %s", n.name);
            n.parent.remove(n);
        }
    }
}
