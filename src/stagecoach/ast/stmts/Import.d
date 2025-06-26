module stagecoach.ast.stmts.Import;

import stagecoach.all;

/**
 * Import
 *     Expression
 */
final class Import : Statement {
public:
    this() {
        _type = makeVoidType();
    }

    string name;            // optional
    Module fromModule;      // The module we are importing from

    // Node
    override NodeKind nodeKind() { return NodeKind.IMPORT; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return _type; }

    override string toString() {
        string m = fromModule ? fromModule.name : "UNRESOLVED";
        return "import %s".format(m);
    }
private:
    Type _type;
}
