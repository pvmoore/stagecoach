module stagecoach.errors.error_utils;

import stagecoach.all;

string getLocationString(Statement stmt) {
    Module mod = stmt.getModule();
    Project project = mod.project;
    Token token = stmt.startToken;
    int line = token.line;
    int column = token.column;
    return "%s%s(%s,%s)".format(project.directory, mod.relFilename, line+1, column+1);
}

string formatErrorMessage(Module mod, string message, int line, int column) {
    Token[] tokens = getTokensOnLine(mod, line);
    string lineStr = "%s".format(line+1);
    string ss = repeatStr("─", lineStr.length);
    string formatted;

    string fmt(string ansiCode, string str) {
        return ansiCode ~ str ~ Ansi.RESET;
    }

    formatted ~= "├─" ~ ss ~ "─┼──────────────────────────────────────────────────────────\n";
    formatted ~= "│ " ~fmt(Ansi.WHITE_BOLD, lineStr) ~ " │ ";

    foreach(i, t; tokens) {
        string colour = Ansi.WHITE;
        if(t.column == column) {
            colour = Ansi.YELLOW_BOLD;
        } else if(t.kind == TokenKind.IDENTIFIER && t.text in KEYWORDS) {
            colour = Ansi.BLUE;
        } 
        formatted ~= fmt(colour, t.text);

        if(i+1 < tokens.length) {
            auto gap = tokens[i+1].column - (t.column + t.text.length);
            gap = minOf(gap, 10);
            foreach(j; 0..gap) formatted ~= " ";
        }
    }

    formatted ~= "\n";
    formatted ~= "├─" ~ ss ~ "─┼──────────────────────────────────────────────────────────\n";
    formatted ~= fmt(Ansi.RED_BOLD, "Error: ") ~ message;
    formatted ~= "\n";

    return formatted;
}

Token[] getTokensOnLine(Module mod, int line) {
    return mod.tokens.filter!(t => t.line == line).array;
}
string highlightKeywords(string source) {

    return source;
}


__gshared bool[string] KEYWORDS = [
    "bool":true,
    "byte":true,
    "int":true,
    "long":true,
    "short":true,
    "ubyte":true,
    "uint":true,
    "ulong":true,
    "ushort":true,
    "float":true,
    "double":true,
    "void":true,
    "struct":true,
    "enum":true,
    "union":true,

    "as":true,
    "if":true,
    "is":true,
    "fn":true,
    "return":true,
    "import":true,
    "true":true,
    "false":true,
    "null":true,
    "not":true,
    "and":true,
    "or":true,
    "const":true,
    "extern":true,
    "alias":true,
    "assert":true,
    "public":true,
    "private":true
];
