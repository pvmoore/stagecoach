module stagecoach.ast.Number;

import stagecoach.all;

/**
 * Number
 */
final class Number : Expression {
public:
    string stringValue;
    Value_T value;

    static union Value_T {
        byte byteValue;
        short shortValue;
        int intValue;
        long longValue;
        float floatValue;
        double doubleValue;
    }

    this() {
        _type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.NUMBER; }
    override bool isResolved() { return _type.isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    bool isZero() {
        switch(_type.typeKind()) {
            case TypeKind.BYTE:   return value.byteValue == 0;
            case TypeKind.SHORT:  return value.shortValue == 0;
            case TypeKind.INT:    return value.intValue == 0;
            case TypeKind.LONG:   return value.longValue == 0;
            case TypeKind.FLOAT:  return value.floatValue == 0.0;
            case TypeKind.DOUBLE: return value.doubleValue == 0.0;
            default: assert(false);
        }
        assert(false);  
    }

    void setType(Type type) { this._type = type; }
    
    override string toString() {
        string[] info;
        if(!isResolved()) info ~= "UNRESOLVED"; else info ~= "%s".format(_type);
        return "%s %s".format(stringValue, info.join(", "));
    }

    bool getValueAsBool() {
        switch(_type.typeKind()) {
            case TypeKind.BYTE:   return value.byteValue != 0;
            case TypeKind.SHORT:  return value.shortValue != 0;
            case TypeKind.INT:    return value.intValue != 0;
            case TypeKind.LONG:   return value.longValue != 0;
            case TypeKind.FLOAT:  return value.floatValue != 0.0;
            case TypeKind.DOUBLE: return value.doubleValue != 0.0;
            default: assert(false);
        }
    }
    int getValueAsInt() {
        switch(_type.typeKind()) {
            case TypeKind.BYTE:   return value.byteValue;
            case TypeKind.SHORT:  return value.shortValue;
            case TypeKind.INT:    return value.intValue;
            case TypeKind.LONG:   return value.longValue.as!int;
            case TypeKind.FLOAT:  return value.floatValue.as!int;
            case TypeKind.DOUBLE: return value.doubleValue.as!int;
            default: assert(false);
        }
    }
    double getValueAsDouble() {
        switch(_type.typeKind()) {
            case TypeKind.BYTE:   return value.byteValue;
            case TypeKind.SHORT:  return value.shortValue;
            case TypeKind.INT:    return value.intValue;
            case TypeKind.LONG:   return value.longValue;
            case TypeKind.FLOAT:  return value.floatValue;
            case TypeKind.DOUBLE: return value.doubleValue;
            default: assert(false);
        }
    }
    void setValue(int v) {
        stringValue = "%s".format(v);
        switch(_type.typeKind()) {
            case TypeKind.BYTE:   value.byteValue = v.as!byte; break;
            case TypeKind.SHORT:  value.shortValue = v.as!short; break;
            case TypeKind.INT:    value.intValue = v; break;
            case TypeKind.LONG:   value.longValue = v.as!long; break;
            case TypeKind.FLOAT:  value.floatValue = v.as!float; break;
            case TypeKind.DOUBLE: value.doubleValue = v.as!double; break;
            default: assert(false);
        }   
    }
private:
    Type _type;
}

Number makeBoolNumber(bool b) {
    auto n = makeNode!Number(0);
    n.stringValue = b ? "true" : "false";
    n.value.byteValue = b ? -1 : 0;
    n.setType(makeBoolType());
    return n;
}
Number makeIntNumber(int value) {
    auto n = makeNode!Number(0);
    n.stringValue = "%s".format(value);
    n.value.intValue = value;
    n.setType(makeIntType());
    return n;
}
Number makeLongNumber(long value) {
    auto n = makeNode!Number(0);
    n.stringValue = "%s".format(value);
    n.value.longValue = value;
    n.setType(makeLongType());
    return n;
}
Number makeRealNumber(double value, Type type) {
    auto n = makeNode!Number(0);
    n.stringValue = "%.8f".format(value);
    n.value.doubleValue = value;
    n.setType(type);
    return n;
}
