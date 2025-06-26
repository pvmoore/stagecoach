module stagecoach.ast.AddressOf;

import stagecoach.all;

/**
 * AddressOf
 *     Expression
 */
final class AddressOf : Expression {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.ADDRESS_OF; }
    override bool isResolved() { return resolveEvaluated && expr().isResolved(); }

    // Statement
    override Type getType() { return makeOrReuseType(); }

    // Expression
    override int precedence() { return Precedence.ADDRESS_OF; }

    Expression expr() { return first().as!Expression; }

    void setResolveEvaluated() { resolveEvaluated = true; }

    override string toString() {
        return "AddressOf %s".format(getType());
    }
private:
    PointerType _type;

    Type makeOrReuseType() {
        if(_type) {
            if(TypeRef fr = _type.valueType().as!TypeRef) {
                if(fr.type is expr().getType()) {
                    return _type;
                }
            }
        }

        this._type = makePointerTypeWithChild(makeTypeRef(expr().getType())); 
        return _type;
    }
}

AddressOf makeAddressOf(Expression expr) {
    auto a = makeNode!AddressOf(0);
    a.add(expr);
    return a;
}
