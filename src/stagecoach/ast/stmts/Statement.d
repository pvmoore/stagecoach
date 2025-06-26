module stagecoach.ast.stmts.Statement;

import stagecoach.all;

abstract class Statement : Node {
public:
    int tokenIndex;
    bool resolveEvaluated;

    abstract Type getType();

    Token startToken() { return getModule().tokens[tokenIndex]; }
    
protected:    
}
