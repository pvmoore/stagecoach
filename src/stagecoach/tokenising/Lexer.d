module stagecoach.tokenising.Lexer;

import stagecoach.all;

final class Lexer {
public:
    this(Module mod, string source) {
        this.mod = mod;
        this.source = source;
    }
    Token[] tokenise() {
        while(pos < source.length) {
            char ch = peek();
            //log("ch = %s", ch);

            if(ch < 33) {
                lexWhitespace();
            } else switch(ch) {
                case '"':
                    lexString();
                    break;
                case '\'':
                    lexChar();
                    break;
                case '/':
                    if(peek(1)=='/') {
                        lexLineComment();
                    } else if(peek(1)=='*') {
                        lexMultiLineComment();
                    } else if(peek(1)=='=') {
                        addToken(TokenKind.SLASH_EQUAL);
                    } else {
                        addToken(TokenKind.SLASH);
                    }
                    break;
                case '+': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.PLUS_EQUAL);
                    } else {
                        addToken(TokenKind.PLUS);
                    } 
                    break;
                case '-': 
                    if(tokenStart==pos && peek(1).isDigit()) {
                        // This is a negative number
                        pos++;
                        break;
                    }
                    if(peek(1) == '=') {
                        addToken(TokenKind.MINUS_EQUAL);
                    } else if(peek(1) == '>') {
                        addToken(TokenKind.RARROW); 
                    } else {
                        addToken(TokenKind.MINUS);
                    }                    
                    break;
                case '*': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.STAR_EQUAL);
                    } else {
                        addToken(TokenKind.STAR);
                    }
                    break;
                case '%': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.PERCENT_EQUAL);
                    } else {
                        addToken(TokenKind.PERCENT);
                    } 
                    break;
                case '^': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.HAT_EQUAL);
                    } else {
                        addToken(TokenKind.HAT);
                    }
                    break;
                case '&': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.AMPERSAND_EQUAL);
                    } else {
                        addToken(TokenKind.AMPERSAND);
                    }
                    break;
                case '|': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.PIPE_EQUAL);
                    } else {
                        addToken(TokenKind.PIPE);
                    }
                    break;
                case '~': 
                    if(peek(1) == '=') {
                        addToken(TokenKind.TILDE_EQUAL);
                    } else {
                        addToken(TokenKind.TILDE);
                    }
                    break;

                case '(': addToken(TokenKind.LPAREN); break;
                case ')': addToken(TokenKind.RPAREN); break;
                case '{': addToken(TokenKind.LBRACE); break;
                case '}': addToken(TokenKind.RBRACE); break;
                case '[': addToken(TokenKind.LSQUARE); break;
                case ']': addToken(TokenKind.RSQUARE); break;

                case ';': addToken(TokenKind.SEMICOLON); break;
                case ',': addToken(TokenKind.COMMA); break;
                case '?': addToken(TokenKind.QUESTION); break;
                //case '@': addToken(TokenKind.AT); break;
                case '#': addToken(TokenKind.HASH); break;
                case '$': addToken(TokenKind.DOLLAR); break;

                case ':': 
                    if(peek(1)==':') {
                        addToken(TokenKind.COLON2);
                    } else {
                        addToken(TokenKind.COLON); 
                    }
                    break;
                case '.': 
                    if(isDigit(peek(-1)) && isDigit(peek(1))) {
                        // Assume this is a real number
                        pos++;
                    } else if(peek(1)=='.' && peek(2)=='.') {
                        addToken(TokenKind.ELLIPSIS);
                    } else {
                        addToken(TokenKind.DOT); 
                    }
                    break;

                case '!': 
                    if(peek(1)=='=') {
                        addToken(TokenKind.BANG_EQUAL);
                    } else {
                        addToken(TokenKind.BANG);
                    } 
                    break;
                case '=': 
                    if(peek(1)=='=') {
                        addToken(TokenKind.EQUAL2);
                    } else {
                        addToken(TokenKind.EQUAL);
                    } 
                    break;
                case '<': 
                    if(peek(1)=='=') {
                        addToken(TokenKind.LANGLE_EQUAL);
                    } else if(peek(1) == '<' && peek(2)=='=') {
                        addToken(TokenKind.LANGLE2_EQUAL);
                    } else if(peek(1)=='<') {
                        addToken(TokenKind.LANGLE2);
                    } else {
                        addToken(TokenKind.LANGLE); 
                    }
                    break;
                case '>': 
                    if(peek(1)=='=') {
                        addToken(TokenKind.RANGLE_EQUAL);
                    } else if(peek(1) == '>' && peek(2)=='=') {
                        addToken(TokenKind.RANGLE2_EQUAL);
                    } else if(peek(1)=='>') {
                        addToken(TokenKind.RANGLE2);
                    } else {
                        addToken(TokenKind.RANGLE); 
                    }
                    break;

                default: 
                    pos++;
                    break;
            }
        }
        addToken();

        return tokens;
    }
