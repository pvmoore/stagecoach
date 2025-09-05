module stagecoach.ast.node.NodeKind;

import stagecoach.all;

enum NodeKind {
    // Nodes
    ADDRESS_OF,
    ALIAS,
    ARRAY_LITERAL,
    AS,
    ASSERT,
    BINARY,
    BUILTIN,
    CALL,
    DOT,
    ENUM,
    ENUM_MEMBER,
    FUNCTION,
    IDENTIFIER,
    IF,
    INDEX,
    IS,
    MODULE,
    MODULE_REF,
    NODE_REF,
    NUMBER,
    PARENS,
    RETURN,
    STRING_LITERAL,
    STRUCT_LITERAL,
    NULL,
    UNARY,
    VALUE_OF,
    VARIABLE,

    // Types
    ARRAY_TYPE,
    BASIC_TYPE,
    POINTER_TYPE,
    STRUCT,
    TYPE_OF,
    TYPE_REF,
}
