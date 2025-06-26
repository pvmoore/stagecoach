module stagecoach.ast.If;

import stagecoach.all;

/**
 * If
 *    Expression    // condition
 *    { Statement } // then branch
 *    { Statement } // else branch (optional)
 */
final class If : Expression {
public:
    this() {
        _type = makeUnknownType();
    }
    int numThenStatements;
    bool hasElse;

    // Node
    override NodeKind nodeKind() { return NodeKind.IF; }
    override bool isResolved() { return _type.isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression condition() { return first().as!Expression; }
    Statement[] thenStatements() { return children[1..numThenStatements+1].map!(v=>v.as!Statement).array; }
    Statement[] elseStatements() { return children[1+numThenStatements..$].map!(v=>v.as!Statement).array; }

    bool isExpression() { return !parent.isA!Function; }

    Type thenType() { 
        if(auto e = lastThenStatement()) return e.getType(); 
        return makeUnknownType();
    }
    Type elseType() { 
        if(auto e = lastElseStatement()) return e.getType(); 
        return makeUnknownType(); 
    }

    Statement lastThenStatement() {

        // If this is an if expression then there should be at least one 'then' statement which will be 
        // checked later but for now we can just return null
        if(numThenStatements == 0) return null;

        if(Statement st = thenStatements().last().as!Statement) {
            return st;
        }
        return null;
    }

    Statement lastElseStatement() {

        // If this is an if expression then there should be at least one 'else' statement which will be 
        // checked later but for now we can just return null.
        // For now we will require an if expression to have both a 'then' and an 'else' branch
        // but we could possibly return an optional as the Type instead
        if(elseStatements().length == 0) return null;

        if(Statement st = elseStatements().last().as!Statement) {
            return st;
        }
        return null;
    }

    bool thenBlockReturns() {
        if(auto s = lastThenStatement()) {
            return s.isA!Return;
        }
        return false;
    }
    bool elseBlockReturns() {
        if(auto s = lastElseStatement()) {
            return s.isA!Return;
        }
        return false;
    }

    void setType(Type type) {
        this._type = type;
    }

    override string toString() {
        string[] info;
        if(!isExpression()) info ~= "stmt";
        if(!isResolved()) info ~= "UNRESOLVED"; else info ~= "%s".format(_type);
        info ~= "then: %s".format(numThenStatements);
        info ~= "else: %s".format(numChildren()-(1+numThenStatements));
        return "if %s".format(info.join(", "));
    }
private:
    Type _type;
}

If makeIf(Expression condition, Statement[] thenStmts, Statement[] elseStmts) {
    auto i = makeNode!If(0);
    i.add(condition);
    i.numThenStatements = thenStmts.length.as!int;
    i.hasElse = elseStmts.length > 0;
    i.addAll(thenStmts);
    i.addAll(elseStmts);
    return i;
}
