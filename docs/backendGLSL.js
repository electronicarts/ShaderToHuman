// type Backend
class BackendGLSL {
    expandIncludes = false
}


// @param name HLSL name e.g. "float2x2|float3x3|float4x4" or "quat" or "frac"
// @return type in Code language
BackendGLSL.prototype.translateName = function(name) 
{
//    if (code === "HLSL") {        
//        if (type == "quat") return "float4";
//        return type;
//    }

    // We have preprocesssed .glsl files already 
  /*
    // types
    if (name === "float2x2") return "mat2";
    if (name === "float3x3") return "mat3";
    if (name === "float4x4") return "mat4";
    if (name === "float2") return "vec2";
    if (name === "float3") return "vec3";
    if (name === "float4") return "vec4";
    if (name === "int2") return "ivec2";
    if (name === "int3") return "ivec3";
    if (name === "int4") return "ivec4";
    if (name === "uint2") return "uvec2";
    if (name === "uint3") return "uvec3";
    if (name === "uint4") return "uvec4";
    
    if (name === "frac") return "fract";
    if (name === "lerp") return "mix";
    if (name === "rsqrt") return "inversesqrt";
    */
};