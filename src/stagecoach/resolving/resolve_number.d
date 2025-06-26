module stagecoach.resolving.resolve_number;

import stagecoach.all;
import std.conv     : to;
import std.string   : toLower;

/**
 * true
 * false
 * 
 * 123      (int)
 * 123L
 *
 * 0x123    (ubyte)
 * 0b101010 (ubyte)
 *
 * 123.4    (float)
 * 123d     (double)
 *
 * 123.4e5  *todo
 * 
 * 'c', '\n', '\x12', '\u1234', '\U12345678' (uint)  we will turn chars into uint 
 */
void resolveNumber(Number n, ResolveState state) {

    if("true" == n.stringValue) {
        n.value.byteValue = -1;
        n.setType(makeBoolType());
        return;
    }
    if("false" == n.stringValue) {
        n.value.byteValue = 0;
        n.setType(makeBoolType());
        return;
    }


    // Check for a character literal
    if(n.stringValue[0] == '\'') {
        resolveChar(n, state);
        return;
    }

    string s = n.stringValue.toLower();

    if(s.contains(".") || s.endsWith("d")) {
        resolveReal(n, s);
    } else {
        resolveInteger(n, s);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void resolveReal(Number n, string s) {
    bool isDouble = false;

    if(s.endsWith("d")) {
        s = s[0..$-1];
        isDouble = true;
    }

    if(isDouble) {
        n.setType(makeDoubleType());
    } else {
        n.value.floatValue = s.to!float;
        n.setType(makeFloatType());
    }
}

void resolveInteger(Number n, string s) {
    uint size = 1;          

    if(s.endsWith("l")) {
        size = 8;
        s = s[0..$-1];
    }

    if(s.startsWith("0x")) {
        s = s[2..$];
        if(s.length > 8) {
            size = 8;
        } else if(s.length > 4) {
            size = maxOf(size, 4);
        } else if(s.length > 2) {
            size = maxOf(size, 2);
        } else {
            size = maxOf(size, 1);
        }
        s = s.to!ulong(16).to!string;

    } else if(s.startsWith("0b")) {
        s = s[2..$];
        if(s.length > 32) {
            size = 8;
        } else if(s.length > 16) {
            size = maxOf(size, 4);
        } else if(s.length > 8) {
            size = maxOf(size, 2);
        } else {
            size = maxOf(size, 1);
        }
        s = s.to!ulong(2).to!string;
    }

    // Make sure size is large enough to hold the value
    if(s.startsWith("-")) {
        long v = s.to!long;
        if(v < int.min || v > int.max) size = maxOf(size, 8);
        else if(v < short.min || v > short.max) size = maxOf(size, 4);
        else if(v < byte.min || v > byte.max) size = maxOf(size, 2);
    } else {
        ulong v = s.to!long;
        if(v < uint.min || v > uint.max) size = maxOf(size, 8);
        else if(v < ushort.min || v > ushort.max) size = maxOf(size, 4);
        else if(v < ubyte.min || v > ubyte.max) size = maxOf(size, 2);
    }
    //log("number %s (%s, %s) size = %s", s, s.to!long, s.to!long.as!ulong, size);

    TypeKind tk;
    switch(size) {
        case 1: n.value.byteValue = s.to!long.as!byte; tk = TypeKind.BYTE; break;
        case 2: n.value.shortValue = s.to!long.as!short; tk = TypeKind.SHORT; break;
        case 4: n.value.intValue = s.to!long.as!int; tk = TypeKind.INT; break;
        case 8: n.value.longValue = s.to!long; tk = TypeKind.LONG; break;
        default: assert(false);
    }
    n.setType(makeSimpleType(tk));
}

void resolveChar(Number n, ResolveState state) {
    auto t = state.resolveChar(n, n.stringValue[1..$-1]);
    n.value.intValue = t[0];
    n.setType(makeIntType());
}
