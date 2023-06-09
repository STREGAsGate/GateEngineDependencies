/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

public class GLSLCodeGenerator: CodeGenerator {
    public enum GLSLVersion: CustomStringConvertible {
        case v300es
        case v300core
        
        public var description: String {
            switch self {
            case .v300core:
                return "#version 300 core"
            case .v300es:
                return "#version 300 es"
            }
        }
    }
    
    override func type(for valueType: ValueType) -> String {
        switch valueType {
        case .texture2D:
            return "sampler2D"
        case .operation:
            fatalError("operation has no type.")
        case .bool:
            return "bool"
        case .int:
            return "int"
        case .float1:
            return "float"
        case .float2:
            return "vec2"
        case .float3:
            return "vec3"
        case .float4:
            return "vec4"
        case .float3x3:
            return "mat3"
        case .float4x4:
            return "mat4"
        }
    }
    
    public override func variable(for representation: ValueRepresentation) -> String {
        switch representation {
        case .operation, .vec2, .vec3, .vec4, .mat4:
            fatalError("Shouldn't be asking for a name")
            
        case .vertexInstanceID:
            return "iid"
        case let .vertexInPosition(index):
            return "iPos\(index)"
        case let .vertexInTexCoord0(index):
            return "iUV\(index)_0"
        case let .vertexInTexCoord1(index):
            return "iUV\(index)_1"
        case let .vertexInNormal(index):
            return "iNml\(index)"
        case let .vertexInTangent(index):
            return "iTan\(index)"
        case let .vertexInColor(index):
            return "iClr\(index)"
        case .vertexOutPosition:
            return "gl_Position"
        case .vertexOutPointSize:
            return "gl_PointSize"
        case let .vertexOut(name):
            return "io_\(name)"
            
        case .fragmentInstanceID:
            return "iid"
        case let .fragmentIn(name):
            return "io_\(name)"
        case .fragmentOutColor:
            return "fClr"
            
        case .uniformModelMatrix:
            return "mMtx"
        case .uniformViewMatrix:
            return "vMtx"
        case .uniformProjectionMatrix:
            return "pMtx"
        case let .uniformCustom(index, type: _):
            return "u\(index)"
            
        case let .scalarBool(bool):
            return "\(bool)"
        case let .scalarInt(int):
            return "\(int)"
        case let .scalarFloat(float):
            return "\(float)"
            
        case let .vec2X(vec):
            return variable(for: vec) + ".x"
        case let .vec2Y(vec):
            return variable(for: vec) + ".y"
            
        case let .vec3X(vec):
            return variable(for: vec) + ".x"
        case let .vec3Y(vec):
            return variable(for: vec) + ".y"
        case let .vec3Z(vec):
            return variable(for: vec) + ".z"
            
        case let .vec4W(vec):
            return variable(for: vec) + ".w"
        case let .vec4X(vec):
            return variable(for: vec) + ".x"
        case let .vec4Y(vec):
            return variable(for: vec) + ".y"
        case let .vec4Z(vec):
            return variable(for: vec) + ".z"
            
        case let .channelAttachment(index: index):
            return "materials[\(index)].texture"
        case let .channelScale(index):
            return "materials[\(index)].scale"
        case let .channelOffset(index):
            return "materials[\(index)].offset"
        case let .channelColor(index):
            return "materials[\(index)].color"
        }
    }
    
    override func function(for operation: Operation) -> String {
        switch operation.operator {
        case .add, .subtract, .multiply, .divide, .compare(_):
            return "\(variable(for: operation.lhs)) \(symbol(for: operation.operator)) \(variable(for: operation.rhs))"
        case .branch(comparing: _):
            fatalError()
        case .sampler2D(filter: _):
            return "texture(\(variable(for: operation.lhs)),\(variable(for: operation.rhs)))"
        case let .lerp(factor: factor):
            return "mix(\(variable(for: operation.lhs)), \(variable(for: operation.rhs)), \(variable(for: factor)))"
        }
    }
    
