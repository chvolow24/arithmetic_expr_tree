import Foundation


enum operation: String {
    case equal = "="
    case add = "+"
    case sub = "-"
    case mult = "*"
    case div = "/"
    case exp = "^"
    case none = ""
}

enum unaryOperation: String {
    case paren = "("
    case sin = "sin("
    case cos = "cos("
    case tan = "tan("
}
enum exprNodeType: String {
    case val = "num"
    case unOp = "unOp"
    case closeParen = "closeParen"
    case tbd = "tbd"
}

let opPri: [operation: Int8] = [
    .none : 0,
    .equal : 0,
    .add : 1,
    .sub : 1,
    .mult : 2,
    .div : 2,
    .exp : 3
]

class exprNode {
    var type: exprNodeType
    var value: Double?
    var parent: exprNode?
    var opToParent: operation
    var unOp: unaryOperation?
    var parenClosed: Bool?
    var children: [exprNode]
    var str: String {
        if type == .closeParen {
            return ") "
        }
        var unOpStr: String = ""
        if let unOpUnwrapped = unOp {
            unOpStr = unOpUnwrapped.rawValue
        }
        if let val = value {
            return unOpStr + opToParent.rawValue + " " + String(val) + " "
        } else {
            return unOpStr + opToParent.rawValue + " "
        }
    }
    init(value: Double) {
        self.type = .val
        self.value = value
        self.parent = nil
        self.opToParent = .none
        self.children = []
        self.unOp = nil
    }
    init(opToParent: operation, unOp: unaryOperation? = nil) {
        self.value = nil
        self.parent = nil
        self.opToParent = opToParent
        self.children = []
        self.unOp = unOp
        if unOp != nil {
            self.type = .unOp
        } else {
            self.type = .tbd
        }
    }
    func addChild(_ child: exprNode) {
        self.children.append(child)
        child.parent = self
    }
    
}

class exprTree {
    var head: exprNode
    var last: exprNode
    init(head: exprNode) {
        self.head = head
        self.last = head
    }
//
//    func getLast() -> exprNode {
//        if head.children.count > 0 && head.parenClosed != true {
//            let subTree = exprTree(head: head.children.last!)
//            return subTree.getLast()
//        } else {
//            return head
//        }
//    }
    
    func putValue(_ value: Double) {
        if [.val, .tbd].contains(last.type) {
            last.value = value
            last.type = .val
        } else {
            last.addChild(exprNode(value: value))
            last = last.children.last!
        }
    }
    
    func appendOp(_ op: operation) {
//        var selected = self.getLast()
        var selected = last
        while opPri[op]! <= opPri[selected.opToParent]! && selected.parent != nil{
            selected = selected.parent!
        }
        selected.addChild(exprNode(opToParent: op))
        last = selected.children.last!
    }
    
    func appendUnaryOp(_ unOp: unaryOperation) {
        var selected = last
        selected.addChild(exprNode(opToParent: .none, unOp: unOp))
        last = selected.children.last!
        last.parenClosed = false
    }
    
    func openParen() {
        self.appendUnaryOp(.paren)
    }
    
    func closeParen() {
        var selected = last
        var closeParenNode = exprNode(opToParent: .none)
        closeParenNode.type = .closeParen
        if let parent = selected.parent {
            parent.addChild(closeParenNode)
        } else {
            last.addChild(closeParenNode)
            print("Error: cannot close paren")
        }
        while true {
            if selected.type == .unOp && selected.parenClosed != true {
                selected.parenClosed = true
                if selected.parent != nil {
                    last = selected.parent!
                } else {
                    last = selected
                }
                 // TODO: cofirm this doesn't fail
                break
            }
            if selected.parent != nil {
                selected = selected.parent!
            } else {
                break
            }
        }
    }

