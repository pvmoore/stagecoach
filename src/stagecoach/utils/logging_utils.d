module stagecoach.utils.logging_utils;

import stagecoach.all;

import std.stdio  : File;

enum LoggingStage { None, Tokenising, Scanning, Parsing, Resolving, Checking, Generating, All }

final class LoggingContext {
    Module mod;
    LoggingStage currentStage = LoggingStage.None;
    File file;
    bool open;

    this(Module mod) {
        this.mod = mod;
    }

    bool shouldLog() {
        bool m = g_onlyLogModule == "" || mod.name == g_onlyLogModule;
        bool s = g_onlyLogStage == LoggingStage.All || currentStage == g_onlyLogStage;
        return g_loggingEnabled && m && s;
    }
}

void updateLoggingContext(Module mod, LoggingStage stage) {
    auto lc = getLoggingContext(mod);
    lc.currentStage = stage;
}

__gshared {
    bool g_loggingEnabled         = true;
    string g_onlyLogModule        = "";
    LoggingStage g_onlyLogStage   = LoggingStage.All;
    Mutex g_logMutex;
    LoggingContext[Module] g_loggingContexts;
}

void log(A...)(Module mod, string fmt, A args) {
    log(mod, format(fmt, args));
}
void logAnsi(A...)(Module mod, string ansi, string fmt, lazy A args) {
    log(mod, ansiWrap(format(fmt, args), ansi));
}
void log(Module mod, string str) {
    auto lc = getLoggingContext(mod);
    if(lc.shouldLog()) {
        if(!lc.open) {
            lc.file = File(mod.project.getTargetFilename(mod, "logs", "", "log"), "w");
            lc.open = true;
        }
        lc.file.writeln(str);
    }
}

void log(Module mod, Token[] tokens) {
    log(mod, "Tokens: (%s) [", tokens.length);
    foreach(t; tokens) {
        log(mod, "  [%s:%s] %s '%s'", t.line+1, t.column, t.kind, t.text);
    }
    log(mod, "]");
}

private LoggingContext getLoggingContext(Module mod) {
    g_logMutex.lock();
    scope(exit) g_logMutex.unlock();
    
    auto ptr = mod in g_loggingContexts;
    if(ptr) return *ptr;
 
    auto lc = new LoggingContext(mod);
    g_loggingContexts[mod] = lc;
    return lc;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

void consoleLog(A...)(string fmt, A args) {
    if(!g_loggingEnabled) return;
    auto s = format(fmt, args);
    writeln(s);
}
void consoleLogAnsi(A...)(string ansi, string fmt, lazy A args) {
    if(!g_loggingEnabled) return;
    auto s = format(fmt, args);
    writefln(ansiWrap(s, ansi));
}

void flushLogs() {
    import core.stdc.stdio : fflush, stderr, stdout;
    fflush(stderr);
    fflush(stdout);
}

string ansiWrap(string text, string ansi) {
    return ansi ~ text ~ Ansi.RESET;
}

enum Ansi : string {
    BLACK           = "\u001b[30m",
    RED             = "\u001b[31m",
    GREEN           = "\u001b[32m",
    YELLOW          = "\u001b[33m",
    BLUE            = "\u001b[34m",
    MAGENTA         = "\u001b[35m",
    CYAN            = "\u001b[36m",
    WHITE           = "\u001b[37m",

    BLACK_BOLD      = "\u001b[30;1m",
    RED_BOLD        = "\u001b[31;1m",
    GREEN_BOLD      = "\u001b[32;1m",
    YELLOW_BOLD     = "\u001b[33;1m",
    BLUE_BOLD       = "\u001b[34;1m",
    MAGENTA_BOLD    = "\u001b[35;1m",
    CYAN_BOLD       = "\u001b[36;1m",
    WHITE_BOLD      = "\u001b[37;1m",

    BLACK_BG        = "\u001b[40m",
    RED_BG          = "\u001b[41m",
    GREEN_BG        = "\u001b[42m",
    YELLOW_BG       = "\u001b[43m",
    BLUE_BG         = "\u001b[44m",
    MAGENTA_BG      = "\u001b[45m",
    CYAN_BG         = "\u001b[46m",
    WHITE_BG        = "\u001b[47m",

    BLACK_BOLD_BG   = "\u001b[40;1m",
    RED_BOLD_BG     = "\u001b[41;1m",
    GREEN_BOLD_BG   = "\u001b[42;1m",
    YELLOW_BOLD_BG  = "\u001b[43;1m",
    BLUE_BOLD_BG    = "\u001b[44;1m",
    MAGENTA_BOLD_BG = "\u001b[45;1m",
    CYAN_BOLD_BG    = "\u001b[46;1m",
    WHITE_BOLD_BG   = "\u001b[47;1m",

    BOLD            = "\u001b[1m",
    UNDERLINE       = "\u001b[4m",
    INVERSE         = "\u001b[7m",

    RESET           = "\u001b[0m",
}
