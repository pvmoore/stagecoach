module stagecoach.ast.As;

import stagecoach.all;

/**
 * As
 *     Expression
 *     Type
 */
final class As : Expression {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.AS; }
    override bool isResolved() { return resolveEvaluated && expr().isResolved() && toType().isResolved(); }

    // Statement
    override Type getType() { return rightType(); }

    // Expression
    override int precedence() { return Precedence.AS; }

    Expression expr() { return first().as!Expression; }
    Expression toType() { return last().as!Expression; }

    Type leftType() { return expr().getType(); }
    Type rightType() { return toType().getType(); }

    override string toString() {
        string u = isResolved() ? "%s".format(rightType().shortName()) : "UNRESOLVED";
        return "as %s".format(u);
    }
}

As makeAs(Expression expr, Type toType) {
    auto a = makeNode!As(0);
    a.add(expr);
    a.add(toType);
    return a;
}
