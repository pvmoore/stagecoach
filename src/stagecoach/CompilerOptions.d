module stagecoach.CompilerOptions;

final class CompilerOptions {
public:
    string targetTriple = "x86_64-pc-windows-msvc";
    string subsystem = "console";
    string[] libs;

    bool isDebug = true;
    bool checkOnly = false;

    bool enableAsserts = true;
    bool enableNullChecks = true;
    bool enableBoundsChecks = true;

    bool writeObj = false;
    bool writeLL = false;
    bool writeAST = false;
}
