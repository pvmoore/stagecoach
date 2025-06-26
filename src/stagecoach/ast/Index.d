module stagecoach.ast.Index;

import stagecoach.all;

/**
 * Index
 *     Expression    index
 *     Expression    array | ptr
 */
final class Index : Expression {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.INDEX; }
    override bool isResolved() { return expr().isResolved() && index().isResolved(); }

    // Statement
    override Type getType() { 
        Type t = expr().getType(); 
        if(!t.isResolved()) return t;

        if(t.isArrayType()) {
            return t.as!ArrayType.elementType();
        }
        if(t.isPointer()) {
            return t.as!PointerType.valueExpr().getType();
        }
        return makeUnknownType();
    }

    // Expression
    override int precedence() { return Precedence.INDEX; }

    Expression expr() { return last().as!Expression; }
    Expression index() { return first().as!Expression; }

    bool isArrayIndex() { return expr().getType().isArrayType(); }
    bool isPointerIndex() { return expr().getType().isPointer(); }

    override string toString() {
        string t = getType().isResolved() ? " %s".format(getType()) : "UNRESOLVED";
        return "[index]%s".format(t);
    }
}
