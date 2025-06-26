module stagecoach.generating.GenerateState;

import stagecoach.all;

final class GenerateState {
public:
    this(Module mod, LLVMContextRef context) {
        this.mod = mod;
        this.context = context;
        this.normalBuilder = LLVMCreateBuilderInContext(context);
        this.initFunctionBuilder = LLVMCreateBuilderInContext(context);
        this.currentModule = LLVMModuleCreateWithNameInContext(mod.name.toStringz(), context);
        this.targetData = LLVMGetModuleDataLayout(currentModule);

        this.VOID_TYPE = LLVMVoidTypeInContext(context);
        this.INT1_TYPE = LLVMInt1TypeInContext(context);
        this.INT8_TYPE = LLVMInt8TypeInContext(context);
        this.INT16_TYPE = LLVMInt16TypeInContext(context);
        this.INT32_TYPE = LLVMInt32TypeInContext(context);
        this.INT64_TYPE = LLVMInt64TypeInContext(context);
        this.FLOAT_TYPE = LLVMFloatTypeInContext(context);
        this.DOUBLE_TYPE = LLVMDoubleTypeInContext(context);
        this.VOID_PTR_TYPE = LLVMPointerType(LLVMVoidTypeInContext(context), 0);

        mod.llvmModule = currentModule;
        builder = normalBuilder;

        // log("PointerSize = %s", LLVMPointerSize(targetData));
        // log("Store size of i8 is %s", LLVMStoreSizeOfType(targetData, INT8_TYPE));
        // log("Store size of i16 is %s", LLVMStoreSizeOfType(targetData, INT16_TYPE));
        // log("Store size of i32 is %s", LLVMStoreSizeOfType(targetData, INT32_TYPE));
        // log("Store size of i64 is %s", LLVMStoreSizeOfType(targetData, INT64_TYPE));
        // log("Store size of float is %s", LLVMStoreSizeOfType(targetData, FLOAT_TYPE));
        // log("Store size of double is %s", LLVMStoreSizeOfType(targetData, DOUBLE_TYPE));
        // log("Store size of ptr is %s", LLVMStoreSizeOfType(targetData, PTR_TYPE));

        // log("ABI size of i8 is %s", LLVMABISizeOfType(targetData, INT8_TYPE));
        // log("ABI size of i16 is %s", LLVMABISizeOfType(targetData, INT16_TYPE));
        // log("ABI size of i32 is %s", LLVMABISizeOfType(targetData, INT32_TYPE));
        // log("ABI size of i64 is %s", LLVMABISizeOfType(targetData, INT64_TYPE));
        // log("ABI size of float is %s", LLVMABISizeOfType(targetData, FLOAT_TYPE));
        // log("ABI size of double is %s", LLVMABISizeOfType(targetData, DOUBLE_TYPE));
        // log("ABI size of ptr is %s", LLVMABISizeOfType(targetData, PTR_TYPE));

        // log("Alignment of i8 is %s", LLVMPreferredAlignmentOfType(targetData, INT8_TYPE));
        // log("Alignment of i16 is %s", LLVMPreferredAlignmentOfType(targetData, INT16_TYPE));
        // log("Alignment of i32 is %s", LLVMPreferredAlignmentOfType(targetData, INT32_TYPE));
        // log("Alignment of i64 is %s", LLVMPreferredAlignmentOfType(targetData, INT64_TYPE));
        // log("Alignment of float is %s", LLVMPreferredAlignmentOfType(targetData, FLOAT_TYPE));
        // log("Alignment of double is %s", LLVMPreferredAlignmentOfType(targetData, DOUBLE_TYPE));
        // log("Alignment of ptr is %s", LLVMPreferredAlignmentOfType(targetData, PTR_TYPE));
        //log("Alignment of struct [ { i8 } x 2 ] is %s", LLVMPreferredAlignmentOfType(targetData, LLVMArrayType2(LLVMStructTypeInContext(context, [INT8_TYPE].ptr, 1, 0), 2)));
        //log("Size of array of structs [ { i8 } x 2 ] is %s", LLVMABISizeOfType(targetData, LLVMArrayType2(LLVMStructTypeInContext(context, [INT8_TYPE].ptr, 1, 0), 2)));
   
        // struct Chicken { // size = 8
        //     int a;      // align 0 
        //     bool b;     // align 4
        //     short c;    // align 6
        // }
        // struct Gnat {    // size = 1
        //     byte b;     // align 0
        // }
        // struct Egg {    // size = 16
        //     bool a;     // align 0
        //     Chicken b;  // align 4
        //     int c;      // align 12
        // }

        // auto gnat = LLVMStructTypeInContext(context, [INT8_TYPE].ptr, 1, 0);
        // auto chicken = LLVMStructTypeInContext(context, [INT32_TYPE, INT8_TYPE, INT16_TYPE].ptr, 3, 0);
        // auto egg = LLVMStructTypeInContext(context, [INT8_TYPE, chicken, INT32_TYPE].ptr, 3, 0);

        // log("size of Gnat is %s", LLVMABISizeOfType(targetData, gnat));
        // log("size of Chicken is %s", LLVMABISizeOfType(targetData, chicken));
        // log("size of Egg is %s", LLVMABISizeOfType(targetData, egg));
    }

