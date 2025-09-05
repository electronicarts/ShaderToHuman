// type Backend
class BackendGLM {
}


// @param type HLSL name e.g. "float2x2|float3x3|float4x4" or "quat"
// @return type in Code language
BackendGLM.prototype.translateName = function(type) 
{
    if (type === "float2x2") return "glm::mat2";
    if (type === "float3x3") return "glm::mat3";
    if (type === "float4x4") return "glm::mat4";
    if (type === "float") return "float";
    if (type === "float2") return "glm::vec2";
    if (type === "float3") return "glm::vec3";
    if (type === "float4") return "glm::vec4";
    if (type === "int2") return "glm::ivec2";
    if (type === "int3") return "glm::ivec3";
    if (type === "int4") return "glm::ivec4";
    if (type === "uint2") return "glm::uvec2";
    if (type === "uint3") return "glm::uvec3";
    if (type === "uint4") return "glm::uvec4";

    if (type === "quat") return "glm::quat";

/*    if (code === "glm-js") {
        if (type === "float2x2") return "glm.mat2";
        if (type === "float3x3") return "glm.mat3";
        if (type === "float4x4") return "glm.mat4";
        if (type === "float") return "float";
        if (type === "float2") return "glm.vec2";
        if (type === "float3") return "glm.vec3";
        if (type === "float4") return "glm.vec4";
        if (type === "quat") return "glm.quat";
    }
*/
};