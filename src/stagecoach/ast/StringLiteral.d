module stagecoach.ast.StringLiteral;

import stagecoach.all;

/**
 * StringLiteral
 */
final class StringLiteral : Expression {
public:
    string stringValue;
    bool isCString;
    LLVMValueRef llvmValue;

    this() {
        this._type = makeBytePointerType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.STRING_LITERAL; }
    override bool isResolved() { return resolveEvaluated; }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }


    override string toString() {
        string[] info;
        info ~= isCString ? "cstr" : "string";
        info ~= isResolved() ? "%s".format(_type.shortName()) : "UNRESOLVED";
        string s = stringValue.replace("%", "%%")
                              .replace("\\", "\\\\")
                              .replace(10, "\\n");
        if(s.length > 16) s = s[0..16] ~ "...";                      
        return "\"%s\" %s".format(s, info.join(", "));
    }
private:
    Type _type;
}

StringLiteral makeStringLiteral(string value, bool isCStr) {
    auto s = makeNode!StringLiteral(0);
    s.stringValue = value;
    s.isCString = isCStr;
    return s;
}