    func stringRepr(initStr: String) -> String {
        var rStr = initStr
        rStr += head.str
        for child in head.children {
            let subTree = exprTree(head: child)
            rStr = subTree.stringRepr(initStr: rStr)
        }
        
        return rStr
    }
    
    func treeRepr(startDepth depth: Int) {
        if depth == 0 {
            print("\(head.str)")
        }
        let spaceString = String(repeating: " ", count: (depth+1) * 2)
        for child in head.children {
            print("\(spaceString)\(child.str)")
            if child.children.count > 0 {
                let subTree = exprTree(head: child)
                subTree.treeRepr(startDepth: depth+1)
            }
        }
    }
    
    func evaluate() -> Double {
        if head.children.count == 0 {
            if let headVal = head.value {
                return headVal
            } else {
                print("Error: head has no value")
                return 0
            }
        }
        for child in head.children {
            if child.value == nil && child.children.count == 0 {
                continue
            }
            let subTree = exprTree(head: child)
            let childValue = subTree.evaluate()
            if head.value == nil {
                head.value = childValue
                head.type = .val
            } else {
                
                switch child.opToParent {
                case .add:
                    head.value! += childValue
                case .sub:
                    head.value! -= childValue
                case .mult:
                    head.value! *= childValue
                case .div:
                    head.value! /= childValue
                case .exp:
                    head.value! = pow(head.value!, childValue)
                default:
                    head.value! = head.value!
                }
            }
        }
        if let headUnOp = head.unOp {
            switch headUnOp {
            case .paren:
                head.value! = head.value!
            case .sin:
                head.value! = sin(head.value!)
            case .cos:
                head.value! = cos(head.value!)
            case .tan:
                head.value! = tan(head.value!)
            }
        }
        return head.value!
    }
}

let clock = ContinuousClock()


let newHead = exprNode(opToParent: .none, unOp: .paren)
newHead.type = .unOp
var newTree = exprTree(head: newHead)

newTree.putValue(4.0)
newTree.appendOp(.add)
newTree.appendUnaryOp(.sin)
newTree.putValue(2)
newTree.closeParen()
newTree.appendOp(.exp)
newTree.putValue(5)
newTree.appendOp(.add)
newTree.appendUnaryOp(.cos)
newTree.putValue(2)
newTree.appendOp(.div)
newTree.putValue(3)
newTree.appendOp(.div)
newTree.appendUnaryOp(.sin)
newTree.appendUnaryOp(.sin)
newTree.putValue(5.521)
newTree.closeParen()
newTree.closeParen()
newTree.appendOp(.mult)
newTree.putValue(5.021412)
newTree.closeParen()
newTree.appendOp(.add)
newTree.putValue(2)
newTree.appendOp(.add)
newTree.putValue(5)
newTree.appendOp(.exp)
newTree.appendUnaryOp(.cos)
newTree.putValue(2)
newTree.appendOp(.div)
newTree.putValue(3)
newTree.appendOp(.div)
newTree.appendUnaryOp(.sin)
newTree.putValue(5.521)
newTree.closeParen()
newTree.appendOp(.mult)
newTree.putValue(5.021412)
newTree.closeParen()
newTree.appendOp(.sub)
newTree.appendUnaryOp(.tan)
newTree.putValue(2)
newTree.appendOp(.mult)
newTree.putValue(3)
newTree.appendOp(.div)
newTree.appendUnaryOp(.cos)
newTree.putValue(5.521)
newTree.closeParen()
newTree.appendOp(.mult)
newTree.putValue(5.021412)
newTree.closeParen()

let ttStringRepr = clock.measure {
    print(newTree.stringRepr(initStr: ""))
}
let ttTreeRepr = clock.measure {
    newTree.treeRepr(startDepth: 0)
}
let timetoeval = clock.measure{
    print(newTree.evaluate())
}

print("Time to string: \(ttStringRepr)")
print("Time to tree: \(ttTreeRepr)")
print("Time to evaluate: \(timetoeval)")




