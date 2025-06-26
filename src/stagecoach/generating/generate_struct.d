module stagecoach.generating.generate_struct;

import stagecoach.all;

void generateStruct(Struct s, GenerateState state) {
    s.llvmType = state.getLLVMType(s);
}

/**
 * Set the default values for a default initialised Struct.
 */
void defaultInitialiseStruct(Struct s, LLVMValueRef structPtr, GenerateState state, bool isTopLevel = true) {
    LLVMTypeRef structType = state.getLLVMType(s);

    // state.log("Default initialising struct %s", s.name);
    //state.log("%s structSize = %s", s.name ? s.name : "(anon)", LLVMABISizeOfType(state.targetData, structType));
    //state.log("%s alignment = %s", s.name, LLVMPreferredAlignmentOfType(state.targetData, structType));

    // Zero initialise the struct if this is the top level struct
    if(isTopLevel) {
        LLVMBuildMemSet(state.builder, structPtr, state.createConstIntValue(state.INT8_TYPE, 0), state.createConstIntValue(state.INT64_TYPE, s.getSize()), 8);
    }

    // Set default member values if they are specified
    foreach(v; s.members()) {
        if(v.hasInitialiser()) {
            string name = "%s.%s-gep".format(s.name, v.name);
            state.generate(v.initialiser());
            state.castType(state.rhs, v.initialiser().getType(), v.getType());
        
            state.lhs = state.setStructMemberValue(structType, structPtr, state.rhs, v.index.as!uint, name);
        } else {
            // If this is a Struct value then we need to recursively initialise this as well
            Struct st = v.getType().extract!Struct;
            if(st && v.getType().isValue()) {
                string name = "%s.%s-gep".format(s.name, v.name);
                LLVMValueRef memberPtr = state.getStructMemberPtr(structType, structPtr, v.index.as!uint, name);
                defaultInitialiseStruct(st, memberPtr, state, false);
            }
        }
    }
}


void generateStructLiteral(StructLiteral n, GenerateState state) {

    Struct st = n.getStruct();
    Variable[] variables = st.members();
    Expression[] expressions = n.members();
    LLVMValueRef[] elements = new LLVMValueRef[variables.length];

    // Allocate a local struct value
    LLVMValueRef tempStruct = LLVMBuildAlloca(state.builder, state.getLLVMType(st), "struct_literal");

    // Zero initialise the struct here and only set default values if there is an initialiser
    LLVMBuildStore(state.builder, LLVMConstNull(state.getLLVMType(st)), tempStruct);

    // Generate the element values
    int eid;
    foreach(i, v; variables) {

        Expression e;

        if(v.isConst) {
            assert(v.hasInitialiser());
        } else if(n.hasNamedArguments()) {
            e = n.getMember(v.name);
        } else if(eid < expressions.length) {
            e = expressions[eid++];
        }

        if(e) {
            state.generate(e);
            state.castType(state.rhs, e.getType(), v.getType());
            elements[i] = state.rhs;
        } else {
            // Set to default initialiser if there is one
            if(v.hasInitialiser()) {
                state.generate(v.initialiser());
                state.castType(state.rhs, v.initialiser().getType(), v.getType());
                elements[i] = state.rhs;
            } else {
                elements[i] = null;
            }
        }
    }

    // Set the local struct member values
    foreach(i, e; elements) {
        if(e) {
            state.lhs = LLVMBuildStructGEP2(state.builder, state.getLLVMType(st), tempStruct, i.as!uint, "gep");
            LLVMBuildStore(state.builder, e, state.lhs);
        } 
    }

    // Point to the struct
    state.lhs = tempStruct;
    state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(st), state.lhs, "struct_literal");
}