    // Static state
    Module mod;
    LLVMContextRef context;
    LLVMBuilderRef normalBuilder;
    LLVMBuilderRef initFunctionBuilder;
    LLVMTargetDataRef targetData;
    LLVMTypeRef VOID_TYPE;
    LLVMTypeRef INT1_TYPE;
    LLVMTypeRef INT8_TYPE;
    LLVMTypeRef INT16_TYPE;
    LLVMTypeRef INT32_TYPE;
    LLVMTypeRef INT64_TYPE;
    LLVMTypeRef FLOAT_TYPE;
    LLVMTypeRef DOUBLE_TYPE;
    LLVMTypeRef VOID_PTR_TYPE;

    // Dynamic state
    LLVMModuleRef currentModule;
    LLVMBuilderRef builder;
    LLVMValueRef currentFunction;
    LLVMValueRef lhs;
    LLVMValueRef rhs;
    LLVMValueRef initFunctionValue;

    void generate(Node n) {

        //this.log("Generating %s %s", n.nodeKind(), n);

        switch(n.nodeKind()) {
            case NodeKind.ADDRESS_OF: generateAddressOf(n.as!AddressOf, this); break;
            case NodeKind.ARRAY_LITERAL: generateArrayLiteral(n.as!ArrayLiteral, this); break;
            case NodeKind.AS: generateAs(n.as!As, this); break;
            case NodeKind.BINARY: generateBinary(n.as!Binary, this); break;
            case NodeKind.CALL: generateCall(n.as!Call, this); break;
            case NodeKind.DOT: generateDot(n.as!Dot, this); break;
            case NodeKind.ENUM_MEMBER: generateEnumMember(n.as!EnumMember, this); break;
            case NodeKind.FUNCTION: generateFunctionBody(n.as!Function, this); break;
            case NodeKind.IDENTIFIER: generateIdentifier(n.as!Identifier, this); break;
            case NodeKind.IF: generateIf(n.as!If, this); break;
            case NodeKind.INDEX: generateIndex(n.as!Index, this); break;
            case NodeKind.NODE_REF: generateNodeRef(n.as!NodeRef, this); break;
            case NodeKind.NULL: generateNull(n.as!Null, this); break;
            case NodeKind.MODULE_REF: break;
            case NodeKind.NUMBER: generateNumber(n.as!Number, this); break;
            case NodeKind.PARENS: generateParens(n.as!Parens, this); break;
            case NodeKind.RETURN: generateReturn(n.as!Return, this); break;
            case NodeKind.STRING_LITERAL: generateStringLiteral(n.as!StringLiteral, this); break;
            case NodeKind.STRUCT_LITERAL: generateStructLiteral(n.as!StructLiteral, this); break;
            case NodeKind.TYPE_REF: break;
            case NodeKind.UNARY: generateUnary(n.as!Unary, this); break;
            case NodeKind.VALUE_OF: generateValueOf(n.as!ValueOf, this); break;
            case NodeKind.VARIABLE: generateVariable(n.as!Variable, this); break;
            default: throwIf(true, "Handle generate %s", n.nodeKind()); 
        }

        //this.log(" Generated %s", n.nodeKind());
    }

