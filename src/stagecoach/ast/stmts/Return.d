module stagecoach.ast.stmts.Return;

import stagecoach.all;

/**
 * Return 
 *    [ Expression ] 
 */
final class Return : Statement {
public:
    this() {
        _type = makeVoidType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.RETURN; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return hasChildren() ? expr().getType() : _type; }

    Expression expr() { assert(hasChildren); return first().as!Expression; }
    Function func() { return getAncestor!Function(); }

    override string toString() {
        return "return";
    }
private:
    Type _type;
}
