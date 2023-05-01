/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

public final class Operation: ShaderElement {
    var operation: Operation? {
        return self
    }
    let valueRepresentation: ValueRepresentation = .operation
    let valueType: ValueType = .operation
    
    public enum Operator {
        case add
        case subtract
        case multiply
        case divide
        
        public enum Comparison {
            case equal
            case notEqual
            case greater
            case greaterEqual
            case less
            case lessEqual
            case and
            case or
        }
        case compare(_ comparison: Comparison)
        
        case branch(comparing: Scalar)
        case sampler2D(filter: Sampler2D.Filter)
        case lerp(factor: Scalar)
    }
    let lhs: ShaderValue
    let `operator`: Operator
    let rhs: ShaderValue
        
    public init(lhs: Scalar, operator: Operator, rhs: Scalar) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Vec2, operator: Operator, rhs: Vec2) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Vec3, operator: Operator, rhs: Vec3) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Vec4, operator: Operator, rhs: Vec4) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Mat3, operator: Operator, rhs: Vec3) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Mat3, operator: Operator, rhs: Mat3) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Mat4, operator: Operator, rhs: Vec4) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    public init(lhs: Mat4, operator: Operator, rhs: Mat4) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    internal init(lhs: Sampler2D, rhs: Vec2, operator: Operator) {
        self.lhs = lhs
        self.operator = `operator`
        self.rhs = rhs
    }
    
    internal init<T: ShaderValue>(lhs: T, comparison: Operator.Comparison, rhs: T) {
        self.lhs = lhs
        self.operator = .compare(comparison)
        self.rhs = rhs
    }
    
    internal init<T: ShaderValue>(compare: Scalar, success: T, failure: T) {
        self.lhs = success
        self.operator = .branch(comparing: compare)
        self.rhs = failure
    }
}