    /**
    * Verify the module if we are in debug mode.
    */
    bool verifyModule() {
        debug {
            char* msgs;
            if(LLVMVerifyModule(currentModule, LLVMVerifierFailureAction.LLVMPrintMessageAction, &msgs)) {
                logAnsi(mod, Ansi.RED_BOLD, "Module verification failed: %s", msgs.fromStringz());
                LLVMDisposeMessage(msgs);

                logAnsi(mod, Ansi.RED, "%s", currentModule.printModuleToString());

                return false;
            }
        }
        return true;
    }

    void switchToInitFunctionBuilder() {
        this.builder = initFunctionBuilder;
    }
    void switchToNormalBuilder() {
        this.builder = normalBuilder;
    }

     LLVMBasicBlockRef createBlock(string name) {
        LLVMValueRef functionValue = currentFunction;
        if(builder is initFunctionBuilder) {
            functionValue = initFunctionValue;
        }
        return LLVMAppendBasicBlockInContext(context, functionValue, name.toStringz());
     }
    LLVMTypeRef getLLVMFunctionType(Function f) {
        if(f.llvmType) return f.llvmType;

        LLVMTypeRef returnType = getLLVMType(f.returnType);
        LLVMTypeRef[] paramTypes = f.paramTypes().filter!(it=>it.typeKind() != TypeKind.C_VARARGS)
                                                 .map!(it => getLLVMType(it))
                                                 .array;
        
        return LLVMFunctionType(returnType, paramTypes.ptr, paramTypes.length.as!uint, f.hasVarargParam.toLLVMBool());
    }

