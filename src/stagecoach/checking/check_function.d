module stagecoach.checking.check_function;

import stagecoach.all;

void checkFunction(Function f) {

    // Check the parameters
    foreach(i, p; f.params()) {
        checkVariable(p);
    }

    // Check that there is a return if the return type is not void
    if(!f.isExtern && !f.returnType.isVoidValue()) {
        Node last = f.last();

        if(last is null) {
            semanticError(f, ErrorKind.FUNCTION_MISSING_RETURN);
        }
    }
}
