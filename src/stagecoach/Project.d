module stagecoach.Project;

import stagecoach.all;
import std.file : getcwd, exists, mkdirRecurse;
import std.path : baseName, dirName, withExtension;

final class Project {
public:
    // Fixed state
    string mainFilename;
    string directory;   
    string targetDirectory;
    string targetName;

    // Fixed user options
    CompilerOptions options;
    string targetTriple;

    // Dynamic state
    Module mainModule;
    Module[] allModules;
    Module[string] modulesByFilename;
    Module[string] modulesByName;
    CompilationError[] errors;

    this(CompilerOptions options, string mainFilename) {
        this.options = options;
        this.targetTriple = options.targetTriple;

        string workingDirectory = getcwd().replace("\\", "/") ~ "/";
        string normalisedFilename = toCanonicalPath(mainFilename, false);

        this.mainFilename = baseName(normalisedFilename);
        this.directory = dirName(normalisedFilename) ~ "/";
        this.targetDirectory = workingDirectory ~ ".target/";
        this.targetName = baseName(normalisedFilename).withExtension("").array;

        this.createTargetDirectory();

        consoleLog("Working directory .. %s", workingDirectory);
        consoleLog("Project directory .. %s", this.directory);
        consoleLog("Main filename ...... %s", this.mainFilename);
        consoleLog("Target directory ... %s", this.targetDirectory);
        consoleLog("Target name ........ %s.exe", this.targetName);

        foreach(lib; options.getLibs()) {
            consoleLog("Lib ................ '%s' %s", lib.name, lib.sourceDirectory);
        }
    }

    bool hasErrors() { return errors.length > 0; }

    string getTargetFilename(Module mod, string subdir, string suffix, string extension) {
        subdir = subdir ? subdir ~ "/" : "";
        string dir = targetDirectory ~ subdir;
        return dir ~ mod.name.replace("/", "_") ~ suffix ~ "." ~ extension;
    }

    void addError(CompilationError e) {
        // Don't add the same error more than once
        foreach(er; errors) if(er == e) return;

        errors ~= e;

        // Bail out if this is a SyntaxError
        if(e.kind() == ErrorKind.SYNTAX) { throw new Exception(e.getSummary()); }
    }
    void addModule(Module mod) {
        allModules ~= mod;
        modulesByName[mod.name] = mod;
        modulesByFilename[mod.relFilename] = mod;

        if(!this.mainModule) {
            // This is the main program Module
            this.mainModule = mod;
            mod.isMainModule = true;
        }
    }

    Module processMainSourceFile(string relFilename) { 
        if(!exists(directory ~ relFilename)) {
            throw new Exception("Source file not found: %s".format(directory ~ relFilename));
        }
        return processSourceFile(directory, relFilename);
    }

    /**
     * Get the external libraries required by the linker.
     * This consists of the C runtime libraries and any user-specified libraries.
     *
     * https://learn.microsoft.com/en-us/cpp/c-runtime-library/crt-library-features?view=msvc-170#c-runtime-lib-files
     */
    string[] getExternalLibs() {
        string[] externalLibs;
        if(options.isDebug) {
            externalLibs ~= [
                //"ucrtd.lib",                  // MS universal C99 runtime (debug)
                "msvcrtd.lib",                  // MS C initialization and termination (debug)
                "legacy_stdio_definitions.lib", // Required for printf (and probably other stdio functions)
            ];
            //externalLibs ~= [
            //    "libucrtd.lib",
            //    "libcmtd.lib",
            //    "libvcruntimed.lib"
            //];
        } else {
            externalLibs ~= [
                "msvcrt.lib",               // MS C initialization and termination (release)
                //"ucrt.lib",                 // MS universal C99 runtime (release)
                "legacy_stdio_definitions.lib", // Required for printf (and probably other stdio functions)
            ];
            //externalLibs ~= [
            //    "libucrt.lib",
            //    "libcmt.lib",
            //    "libvcruntime.lib"
            //];
        }
        foreach(l; options.getLibs()) {
            if(l.libFile) {
                externalLibs ~= l.libFile;
            }
        }
        return externalLibs;
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    void createTargetDirectory() {
        void create(string dir) {
            if(!dir.exists()) {
                mkdirRecurse(dir);
            }
        }
        create(targetDirectory ~ "/scan/");
        create(targetDirectory ~ "/ast/");
        create(targetDirectory ~ "/ll/");
        create(targetDirectory ~ "/logs/");
    } 
    /**
     * - Read the source
     * - Tokenise the source
     * - Scan the source for user defined types, imports and function names
     */
    Module processSourceFile(string baseDirectory, string relFilename) {

        // Skip if we have already processed this file
        if(relFilename in modulesByFilename) return modulesByFilename[relFilename];

        // Read the source
        import std.file : read;
        string source = read(baseDirectory ~ relFilename).as!string;

        // Create and initialise the Module instance
        Module mod = makeNode!Module(0);
        mod.project = this;
        mod.name = toModuleName(relFilename);
        mod.relFilename = relFilename;
        mod.source = source;
        mod.baseDirectory = baseDirectory;
        addModule(mod);

        // Lex the source into a Token array
        mod.tokens = new Lexer(mod, source).tokenise();

        // Scan the module for user defined types, imports and function names
        mod.scanResult = scanModule(mod);

        // Add an implicit [import @common:@common]
        if(mod.name != "@common") {
            processImport(mod, ScanImport("@common", null, "@common"));
        }

        // Process the imports
        foreach(ScanImport imp; mod.scanResult.imports) {
            processImport(mod, imp);   
        }

        writeScanResults(this, mod);

        return mod;
    }
    void processImport(Module mod, ScanImport imp) {

        // Check for a module importing itself
        if(imp.libName is null && imp.path == mod.name) {
            syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Recursive import");
            return;
        }

        string relFilename = toSourceFilename(imp.path);
        string baseDirectory;

        //consoleLog("looking for import [%s] from module %s %s", imp, mod.name, mod.baseDirectory);
        
        if(imp.libName) {
            // This is a library include
            if(auto lib = options.getLib(imp.libName)) {
                if(lib.sourceDirectory is null) {
                    syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Library '%s' has no source".format(imp.libName));
                    return;
                }
                baseDirectory = lib.sourceDirectory;

                if(!exists(baseDirectory ~ relFilename)) {
                    syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Module '%s' not found in library '%s'".format(imp.path, imp.libName));
                    return;
                }
            } else {
                syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Library '%s' not found".format(imp.libName));
                return;
            }

        } else if(exists(mod.baseDirectory ~ relFilename)) {
            // Relative to the importing module
            baseDirectory = mod.baseDirectory;
        }

        if(baseDirectory is null) {
            syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Import '%s' not found".format(imp.path));
            return;
        }

        Module importedModule = processSourceFile(baseDirectory, relFilename);

        if(imp.alias_) {
            // Check for duplicate alias
            if(mod.isModuleAlias(imp.alias_)) {
                syntaxError(mod, imp.aliasToken.line, imp.aliasToken.column, "Module alias '%s' already defined".format(imp.alias_));
                return;
            }
            mod.importedModulesQualified[imp.alias_] = importedModule;
            mod.log("  Importing module %s = %s%s", imp.alias_, imp.libName ? "%s:".format(imp.libName) : "", imp.path);
        } else {

            string key = imp.libName ? imp.libName ~ ":" ~ imp.path : imp.path;

            mod.importedModulesUnqualified[key] = importedModule;
            mod.log("  Importing module %s", key);
        }   
    }
}