    LLVMTypeRef getLLVMType(Type t) {
        // This also covers functions because they are also pointers 
        if(t.isPointer()) {
            LLVMTypeRef valueType = t.isFunction() ? getLLVMFunctionType(t.extract!Function) 
                                                   : getLLVMType(t.extract!PointerType.valueType());
            return LLVMPointerType(valueType, 0);
        }
        if(t.isArrayType()) {
            ArrayType at = t.extract!ArrayType; assert(at);
            if(at.llvmType) return at.llvmType;

            at.llvmType = LLVMArrayType2(getLLVMType(at.elementType()), at.numElements());
            return at.llvmType;
        }
        if(t.isStruct()) {
            Struct st = t.extract!Struct; assert(st);
            if(st.llvmType) return st.llvmType;

            LLVMTypeRef[] memberTypes = st.members().map!(m => getLLVMType(m.getType())).array;
            if(st.name) {
                st.llvmType = LLVMStructCreateNamed(context, st.name.toStringz());
                LLVMStructSetBody(st.llvmType, memberTypes.ptr, memberTypes.length.as!uint, st.isPacked.toLLVMBool());
            } else  {
                st.llvmType = LLVMStructTypeInContext(context, memberTypes.ptr, memberTypes.length.as!uint, st.isPacked.toLLVMBool());
            }
            return st.llvmType;
        }
        if(t.isEnum()) {
            return getLLVMType(t.extract!Enum.elementType());
        }
        return getLLVMType(t.typeKind());
    }
    LLVMTypeRef getLLVMType(TypeKind tk) {
        final switch(tk) {
            case TypeKind.VOID: return VOID_TYPE;
            case TypeKind.BOOL: // Bool is also a byte 
            case TypeKind.BYTE: 
                return INT8_TYPE;
            case TypeKind.SHORT: return INT16_TYPE;
            case TypeKind.INT: return INT32_TYPE;
            case TypeKind.LONG: return INT64_TYPE;
            case TypeKind.FLOAT: return FLOAT_TYPE;
            case TypeKind.DOUBLE: return DOUBLE_TYPE;
            case TypeKind.POINTER: 
                throwIf(true, "getLLVMType(TypeKind.POINTER) -> call getLLVMType(Type) for Pointers");
                break;
            case TypeKind.FUNCTION:
                throwIf(true, "getLLVMType(TypeKind.FUNCTION) -> call getLLVMType(Type) for Functions");
                break;
            case TypeKind.ARRAY:
                throwIf(true, "getLLVMType(TypeKind.ARRAY) -> call getLLVMType(Type) for ArrayTypes");
                break;
            case TypeKind.STRUCT:
                throwIf(true, "getLLVMType(TypeKind.STRUCT) -> call getLLVMType(Type) for Structs");
                break;
            case TypeKind.ENUM:
                throwIf(true, "getLLVMType(TypeKind.ENUM) -> call getLLVMType(Type) for Enums");
                break;    
            case TypeKind.UNKNOWN:
            case TypeKind.C_VARARGS:
                throwIf(true, "getLLVMType() Unexpected TypeKind %s", tk);
                break;
        }
        assert(false);
    }
    void addFunctionDeclaration(string name, 
                                LLVMTypeRef returnType, 
                                LLVMTypeRef[] paramTypes, 
                                CallingConv callingConv, 
                                LLVMLinkage linkage,
                                bool isVarArg = false) 
    {
        if(functionDeclarations.containsKey(name)) {
            log(mod, "Function decl added more than once: %s", name);
            return;
        }

        LLVMTypeRef type = LLVMFunctionType(returnType, paramTypes.ptr, paramTypes.length.as!uint, isVarArg.toLLVMBool());
        LLVMValueRef func = LLVMAddFunction(currentModule, name.toStringz(), type);
        LLVMSetFunctionCallConv(func, callingConv);
        LLVMSetLinkage(func, linkage);

        functionDeclarations[name] = TypeAndValue(type, func);
    }
    LLVMValueRef functionValue(string name) {
        assert(functionDeclarations.containsKey(name));
        return functionDeclarations[name].value;
    }
    LLVMTypeRef functionType(string name) {
        assert(functionDeclarations.containsKey(name));
        return functionDeclarations[name].type;
    }
    /**
     * This should get the intrinsic function and add it to the module if not already there.
     * It is not working for me however since when i ask for 'llvm.memset.inline' and params 
     * (ptr, i8, i64, i1) it returns a function with params (ptr, i8, i8, i1). Not sure why.
     */
    LLVMValueRef getIntrinsicFunctionValue(string name, LLVMTypeRef[] paramTypes) {
        uint id = LLVMLookupIntrinsicID(name.toStringz(), name.length.as!uint);
        ulong length;
        string intrinsicName = LLVMIntrinsicCopyOverloadedName(id, paramTypes.ptr, paramTypes.length.as!uint, &length).fromStringz().as!string;
        log(mod, "getIntrinsicFunctionValue: %s, length: %s, isOverloaded: %s", intrinsicName, length, LLVMIntrinsicIsOverloaded(id));

        uint id2 = LLVMLookupIntrinsicID(intrinsicName.toStringz(), length);
        log(mod, "id = %s, id2 = %s", id, id2);

        auto t = LLVMIntrinsicGetType(context, id2, paramTypes.ptr, paramTypes.length.as!uint);
        log(mod, "getIntrinsicFunctionValue: %s", t.printTypeToString());
        return LLVMGetIntrinsicDeclaration(currentModule, id, paramTypes.ptr, paramTypes.length.as!uint);
    }
    //======================================================================== Create Const LLVMValueRefs
    LLVMValueRef createConstI1Value(bool value) {
        return LLVMConstInt(INT1_TYPE, value ? 1 : 0, 0);
    }
    LLVMValueRef createConstI8Value(byte value) {
        return LLVMConstInt(INT8_TYPE, value, 1);
    }
    LLVMValueRef createConstI16Value(short value) {
        return LLVMConstInt(INT16_TYPE, value, 1);
    }
    LLVMValueRef createConstI32Value(int value) {
        return LLVMConstInt(INT32_TYPE, value, 1);
    }
    LLVMValueRef createConstI64Value(long value) {
        return LLVMConstInt(INT64_TYPE, value, 1);
    }
    LLVMValueRef createConstFloatValue(float value) {
        return LLVMConstReal(FLOAT_TYPE, value);
    }
    LLVMValueRef createConstDoubleValue(double value) {
        return LLVMConstReal(DOUBLE_TYPE, value);
    }
    LLVMValueRef createConstIntValue(LLVMTypeRef type, ulong value) {
        return LLVMConstInt(type, value, 1);
    }
    LLVMValueRef createConstRealValue(LLVMTypeRef type, double value) {
        return LLVMConstReal(type, value);
    }
    LLVMValueRef createConstStringValue(string name) {
        return LLVMConstStringInContext2(context, name.toStringz(), name.length, 0);
    }
    LLVMValueRef createConstArrayValue(LLVMTypeRef elementType, LLVMValueRef[] elements) {
        return LLVMConstArray2(elementType, elements.ptr, elements.length);
    }
    LLVMValueRef createConstStructValue(LLVMValueRef[] elements, bool isPacked = false) {
        return LLVMConstStructInContext(context, elements.ptr, elements.length.as!uint, isPacked.toLLVMBool());
    }
    //======================================================================== Build Instructions
    LLVMValueRef castToI1(LLVMValueRef value) {
        return LLVMBuildTrunc(builder, value, LLVMInt1TypeInContext(context), "to_i1");
    }
    LLVMValueRef castI1ToI8(LLVMValueRef value) {
        return LLVMBuildSExt(builder, value, LLVMInt8TypeInContext(context), "i1-to-i8");
    }
    LLVMValueRef castType(LLVMValueRef value, Type from, Type to, string name = null) {
        assert(from);
        assert(to);
        
        LLVMTypeRef toType = getLLVMType(to);
        auto namez = name.toStringz();

        if(from.exactlyMatches(to)) return value;

        //this.log("castType from %s to %s", from, to);

        if(from.isArrayType() || to.isArrayType()) {
            throwIf(true, "Can't cast ArrayTypes. They should exactly match");
        }

        // Pointer casts are not required
        if(from.isPointer() && to.isPointer()) {
            // no-op
            return value;
        }
        /// cast to different pointer type
        // if(from.isPointer() && to.isPointer()) {
        //     log("castType from %s* to %s*", from.as!PointerType.valueType(), to.as!PointerType.valueType());
        //     this.rhs = LLVMBuildBitCast(builder, value, toType, namez);
        //     log("2");
        //     return this.rhs;
        // }
        
        if(from.isPointer() && to.isInteger()) {
            this.rhs = LLVMBuildPtrToInt(builder, value, toType, namez);
            return this.rhs;
        }
        // if(from.isPointer() && to.isBool()) {
        //     this.rhs = LLVMBuildICmp(builder, LLVMIntPredicate.LLVMIntNE, value, LLVMConstPointerNull(getLLVMType(from)), namez);
        //     return castI1ToI8(this.rhs);
        //}
        if(from.isInteger() && to.isPointer()) {
            this.rhs = LLVMBuildIntToPtr(builder, value, toType, namez);
            return this.rhs;
        }

        if(from.isStruct() && to.isStruct()) {
            throwIf(true, "struct to struct cast should not happen. from = %s, to = %s, module = %s, function = %s", 
                from, to, mod.name, currentFunction ? currentFunction.printValueToString() : "unknown");
        }

        // Convert enums to the enum element type
        if(from.isEnum() && !to.isEnum()) {
            return castType(value, from.extract!Enum.elementType(), to, name);
        }
        if(!from.isEnum() && to.isEnum()) {
            return castType(value, from, to.extract!Enum.elementType(), name);
        }

        /// real->integer or integer->real
        if(from.isReal() != to.isReal()) {
            if(!from.isReal()) {
                /// integer->real
                this.rhs = LLVMBuildSIToFP(builder, value, toType, namez);
            } else {
                /// real->integer
                this.rhs = LLVMBuildFPToSI(builder, value, toType, namez);
            }
            return this.rhs;
        }

        /// widen or truncate
        if(from.size() < to.size()) {
            /// widen
            if(from.isReal()) {
                this.rhs = LLVMBuildFPExt(builder, value, toType, namez);
            } else {
                this.rhs = LLVMBuildSExt(builder, value, toType, namez);
            }
        } else if(from.size() > to.size()) {
            /// truncate
            if(from.isReal()) {
                this.rhs = LLVMBuildFPTrunc(builder, value, toType, namez);
            } else {
                this.rhs = LLVMBuildTrunc(builder, value, toType, namez);
            }
        } else {
            /// Size is the same
            throwIf(true, "castType: We shouldn't get here: from %s to %s", from, to);
        }
        return this.rhs;
    }
    // void callMemset(LLVMValueRef destPtr, ulong numBytes) {
    //     LLVMValueRef[] memsetArgs = [
    //         destPtr,
    //         createConstI8Value(0),
    //         createConstI32Value(numBytes),
    //         createConstI1Value(0)
    //     ];

