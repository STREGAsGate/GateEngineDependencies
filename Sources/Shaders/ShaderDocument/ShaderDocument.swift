/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import Foundation

public class ShaderDocument: Identifiable {
    enum DocumentType {
        case vertex
        case fragment
    }
    
    public struct Channel {
        internal let channelIndex: UInt8
        public let texture: Sampler2D
        public let scale: Vec2
        public let offset: Vec2
        public let color: Vec4
        
        internal init(channelIndex: UInt8) {
            self.channelIndex = channelIndex
            self.texture = Sampler2D(valueRepresentation: .channelAttachment(channelIndex))
            self.scale = Vec2(representation: .channelScale(channelIndex), type: .float2)
            self.offset = Vec2(representation: .channelOffset(channelIndex), type: .float2)
            self.color = Vec4(representation: .channelColor(channelIndex), type: .float2)
        }
    }
    
    let documentType: DocumentType
    internal init(documentType: DocumentType) {
        self.documentType = documentType
    }
    
    internal var customUniforms: [String: ShaderValue] = [:]
    public func sortedCustomUniforms() -> [ShaderValue] {
        return customUniforms.values.sorted {
            if case let .uniformCustom(index1, type: _) = $0.valueRepresentation {
                if case let .uniformCustom(index2, type: _) = $1.valueRepresentation {
                    return index1 < index2
                }
            }
            return false
        }
    }
    
    public enum CustomUniformScalarType {
        case bool
        case int
        case float
        internal var valueType: ValueType {
            switch self {
            case .bool:
                return .bool
            case .int:
                return .int
            case .float:
                return .float1
            }
        }
    }
    /// Creates or returns an existing custom uniform
    public func uniform<T: ShaderValue>(named name: String, as type: T.Type, scalarType: CustomUniformScalarType = .float) -> T {
        if let existing = customUniforms[name] as? T {
            return existing
        }
        
        let index = UInt8(customUniforms.count)
        let v: T
        
        switch type {
        case is Scalar.Type:
            v = Scalar(representation: .uniformCustom(index, type: .float), type: scalarType.valueType) as! T
        case is Vec2.Type:
            v = Vec2(representation: .uniformCustom(index, type: .vec2), type: .float2) as! T
        case is Vec3.Type:
            v = Vec3(representation: .uniformCustom(index, type: .vec3), type: .float3) as! T
        case is Vec4.Type:
            v = Vec4(representation: .uniformCustom(index, type: .vec4), type: .float4) as! T
        case is Mat4.Type:
            v = Mat4(representation: .uniformCustom(index, type: .mat4), type: .float4x4) as! T
        default:
            fatalError()
        }
        
        customUniforms[name] = v
        return v
    }
}