    private func generateShaderCode(from vertexShader: VertexShader, attributes: [InputAttribute]) throws -> String {
        var customUniformDefine: String = ""
        for value in vertexShader.sortedCustomUniforms() {
            customUniformDefine += "\nuniform \(type(for: value.valueType)) \(variable(for: value));"
        }
        
        var vertexGeometryDefine: String = ""
        for attributeIndex in attributes.indices {
            let attribute = attributes[attributeIndex]
            switch attribute {
            case .vertexInPosition(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float3)) \(variable(for: .vertexInPosition(geometryIndex)));"
            case .vertexInTexCoord0(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float2)) \(variable(for: .vertexInTexCoord0(geometryIndex)));"
            case .vertexInTexCoord1(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float2)) \(variable(for: .vertexInTexCoord1(geometryIndex)));"
            case .vertexInNormal(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float3)) \(variable(for: .vertexInNormal(geometryIndex)));"
            case .vertexInTangent(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float3)) \(variable(for: .vertexInTangent(geometryIndex)));"
            case .vertexInColor(geoemtryIndex: let geometryIndex):
                vertexGeometryDefine += "\nlayout(location = \(attributeIndex)) in \(type(for: .float4)) \(variable(for: .vertexInColor(geometryIndex)));"
            }
        }
        vertexGeometryDefine += "\nlayout(location = \(attributes.count)) in \(type(for: .float4x4)) \(variable(for: .uniformModelMatrix));"
        
        var materialDefines: String = ""
        for index in vertexShader.channels.indices {
            materialDefines += """
        uniform \(type(for: .float4)) \(variable(for: .channelColor(UInt8(index))));
        uniform \(type(for: .float2)) \(variable(for: .channelScale(UInt8(index))));
        uniform \(type(for: .float2)) \(variable(for: .channelOffset(UInt8(index))));
        """
        }
        
        var outVariables: String = ""
        for pair in vertexShader.output._values {
            outVariables += "\nout \(type(for: pair.value)) \(variable(for: .vertexOut(pair.key)));"
        }
        
        self.prepareForReuse()
        return """
\(version)
precision highp \(type(for: .float1));

uniform \(type(for: .float4x4)) \(variable(for: .uniformViewMatrix));
uniform \(type(for: .float4x4)) \(variable(for: .uniformProjectionMatrix));\(customUniformDefine)

struct Material {
    \(type(for: .float2)) offset;
    \(type(for: .float2)) scale;
    \(type(for: .float4)) color;
    \(type(for: .texture2D)) texture;
};
uniform Material materials[16];

\(vertexGeometryDefine)
\(outVariables)

void main() {
\(generateMain(from: vertexShader))}
"""
    }
    
    private func generateShaderCode(from fragmentShader: FragmentShader) throws -> String {
        var customUniformDefine: String = ""
        for value in fragmentShader.sortedCustomUniforms() {
            customUniformDefine += "\nuniform \(type(for: value)) \(variable(for: value));"
        }
        
        var inVariables: String = ""
        for pair in fragmentShader.input._values {
            inVariables += "\nin \(type(for: pair.value)) \(variable(for: .fragmentIn(pair.key)));"
        }
        
        var materialDefines: String = ""
        for index in fragmentShader.channels.indices {
            materialDefines += """
        uniform \(type(for: .float4)) \(variable(for: .channelColor(UInt8(index))));
        uniform \(type(for: .float2)) \(variable(for: .channelScale(UInt8(index))));
        uniform \(type(for: .float2)) \(variable(for: .channelOffset(UInt8(index))));
        uniform \(type(for: .texture2D)) \(variable(for: .channelAttachment(UInt8(index))));
        """
        }
        
        self.prepareForReuse()
        return """
\(version)
precision highp \(type(for: .float1));
\(customUniformDefine)
\(inVariables)

layout(location = 0) out \(type(for: .float4)) \(variable(for: .fragmentOutColor));

struct Material {
    \(type(for: .float2)) offset;
    \(type(for: .float2)) scale;
    \(type(for: .float4)) color;
    \(type(for: .texture2D)) texture;
};
uniform Material materials[16];

void main() {
\(generateMain(from: fragmentShader))}
"""
    }

    let version: GLSLVersion
    public required init(version: GLSLVersion) {
        self.version = version
    }
    
    
    public func generateShaderCode(vertexShader: VertexShader, fragmentShader: FragmentShader, attributes: [InputAttribute]) throws -> (vertexSource: String, fragmentSource: String) {
        try validate(vsh: vertexShader, fsh: fragmentShader)
        let vsh = try generateShaderCode(from: vertexShader, attributes: attributes)
        let fsh = try generateShaderCode(from: fragmentShader)
        return (vsh, fsh)
    }
    
    public func addingLineNumbers(_ string: String) -> String {
        var string = string
        var count = 0
        for index in string.indices {
            if string[index] == "\n" {
                count += 1
            }
        }
        for index in string.indices.reversed() {
            if string[index] == "\n" || index == string.startIndex {
                var countS = "\(count) "
                while countS.count < 4 {
                    countS = " " + countS
                }
                string.insert(contentsOf: countS, at: index == string.startIndex ? index : string.index(after: index))
                count -= 1
            }
        }
        return string
    }
}