    //     LLVMValueRef memsetValue = functionValue("llvm.memset.inline.p0.i32");
    //     LLVMTypeRef memsetType = functionType("llvm.memset.inline.p0.i32");

    //     assert(memsetValue);
    //     assert(memsetType);

    //     LLVMValueRef call = LLVMBuildCall2(builder, memsetType, memsetValue, memsetArgs.ptr, memsetArgs.length.as!uint, "");
    //     //LLVMSetInstructionCallConv(call, CallingConv.Fast);
    // }
    LLVMValueRef getStructMemberPtr(LLVMTypeRef structType, LLVMValueRef structPtr, uint memberIndex, string name = null) {
        return LLVMBuildStructGEP2(builder, structType, structPtr, memberIndex, name.toStringz());
    }
    LLVMValueRef setStructMemberValue(LLVMTypeRef structType, LLVMValueRef structPtr, LLVMValueRef value, uint memberIndex, string name = null) {
        LLVMValueRef ptr = getStructMemberPtr(structType, structPtr, memberIndex, name);
        LLVMBuildStore(builder, value, ptr);
        return ptr;
    }
    LLVMValueRef setArrayValue(LLVMValueRef arrayPtr, LLVMTypeRef elementType, LLVMValueRef value, uint index, string name=null) {
        LLVMValueRef[] indices = [createConstI32Value(index)];
        LLVMValueRef ptr = LLVMBuildInBoundsGEP2(builder, elementType, arrayPtr, indices.ptr, 1, name.toStringz());
        LLVMBuildStore(builder, value, ptr);
        return ptr;
    }
    //======================================================================== Attributes
    /**
     * Add an attribute to a function.
     * These are defined in build/include/llvm/IR/Attributes.inc
     * eg. noinline, alwaysinline, inlinehint, nounwind, hot, cold, 
     */
    void addFunctionAttribute(LLVMValueRef functionValue, string attributeName) {
        addFunctionParamAttribute(functionValue, -1, attributeName);
    }
    void addFunctionParamAttribute(LLVMValueRef functionValue, int paramIndex, string attributeName) {
        uint attrId = LLVMGetEnumAttributeKindForName(attributeName.toStringz(), attributeName.length.as!uint);
        LLVMAttributeRef attr = LLVMCreateEnumAttribute(context, attrId, 0);
        LLVMAddAttributeAtIndex(functionValue, paramIndex.as!int, attr);
    }
private:
    static struct TypeAndValue {
        LLVMTypeRef type;
        LLVMValueRef value;
    }

    TypeAndValue[string] functionDeclarations;
}
