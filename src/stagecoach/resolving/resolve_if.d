module stagecoach.resolving.resolve_if;

import stagecoach.all;

void resolveIf(If n, ResolveState state) {
    if(n.isExpression()) {
        auto thenExpr = n.lastThenStatement();
        auto elseExpr = n.lastElseStatement();

        if(thenExpr is null || !thenExpr.isA!Expression) {
            semanticError(n, ErrorKind.IF_MISSING_THEN_EXPRESSION);
        }
        if(elseExpr is null || !elseExpr.isA!Expression) {
            semanticError(n, ErrorKind.IF_MISSING_ELSE_EXPRESSION);
        }
        if(thenExpr is null || elseExpr is null) return;

        if(!n.thenType().isResolved() || !n.elseType().isResolved()) return;

        Type type = selectCommonType(n.thenType(), n.elseType());
        if(type is null) {
            semanticError(n, ErrorKind.IF_EXPRESSION_TYPE_MISMATCH);
            return;
        }

        n.setType(type);

        // todo - If then or else blocks contain a return this is an error


    } else {
        n.setType(makeVoidType());
    }
}
