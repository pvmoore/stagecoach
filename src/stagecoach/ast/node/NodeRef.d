module stagecoach.ast.node.NodeRef;

import stagecoach.all;

/**
 * NodeRef
 *
 * Used to reference another Node in the AST.
 */
final class NodeRef : Expression {
public:
    Expression node;

    // Node
    override NodeKind nodeKind() { return NodeKind.NODE_REF; }
    override bool isResolved() { return node.isResolved(); }

    // Statement
    override Type getType() { return node.getType(); }

    // Expression
    override int precedence() { return node.precedence(); }

    override string toString() {
        return "NodeRef %s".format(node.nodeKind());
    }
}   

Number extractNumber(Node n) {
    if(n.isA!Number) return n.as!Number;
    if(NodeRef nr = n.as!NodeRef) return extractNumber(nr.node);
    return null;
}

Identifier extractIdentifier(Node n) {
    if(n.isA!Identifier) return n.as!Identifier;
    if(NodeRef nr = n.as!NodeRef) return extractIdentifier(nr.node);
    return null;
}
