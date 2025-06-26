module stagecoach.llvm.llvm_utils;

import stagecoach.all;

// See llvm-project\llvm\include\llvm\IR\CallingConv.h
enum CallingConv : uint {
    C           = 0,
    Fast        = 8,
    Cold        = 9,
    Win64       = 79,
}

void writeLLToFile(Module mod, string filename) {
    char* error;
    scope(exit) if(error !is null) LLVMDisposeMessage(error);
    if(LLVMPrintModuleToFile(mod.llvmModule, filename.toStringz(), &error)) {
        log(mod, "Failed to write ll file: %s", error.fromStringz());
    }
}

Tuple!(uint, uint, uint) getLLVMVersion() {
    uint major, minor, patch;
    LLVMGetVersion(&major, &minor, &patch);
    return tuple(major, minor, patch);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
// LLVMTypeRef and LLVMValueRef utilities
//──────────────────────────────────────────────────────────────────────────────────────────────────
LLVMBool toLLVMBool(bool b) {
    return b ? 1 : 0;
}
bool isPointer(LLVMTypeRef ty) {
    return LLVMGetTypeKind(ty) == LLVMTypeKind.LLVMPointerTypeKind;
}
bool isPointer(LLVMValueRef value) {
    return LLVMTypeOf(value).isPointer();
}
string printModuleToString(LLVMModuleRef mod) {
    auto chars = LLVMPrintModuleToString(mod);
    return cast(string)chars.fromStringz();
}
string printValueToString(LLVMValueRef value) {
    auto chars = LLVMPrintValueToString(value);
    return cast(string)chars.fromStringz();
}
string printTypeToString(LLVMTypeRef ty) {
    auto chars = LLVMPrintTypeToString(ty);
    return cast(string)chars.fromStringz();
}
string getName(LLVMBasicBlockRef block) {
    return LLVMGetBasicBlockName(block).fromStringz().as!string;
}
LLVMValueRef alignof(LLVMTypeRef t) {
	return LLVMAlignOf(t);
}
LLVMValueRef sizeof(LLVMTypeRef t) {
	return LLVMSizeOf(t);
}
LLVMTypeRef getElementType(LLVMTypeRef ty) {
	return LLVMGetElementType(ty);
}
bool isFunction(LLVMValueRef value) {
    return LLVMGetValueKind(value) == LLVMValueKind.LLVMFunctionValueKind;
}


