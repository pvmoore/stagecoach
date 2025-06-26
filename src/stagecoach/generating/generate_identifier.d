module stagecoach.generating.generate_identifier;

import stagecoach.all;

void generateIdentifier(Identifier n, GenerateState state) {
    //log("Generating identifier %s %s", n.name, n.getType());
    if(n.target.isMember()) {
        Variable v = n.target.var; assert(v);
        Struct st = v.parent.as!Struct; assert(st);

        auto index = st.getMemberIndex(v);
        state.lhs = LLVMBuildStructGEP2(state.builder, state.getLLVMType(st), state.lhs, index, "gep");
        state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(n.getType()), state.lhs, n.name.toStringz());
    } else {
        if(n.target.isFunction()) {
            state.rhs = n.target.getLLVMValue();
            state.lhs = state.rhs;
            assert(state.lhs.isPointer());
        } else {
            state.lhs = n.target.getLLVMValue(); assert(state.lhs);
            state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(n.getType()), state.lhs, n.name.toStringz());
        }
    }
}
