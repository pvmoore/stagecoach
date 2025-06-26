module stagecoach.ast.types.TypeKind;

import stagecoach.all;

enum TypeKind {
    UNKNOWN,

    // C varargs (special type valid only on extern function parameters)
    C_VARARGS,  

    ARRAY,
    FUNCTION,
    POINTER,
    VOID,
    STRUCT,
    ENUM,

    // Boolean type (implemented as a byte)
    BOOL,

    // Integer types
    BYTE,
    SHORT,
    INT,
    LONG,

    // Real types
    FLOAT,
    DOUBLE
}
