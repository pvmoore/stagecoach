module stagecoach.parsing.ParseState;

import stagecoach.all;

final class ParseState {
public:
    int pos;
    Module mod;
    Token[] tokens;
    Project project;
    Attributes attributes;
    bool insidePublicScopeModule;
    bool insidePublicScopeStruct;
    
    this(Project project, Module mod) {
        this.project = project;
        this.mod = mod;
        this.tokens = mod.tokens;
        this.attributes = new Attributes;
    }

    bool hasAttribute(string name) {
        return attributes.hasAttribute(name);
    }
    Attribute getAttribute(string name) {
        return attributes.getAttribute(name);
    }

    bool eof() {
        return pos >= tokens.length;
    }
    Token token(int offset = 0) {
        return peek(offset);
    }
    TokenKind tokenKind(int offset = 0) {
        return token(offset).kind;
    }
    string text(int offset = 0) {
        return token(offset).text;
    }
    uint line() {
        return token().line;
    }
    Token peek(int offset) {
        return pos + offset >= tokens.length ? NO_TOKEN : tokens[pos + offset];
    }
    auto next() {
        pos++;
        return this;
    }
    auto skip(string t) {
        if(text() != t) {
            syntaxError(mod, token(), "Expected %s but found %s".format(t, text()));
        }
        return next();
    }
    auto skip(TokenKind tk) {
        if(token().kind != tk) {
            string found = token().kind.stringOf();
            if(found.length == 0) found = text();
            syntaxError(mod, token(), "Expected %s but found %s".format(tk.stringOf(), found));
        }
        return next();
    }
    void skipSemicolons() {
        while(tokenKind() == TokenKind.SEMICOLON) {
            skip(TokenKind.SEMICOLON);
        }
    }
    bool isOnSameLine(int offset = 0) {
        return token(offset).line == peek(offset-1).line;
    }
    bool matches(int offset, TokenKind[] tk...) {
        foreach(t; tk) {
            if(tokenKind(offset++) != t) return false;
        }
        return true;
    }
    /**
     * Find the offset of the closing bracket. Assumes the current token is the opening bracket. 
     * If the opening bracket is not found then returns -1.
     */
    int findOffsetOfClosing(int startOffset, TokenKind open, TokenKind close) 
        in(token(startOffset).kind == open)
        out(r; r == -1 || peek(r).kind == close)
    {
        int p = this.pos + startOffset;
        int depth = 0;
        while(p < tokens.length) {
            if(tokens[p].kind == open) {
                depth++;
            } else if(tokens[p].kind == close) {
                depth--;
                if(depth == 0) return p-pos;
            }
            p++;
        }
        return -1;
    }
    /**
     * Find the offset of tok within the current scope. Assumes the current token is the opening bracket. 
     * The current scope is defined as the tokens between the opening and closing bracket 
     * and excludes nested scopes.
     * If the opening bracket is not found then returns -1.
     */
    // int findWithinScope(TokenKind open, TokenKind close, TokenKind tok) 
    //     in(token().kind == open)
    //     out(r; r == -1 || peek(r).kind == tok)
    // {
    //     int p = this.pos;
    //     int depth = 0;
    //     while(p < tokens.length) {
    //         if(tokens[p].kind == open) {
    //             depth++;
    //         } else if(tokens[p].kind == close) {
    //             depth--;
    //             if(depth == 0) return -1;
    //         } else if(tokens[p].kind == tok) {
    //             if(depth == 1) return p-pos;
    //         }
    //         p++;
    //     }
    //     return -1;
    // }
private:
}
