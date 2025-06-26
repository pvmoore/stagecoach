module stagecoach.errors.CompilationError;

import stagecoach.all;
import stagecoach.errors.error_utils;
import stagecoach.errors.error_summary;
import stagecoach.errors.error_extra_info;

interface ErrorExtraInfo {}

final class StringErrorExtraInfo : ErrorExtraInfo { string msg; this(string msg) { this.msg = msg; } }

class CompilationError {
public:
    this(Module mod, Statement stmt, int line, int column, ErrorKind kind, ErrorExtraInfo extraInfo) {
        this.mod = mod;
        this.stmt = stmt;
        this.line = line;
        this.column = column;
        this.errorKind = kind;
        this.extraInfo = extraInfo;
    }
    ErrorKind kind() {
        return errorKind;
    }
    string getLocationString() {
        Project project = mod.project;
        return "%s%s(%s,%s)".format(project.directory, mod.relFilename, line+1, column+1);
    }
    string getSummary() {
        return getSummaryMessage(this);
    }
    string getPrettyString() {
        return formatErrorMessage(mod, getSummaryMessage(this), line, column);
    }
    string getExtraInfo() {
        return getExtraInfoMessage(this);
    }
    override bool opEquals(Object o) {
        if(CompilationError e = o.as!CompilationError) {
            return this.errorKind == e.errorKind && this.stmt is e.stmt;
        }
        return false;
    }
package:
    int line;
    int column;
    Statement stmt;
    ErrorKind errorKind;
    Module mod;
    ErrorExtraInfo extraInfo;
}

void warn(ParseState state, string msg) {
    consoleLog(ansiWrap("[%s:%s] Warning: %s".format(state.mod.relFilename, state.line()+1, msg), Ansi.YELLOW));
}
void warn(Statement n, string msg) {
    consoleLog(ansiWrap("[%s:%s] Warning: %s".format(n.getModule().relFilename, n.startToken.line+1, msg), Ansi.YELLOW));
}

void syntaxError(Module mod, int line, int column, string msg) {
    mod.project.addError(new CompilationError(mod, null, line, column, ErrorKind.SYNTAX, new StringErrorExtraInfo(msg)));
}
void syntaxError(ParseState state, string msg) {
    Token t = state.token();
    state.project.addError(new CompilationError(state.mod, null, t.line, t.column, ErrorKind.SYNTAX, new StringErrorExtraInfo(msg)));
}
void syntaxError(ParseState state, int offset, string msg) {
    Token t = state.peek(offset);
    state.project.addError(new CompilationError(state.mod, null, t.line, t.column, ErrorKind.SYNTAX, new StringErrorExtraInfo(msg)));
}
void syntaxError(Module mod, Token token, string msg) {
    mod.project.addError(new CompilationError(mod, null, token.line, token.column, ErrorKind.SYNTAX, new StringErrorExtraInfo(msg)));
}

void resolutionError(Node n, ErrorKind kind, ErrorExtraInfo extraInfo = null) {
    Token t = n.as!Statement.startToken;
    n.getProject().addError(new CompilationError(n.getModule(), n.as!Statement, t.line, t.column, kind, extraInfo));
}

void semanticError(Node n, ErrorKind kind, ErrorExtraInfo extraInfo = null) {
    semanticError(n.getProject(), n.getModule(), n, kind, extraInfo);
}
void semanticError(Statement n, int offset, ErrorKind kind, ErrorExtraInfo extraInfo = null) {
    Module mod = n.getModule(); assert(mod);
    Token t = mod.getToken(n.tokenIndex + offset);
    mod.project.addError(new CompilationError(mod, n, t.line, t.column, kind, extraInfo));
}
void semanticError(Project project, Module mod, Node n, ErrorKind kind, ErrorExtraInfo extraInfo = null) {
    Token t = n.as!Statement.startToken;
    project.addError(new CompilationError(mod, n.as!Statement, t.line, t.column, kind, extraInfo));
}
