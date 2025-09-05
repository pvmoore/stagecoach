module test_suite;

import std.stdio  : writef, writefln;
import std.file   : read, dirEntries, SpanMode;
import std.path;
import std.array  : replace;
import std.string : indexOf, split;
import std.format : format;

import stagecoach;

void runTestSuite() {
    foreach(e; dirEntries("test_suite/valid", SpanMode.depth)) {
        if(e.isDir) {
            string directory = e.name.buildNormalizedPath().replace("\\", "/");
            runTestDirectory("valid", directory);
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

enum {
    CYAN       = "\u001b[36m",
    GREEN_BOLD = "\u001b[32;1m",
    RED_BOLD   = "\u001b[31;1m",
    RESET      = "\u001b[0m",
}

void runTestDirectory(string suiteName, string directory) {
    foreach(e; dirEntries(directory, "**.stage", SpanMode.breadth)) {
        runTest(directory, e.name);
    }
}

void runTest(string directory, string filename) {
    // Read the test file and extract the test metadata
    Meta meta = Meta.readFrom(filename);

    auto options = new CompilerOptions();
    options.writeLL = true;
    options.writeAST = true;
    options.writeObj = true;
    options.checkOnly = false;
    options.subsystem = "console";
    
    options.isDebug = true;

    options.enableAsserts = true;
    options.enableNullChecks = true;
    options.enableBoundsChecks = true;

    Compiler compiler = new Compiler(options);
    auto errors = compiler.compileProject(filename);

    bool pass = false;

    if(meta.errors.length == 0) {
        // This is expected to pass. If there are no errors (in which case this is a fail) then
        // we need to run the executable to check the status code
    }
    
    writef("[%s%s%s], %s'%s' %s %s", CYAN, directory.baseName(), RESET, CYAN, meta.name, filename.baseName(), RESET);
    
    if(errors.length > 0) {
        writefln(" %s%s%s", RED_BOLD, "FAIL", RESET);
    } else {
        writefln(" %s%s%s", GREEN_BOLD, "PASS", RESET);
    }
}

struct Meta {
    string name;
    string[] tags;
    string[] args;
    string[] errors;

    /**
     * name "01_basic_variables"
     * tags [ variables, locals, globals ]
     * args []
     * errors []
     */
    static Meta readFrom(string filename) {
        string s = cast(string)read(filename);
        s = between(s, null, "/*", "*/");

        Meta meta;
        meta.name   = between(s, "name", "\"", "\"");
        meta.tags   = between(s, "tags", "[", "]").split(",");
        meta.args   = between(s, "args", "[", "]").split(",");
        meta.errors = between(s, "errors", "[", "]").split(",");
        return meta;
    }
    string toString() {
        return ("Meta {\n" ~
            "  name \"%s\"\n" ~
            "  tags %s\n" ~
            "  args %s\n" ~
            "  errors %s\n}"
        ).format(name, tags, args, errors);
    }
private:
    static string between(string s, string skipTo, string start, string end) {
        auto fromIdx  = skipTo is null ? 0 : s.indexOf(skipTo) + skipTo.length;
        auto startIdx = s.indexOf(start, fromIdx) + start.length;  
        auto endIdx   = s.indexOf(end, startIdx);
        return s[startIdx..endIdx];
    }
}
