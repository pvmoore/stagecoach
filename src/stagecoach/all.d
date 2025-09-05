module stagecoach.all;

public:

import core.sync.mutex : Mutex;

import std.stdio              : writefln, writef, writeln;
import std.format             : format;
import std.algorithm          : any, all, map, filter, find, sum;
import std.range              : array, chain;
import std.array              : join;
import std.string             : toStringz, fromStringz, replace, strip, toUpper;
import std.datetime.stopwatch : StopWatch;
import std.typecons           : Tuple, tuple;

// Import the public interface
import stagecoach;

// Import the private implementation
import stagecoach.Project;

import stagecoach.ast.AddressOf;
import stagecoach.ast.ArrayLiteral;
import stagecoach.ast.As;
import stagecoach.ast.Binary;
import stagecoach.ast.Builtin;
import stagecoach.ast.Call;
import stagecoach.ast.Dot;
import stagecoach.ast.EnumMember;
import stagecoach.ast.Expression;
import stagecoach.ast.Identifier;
import stagecoach.ast.If;
import stagecoach.ast.Index;
import stagecoach.ast.Is;
import stagecoach.ast.Number;
import stagecoach.ast.Null;
import stagecoach.ast.Parens;
import stagecoach.ast.StringLiteral;
import stagecoach.ast.StructLiteral;
import stagecoach.ast.Unary;
import stagecoach.ast.ValueOf;

import stagecoach.ast.module_.Module;
import stagecoach.ast.module_.ModuleRef;

import stagecoach.ast.node.Node;
import stagecoach.ast.node.NodeKind;
import stagecoach.ast.node.NodeRef;

import stagecoach.ast.stmts.Assert;
import stagecoach.ast.stmts.Return;
import stagecoach.ast.stmts.Statement;
import stagecoach.ast.stmts.Variable;

import stagecoach.ast.types.Alias;
import stagecoach.ast.types.ArrayType;
import stagecoach.ast.types.Enum;
import stagecoach.ast.types.SimpleType;
import stagecoach.ast.types.Function;
import stagecoach.ast.types.PointerType;
import stagecoach.ast.types.Struct;
import stagecoach.ast.types.Type;
import stagecoach.ast.types.TypeKind;
import stagecoach.ast.types.TypeOf;
import stagecoach.ast.types.TypeRef;

import stagecoach.checking.check;
import stagecoach.checking.check_function;
import stagecoach.checking.check_identifier;
import stagecoach.checking.check_variable;

import stagecoach.errors.CompilationError;
import stagecoach.errors.ErrorKind;

import stagecoach.generating.generate;
import stagecoach.generating.generate_array;
import stagecoach.generating.generate_binary;
import stagecoach.generating.generate_call;
import stagecoach.generating.generate_function;
import stagecoach.generating.generate_identifier;
import stagecoach.generating.generate_if;
import stagecoach.generating.generate_index;
import stagecoach.generating.generate_module;
import stagecoach.generating.generate_struct;
import stagecoach.generating.generate_variable;
import stagecoach.generating.GenerateState;

import stagecoach.linking.link;
import stagecoach.linking.lld_linker;
import stagecoach.linking.ms_linker;

import stagecoach.llvm.llvm_api;
import stagecoach.llvm.llvm_utils;
import stagecoach.llvm.llvm_target_machine;

import stagecoach.parsing.attributes;
import stagecoach.parsing.parse_expressions;
import stagecoach.parsing.parse_statements;
import stagecoach.parsing.parse_types;
import stagecoach.parsing.ParseState;

import stagecoach.resolving.Operator;
import stagecoach.resolving.resolve_array_literal;
import stagecoach.resolving.resolve_as;
import stagecoach.resolving.resolve_builtin;
import stagecoach.resolving.resolve_call;
import stagecoach.resolving.resolve_const;
import stagecoach.resolving.resolve_identifier;
import stagecoach.resolving.resolve_is;
import stagecoach.resolving.resolve_if;
import stagecoach.resolving.resolve_number;
import stagecoach.resolving.resolve_struct_literal;
import stagecoach.resolving.resolve_type;
import stagecoach.resolving.resolve_variable;
import stagecoach.resolving.resolve;
import stagecoach.resolving.ResolveState;
import stagecoach.resolving.rewriter;
import stagecoach.resolving.TargetOfCall;
import stagecoach.resolving.TargetOfIdentifier;   

import stagecoach.scanning.scanner;

import stagecoach.tokenising.Lexer;
import stagecoach.tokenising.Token;
import stagecoach.tokenising.TokenKind;

import stagecoach.utils.utils;
import stagecoach.utils.container_utils;
import stagecoach.utils.logging_utils;

__gshared { 
    // All static initialisation needs to go in here to avoid circular dependencies
    static this() {
        g_logMutex = new Mutex();
    }
    // All static destruction
    static ~this() {
        foreach(lc; g_loggingContexts.values) {
            if(lc.open) {
                lc.file.close();
            }
        }
    }
}
