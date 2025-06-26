module stagecoach.ast.Expression;

import stagecoach.all;

abstract class Expression : Statement {
public:
    abstract int precedence(); 

    final bool isStartOfChain() {
        if(!parent.isA!Dot) return true;
        if(index()!=0) return false;

        return parent.as!Dot.isStartOfChain();
    }
    /**
     * Get the previous link in the chain. Assumes there is one.
     */
    final Expression prevLink() {
        if(!parent.isA!Dot) return null;
        if(isStartOfChain()) return null;

        auto prev = prev(false);
        if(prev) {
            return prev.as!Expression;
        }
        assert(parent.parent.isA!Dot);
        return parent.parent.as!Dot.container();
    }

    final Expression getEndOfChain() {
        if(Dot dot = this.as!Dot) {
            return dot.member().getEndOfChain();
        }
        return this;
    }

protected:
}
