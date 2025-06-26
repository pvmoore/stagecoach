module stagecoach.ast.Builtin;

import stagecoach.all;

/**
 * Builtin
 *     { Expression }  arguments
 *
 *
 * @assert Expression [ ',' "message" ]  --> rewrite to call to @assert(condition, moduleName, line)
 * @debug(Expression)
 * @isVoid(Expression)      
 * @isPointer(Expression)   
 * @isValue(Expression)     
 * @isArray(Expression)     
 * @isFunction(Expression)  
 * @isEnum(Expression)      
 * @isStruct(Expression)    
 * @isPacked(Type)         
 * @isPublic(Expression)    
 * @isInteger(Expression)   
 * @isReal(Expression)      
 * @isBool(Expression)      
 * @sizeOf(Expression)      
 * @alignOf(Expression)     
 * @offsetOf(Expression)   
 * @isConst(Expression)
 *
 * @initOf(Expression)      *todo
 * @isUnion(Expression)     *todo
 */
final class Builtin : Expression {
public:
    this() {
        _type = makeUnknownType();
    }

    string name;

    override NodeKind nodeKind() { return NodeKind.BUILTIN; }
    override bool isResolved() { return false; }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.CALL; }

    Expression[] arguments() { return children.map!(v=>v.as!Expression).array; }

    override string toString() {
        return "Builtin %s".format(name);
    }
private:
    Type _type;
}

