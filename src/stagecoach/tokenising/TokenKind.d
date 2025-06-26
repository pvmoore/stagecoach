module stagecoach.tokenising.TokenKind;

import stagecoach.all;

enum TokenKind {
    NONE,
    IDENTIFIER,
    NUMBER,
    STRING,

    PLUS,               // +
    MINUS,              // -
    STAR,               // *
    SLASH,              // /
    PERCENT,            // %
    HAT,                // ^
    AMPERSAND,          // &
    PIPE,               // |
    TILDE,              // ~
    LANGLE2,            // <<
    RANGLE2,            // >>

    EQUAL,              // =

    PLUS_EQUAL,         // +=
    MINUS_EQUAL,        // -=
    STAR_EQUAL,         // *=
    SLASH_EQUAL,        // /=
    PERCENT_EQUAL,      // %=
    HAT_EQUAL,          // ^=
    AMPERSAND_EQUAL,    // &=
    PIPE_EQUAL,         // |=
    TILDE_EQUAL,        // ~=
    LANGLE2_EQUAL,      // <<=
    RANGLE2_EQUAL,      // >>=

    LANGLE_EQUAL,       // <=
    RANGLE_EQUAL,       // >=
    EQUAL2,             // ==
    BANG_EQUAL,         // !=

    LANGLE,             // <
    RANGLE,             // >
    LPAREN,             // (
    RPAREN,             // )
    LBRACE,             // {
    RBRACE,             // }
    LSQUARE,            // [
    RSQUARE,            // ]

    BANG,               // !    
    RARROW,             // ->   

    DOT,                // .
    COMMA,              // ,
    COLON,              // :
    COLON2,             // ::
    SEMICOLON,          // ;

    ELLIPSIS,           // ...
    
    QUESTION,           // ?
    AT,                 // @
    HASH,               // #
    DOLLAR,             // $
}
int lengthOf(TokenKind t) {
    final switch(t) with(TokenKind) {
        case NONE:
        case IDENTIFIER: 
        case NUMBER: 
        case STRING: 
            return 0;
        case PLUS:
        case MINUS:        
        case STAR:     
        case SLASH:        
        case PERCENT:      
        case HAT:        
        case AMPERSAND:    
        case PIPE:         
        case TILDE:        
        case EQUAL:        
        case LANGLE:         
        case RANGLE:
        case LPAREN:     
        case RPAREN:     
        case LBRACE:       
        case RBRACE:       
        case LSQUARE:  
        case RSQUARE:  
        case DOT:          
        case COMMA:        
        case COLON:        
        case SEMICOLON:
        case BANG:
        case QUESTION:
        case AT:
        case HASH:
        case DOLLAR:
            return 1;
        case PLUS_EQUAL:  
        case MINUS_EQUAL: 
        case STAR_EQUAL:
        case SLASH_EQUAL:
        case PERCENT_EQUAL:
        case HAT_EQUAL:
        case AMPERSAND_EQUAL:
        case PIPE_EQUAL:
        case TILDE_EQUAL:
        case LANGLE_EQUAL:   
        case RANGLE_EQUAL:
        case EQUAL2:  
        case BANG_EQUAL:    
        case LANGLE2:
        case RANGLE2:
        case RARROW:
        case COLON2:
            return 2;
        case LANGLE2_EQUAL:
        case RANGLE2_EQUAL:
        case ELLIPSIS:
            return 3;
    }
}
string stringOf(TokenKind t) {
    final switch(t) with(TokenKind) {
        case NONE:
        case IDENTIFIER:
        case NUMBER:
        case STRING:
            return "";
        case PLUS: return "+";
        case MINUS: return "-";
        case STAR: return "*";
        case SLASH: return "/";
        case PERCENT: return "%";
        case HAT: return "^";
        case AMPERSAND: return "&";
        case PIPE: return "|";
        case TILDE: return "~";
        case LANGLE2: return "<<";
        case RANGLE2: return ">>";
        case PLUS_EQUAL: return "+=";
        case MINUS_EQUAL: return "-=";
        case STAR_EQUAL: return "*=";
        case SLASH_EQUAL: return "/=";
        case PERCENT_EQUAL: return "%=";
        case HAT_EQUAL: return "^=";
        case AMPERSAND_EQUAL: return "&=";
        case PIPE_EQUAL:  return "|=";
        case TILDE_EQUAL: return "~=";
        case LANGLE2_EQUAL: return "<<=";
        case RANGLE2_EQUAL: return ">>=";
        case EQUAL: return "=";
        case LANGLE: return "<";
        case RANGLE: return ">";
        case LANGLE_EQUAL: return "<=";
        case RANGLE_EQUAL: return ">=";
        case EQUAL2: return "==";
        case BANG_EQUAL: return "!=";
        case LPAREN: return "(";
        case RPAREN: return ")";
        case LBRACE: return "{";
        case RBRACE: return "}";
        case LSQUARE: return "[";
        case RSQUARE: return "]";
        case RARROW: return "->";   
        case DOT: return ".";
        case COMMA: return ",";
        case COLON: return ":";
        case SEMICOLON: return ";";
        case ELLIPSIS: return "...";
        case BANG: return "!";
        case COLON2: return "::";
        case QUESTION: return "?";
        case AT: return "@";
        case HASH: return "#";
        case DOLLAR: return "$";
    }   
}
