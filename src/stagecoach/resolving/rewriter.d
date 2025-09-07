module stagecoach.resolving.rewriter;

import stagecoach.all;

void rewrite(ResolveState state, Node n, Node newNode) {
    state.setRewriteOccurred();

    newNode.detach();
    n.replaceWith(newNode);
}

void rewriteToAs(ResolveState state, Node n, Expression expr, Type type) {
    state.setRewriteOccurred();

    auto as = makeNode!As(expr.tokenIndex);
    n.replaceWith(as);

    as.add(expr);
    as.add(type);
}

void rewriteToCall(ResolveState state, Node n, string name, Expression[] arguments) {
    state.setRewriteOccurred();
    auto call = makeCall(name, arguments);
    n.replaceWith(call);
}

void rewriteToBool(ResolveState state, Node n, bool value) {
    state.setRewriteOccurred();
    n.replaceWith(makeBoolNumber(value));
}
void rewriteToInt(ResolveState state, Node n, int value) {
    state.setRewriteOccurred();
    n.replaceWith(makeIntNumber(value));
}
void rewriteToLong(ResolveState state, Node n, long value) {
    state.setRewriteOccurred();
    n.replaceWith(makeLongNumber(value));
}
void rewriteToNumber(ResolveState state, Statement n, string stringValue) {
    state.setRewriteOccurred();
    auto num = makeNode!Number(n.tokenIndex);
    num.stringValue = stringValue;
    n.replaceWith(num);
}

void rewriteToBinary(ResolveState state, Node n, Operator op, Expression left, Expression right, Type type = null) {
    state.setRewriteOccurred();

    Type t = type ? type : makeUnknownType();
    auto b = makeBinary(op, left, right, t);
    n.replaceWith(b);
}

void rewriteToTypeRef(ResolveState state, Expression n, Type type) {
    state.setRewriteOccurred();
    auto tr = makeNode!TypeRef(n.tokenIndex);
    tr.type = type;
    n.replaceWith(tr);
}

void rewriteToNodeRef(ResolveState state, Expression n, Expression node) {
    state.setRewriteOccurred();
    auto nr = makeNode!NodeRef(n.tokenIndex);
    nr.node = node;
    n.replaceWith(nr);
}

void rewriteToMemcmp(ResolveState state, Node n, Expression left, Expression right, Expression length, bool equal) {
    state.setRewriteOccurred();

    auto op = equal ? Operator.EQUAL : Operator.NOT_EQUAL;

    auto call = makeCall("memcmp", [left, right, length]);
    auto b = makeBinary(op, call, makeIntNumber(0), makeBoolType());

    n.replaceWith(b);

    if(!state.mod.hasFunction("memcmp")) {
        auto memcmp = makeExternFunctionDeclaration("memcmp", makeSimpleType(TypeKind.INT), [
            makeVariable("ptr1", makeBytePointerType(), VariableKind.PARAMETER),
            makeVariable("ptr2", makeBytePointerType(), VariableKind.PARAMETER),
            makeVariable("num", makeSimpleType(TypeKind.LONG), VariableKind.PARAMETER)
        ]);
        state.mod.add(memcmp);
    }
}