private:
    Module mod;
    string source;
    int pos;
    int line;
    int tokenStart;
    int lineStart;
    Token[] tokens;

    char peek(int offset = 0) {
        return pos + offset < source.length ? source[pos + offset] : 0;
    }
    void addToken(TokenKind tk = TokenKind.NONE) {
        if(pos > tokenStart) {
            string text = source[tokenStart..pos];
            int column  = tokenStart - lineStart;
            
            // Identify the token type
            auto tk2 = TokenKind.IDENTIFIER;
            char ch1 = text[0];
            char ch2 = text.length > 1 ? text[1] : 0;
            if(ch1 == '\'') tk2 = TokenKind.NUMBER;
            else if(ch1 == '"') tk2 = TokenKind.STRING;
            else if(isDigit(ch1) || (ch1=='-' && isDigit(ch2)) || (ch1=='.' && isDigit(ch2))) tk2 = TokenKind.NUMBER;
        
            tokens ~= Token(tk2, text, line, column);
        }
        if(tk != TokenKind.NONE) {
            int len = lengthOf(tk);
            string text = source[pos..pos+len];
            int column  = pos - lineStart;

            tokens ~= Token(tk, text, line, column); 
            pos += len;
        }
        // Reset the token start position
        tokenStart = pos;
    }
    bool isEol() {
        return peek().isOneOf(10, 13);
    }
    void eol() {
        // can be 13,10 or just 10
        if(peek()==13) pos++;
        if(peek()==10) pos++;
        line++;
        lineStart = pos;
    }
    /**
     *  "sdfsdfs\"df\nsdf"      string struct (*todo)
     *  "sdfsdfs\"df\nsdf"z     zero terminated byte*
     */
    void lexString() {
        addToken();
        assert(peek()=='"');
        pos++;
        while(pos < source.length) {
            if(peek()=='"') {
                break;
            } else if(peek()=='\\' && peek(1)=='"') {
                pos+=2;
            } else {
                pos++;
            }
        }
        assert(peek()=='"');
        pos++;

        if(peek()=='z') {
            pos++;
        }
        addToken();
    }
    /** 
     *  's' | '\n' | '\\'
     */
    void lexChar() {
        addToken();
        assert(peek()=='\'');

        if(peek(1)=='\'') {
            syntaxError(mod, line, pos - lineStart, "Empty character literal");
        }

        pos++;
        if(peek()=='\\') {
            pos+=2;
        } else {
            pos++;
        }
        assert(peek()=='\'');
        pos++;
        addToken();
    }
    void lexWhitespace() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek() < 33) {
                pos++;
            } else {
                break;
            }
        }
        tokenStart = pos;
    }
    void lexLineComment() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
                break;
            }
            pos++;
        }
        tokenStart = pos;
    }
    void lexMultiLineComment() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek()=='*' && peek(1)=='/') {
                pos+=2;
                break;
            } else {
                pos++;
            }
        }
        tokenStart = pos;
    }
}
