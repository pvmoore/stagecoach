module stagecoach.tokenising.Token;

import stagecoach.all;

immutable Token NO_TOKEN = Token(TokenKind.NONE, null, 0, 0);

struct Token {
    TokenKind kind;
    string text;

    uint line;
    uint column;

    string toString() { return "Token(%s '%s' %s:%s)".format(kind, text, line, column); }
}

Token makeToken(TokenKind kind, string text, uint line, uint column) {
    return Token(kind, text, line, column);
}
