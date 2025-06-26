module stagecoach.errors.error_extra_info;

import stagecoach.all;
import stagecoach.errors.error_utils;

string getExtraInfoMessage(CompilationError error) {
    Statement stmt = error.stmt;
    string extraInfo;

    switch(error.kind()) {
        case ErrorKind.CALL_AMBIGUOUS_FUNCTION: {
            extraInfo = formatAmbiguousFunction(stmt.as!Call());
            break;
        }
        case ErrorKind.CALL_ARGUMENT_TYPE_MISMATCH: {

            Expression arg = stmt.as!Expression; assert(arg);
            Call call = arg.parent.as!Call; assert(call);
            Function func = call.target.func;
            int index = call.arguments().indexOf(arg);
            Type paramType = call.target.func.paramTypes()[index];

            extraInfo ~= "Function:\n";
            extraInfo ~= "  %s\n".format(ansiWrap(getLocationString(func), Ansi.CYAN));
            extraInfo ~= "  %s(%s)\n".format(func.name, func.paramTypes().shortName());

            extraInfo ~= "Call:\n";
            extraInfo ~= "  %s\n".format(ansiWrap(getLocationString(call), Ansi.CYAN));
            extraInfo ~= "  %s(%s)\n".format(call.name, call.argumentTypes().shortName());


            extraInfo ~= "%s\n".format("Cannot implicitly convert %s to the parameter type %s".format(arg.getType().shortName(), paramType.shortName()));
            extraInfo ~= "  %s".format(ansiWrap(getLocationString(call.target.func), Ansi.CYAN));
            break;
        }
        case ErrorKind.VARIABLE_SHADOWING: {
            Variable v = stmt.as!Variable; assert(v);
            VariableErrorExtraInfo extra = error.extraInfo.as!VariableErrorExtraInfo; assert(extra);
            extraInfo ~= "Shadowed variables:\n";
            foreach(v2; extra.duplicateVariables) {
                extraInfo ~= "  %s\n".format(ansiWrap(getLocationString(v2), Ansi.CYAN));
            }
            break;
        }

        default: 
            break;
    }

    return extraInfo;
}

string formatAmbiguousFunction(Call n) { 
    CallResolveHistory h = n.resolveHistory;

    string s;

    if(n.arguments().areResolved()) {
        s ~= "    %s(%s)\n\n".format(n.name, n.argumentTypes().shortName()); 
    }

    s ~= "Possible matches:";
    int i;

    void writeFunction(Function f) {
        s ~= "\n(%s) ".format(cast(char)('a' + i++));
        s ~= "%s(%s)\n".format(f.name, f.paramTypes().shortName());
        s ~= "    %s".format(ansiWrap(getLocationString(f), Ansi.CYAN));
    }
    void writeVariable(Variable v) {
        s ~= "\n(%s) ".format(cast(char)('a' + i++));
        s ~= "%s\n".format(v.name);
        s ~= "    %s".format(ansiWrap(getLocationString(v), Ansi.CYAN));
    }

    foreach(t; h.exactTypeCandidates) {
        if(Variable v = t.var) {
            writeVariable(v);
        } else {
            writeFunction(t.func);
        }
    }
    foreach(t; h.implicitTypeCandidates) {
        if(Variable v = t.var) {
            writeVariable(v);
        } else {
            writeFunction(t.func);
        }
    }

    return s;
}
