module stagecoach.ast.ValueOf;

import stagecoach.all;

/**
 * ValueOf
 *     Expression
 */
final class ValueOf : Expression {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.VALUE_OF; }
    override bool isResolved() { return expr().isResolved(); }

    // Statement
    override Type getType() { 
        PointerType ptr = expr().getType().as!PointerType;
        if(ptr) return ptr.valueType();
        return makeUnknownType(); 
    }

    // Expression
    override int precedence() { return Precedence.VALUE_OF; }

    Expression expr() { return first().as!Expression; }

    override string toString() {
        return "ValueOf %s".format(getType());
    }
}

ValueOf makeValueOf(Expression expr) {
    auto v = makeNode!ValueOf(0);
    v.add(expr);
    return v;
}
