module stagecoach.ast.node.Node;

import stagecoach.all;


//──────────────────────────────────────────────────────────────────────────────────────────────────
// Create a new Node. This just creates an object on the heap but can be optimised in the future
//──────────────────────────────────────────────────────────────────────────────────────────────────
T makeNode(T)(ParseState state) if(is(T: Node)) {
    T t = new T;
    if(Statement stmt = t.as!Statement) {
        stmt.tokenIndex = state.pos;
    }
    t.id = g_nodeId++;
    return t;
}
T makeNode(T)(int tokenIndex) if(is(T: Node)) {
    T t = new T;
    if(Statement stmt = t.as!Statement) {
        stmt.tokenIndex = tokenIndex;
    }
    t.id = g_nodeId++;
    return t;
}
__gshared uint g_nodeId;

//──────────────────────────────────────────────────────────────────────────────────────────────────

abstract class Node {
public:
    uint id;
    Node parent;
    Node[] children;

    // ---------------------------------------------------------------------- Abstract functions
    abstract NodeKind nodeKind();
    abstract bool isResolved();

    // ---------------------------------------------------------------------- Properties
    final bool hasChildren() { return children && children.length > 0; }
    final int numChildren() { return children.length.as!int; }
    final int index() { assert(parent !is null); return parent.children.indexOf(this); }
    final bool hasAncestor(NodeKind nk) {
        if(this.nodeKind() == nk) return true;
        if(parent !is null) return parent.hasAncestor(nk);
        return false;
    }
    final bool hasAncestor(Node n) {
        if(this is n) return true;
        if(parent !is null) return parent.hasAncestor(n);
        return false;
    }
    T getAncestor(T)() {
        if(this.isA!T) return this.as!T;
        if(parent !is null) return parent.getAncestor!T;
        return null;
    }

    // ---------------------------------------------------------------------- Navigation
    final Node first() { return hasChildren() ? children[0] : null; }
    final Node last() { return hasChildren() ? children[$-1] : null; }

    final Node prev(bool descend) {
        auto i = this.index(); assert(i!=-1);
        if(i == 0) return descend ? parent : null; 
        return parent.children[i - 1]; 
    }
    final Node next() {
        auto i = this.index(); assert(i!=-1);
        if(i == parent.children.length - 1) return null; 
        return parent.children[i + 1]; 
    }

    final Module getModule() { 
        if(this.isA!Module) return this.as!Module;
        assert(parent !is null);
        return parent.getModule();   
    }
    final Project getProject() {
        return getModule().project;
    }
    final auto range() { 
        return NodeRange(this); 
    }

    // ---------------------------------------------------------------------- Mutation
    final void add(Node child) { 
        if(child.parent) {
            child.parent.remove(child);
        }
        children ~= child;
        child.parent = this;
    }
    void addToFront(Node child) {
        if(child.parent) {
            child.parent.remove(child);
        }
        children.insertAt(0, child);
        child.parent = this;
    }
    void addAll(T)(T[] nodes) if(is(T: Node)) {
        foreach(n; nodes) add(n);
    }
    final void takeChildrenFrom(Node other) {
        children ~= other.children;
        foreach(c; other.children) c.parent = this;
        other.children.length = 0;
    }
    final void remove(Node child) {
        children.remove(child);
        child.parent = null;
    }  
    final void detach() {
        if(parent !is null) {
            parent.remove(this);
        }
    }
    final void replaceWith(Node newNode) {
        assert(parent !is null);
        assert(newNode.parent is null);

        auto i = this.index();
        parent.children[i] = newNode;
        newNode.parent = parent;
        parent = null;
    }

    final string dump(string indent = "") {
        string s;
        if(this.isA!Function && this.as!Function.name) s ~= "────────────────────────────────────────────────────────── fn '%s'\n".format(this.as!Function.name);
        if(this.isA!Struct && this.as!Struct.name) s ~= ".......................................................... struct '%s'\n".format(this.as!Struct.name);
        if(this.isA!Enum) s ~= ".......................................................... enum '%s'\n".format(this.as!Enum.name);
        s ~= "%s%s\n".format(indent, this.toString());
        foreach(c; children) {
            s ~= c.dump(indent ~ "  ");
        }
        return s;
    }
    final override size_t toHash() { return id; }
    final override bool opEquals(Object o) { 
        if(Node n = o.as!Node) return n.id == id;
        return false; 
    }
protected:

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
}

bool areResolved(T)(T[] nodes) if(is(T: Node)) {
    foreach(n; nodes) {
        if(!n.isResolved()) return false;
    }
    return true;
}

/**
 * Return a Range of children of type T
 * 
 * eg. foreach(v; node.childrenOfType!Variable) { ...}
 */
auto childrenOfType(T)(Node n) { 
    return n.children.filter!(it=>it.isA!T).map!(it=>it.as!T); 
}

/**
 * Usage:
 *   node.range().filter!(it=>...).map!(it=>...).array;
 */
struct NodeRange {
    this(Node n) {
        stack.reserve(16);
        stack ~= NI(n, -1);
        fetchNext();
    }
    Node front() { return _front; }
    bool empty() { return _front is null; }
    void popFront() { fetchNext(); }
private:
    void fetchNext() {
        while(stack.length > 0) {

            NI* s = &stack[$-1];
            Node n = s.node;
            int i = s.i++;

            if(i == -1) {
                _front = n;
                return;

            } else if(i < n.numChildren()) {
                stack ~= NI(n.children[i], -1);
            } else {
                stack.length--;
            }
        }
        _front = null;
    }

    struct NI {
        Node node;
        int i;
    }
    NI[] stack;
    Node _front;
}
