#ifndef S2H_GLSL
#define S2H_GLSL 1

#define int2 ivec2
#define int3 ivec3
#define int4 ivec4
#define uint2 uvec2
#define uint3 uvec3
#define uint4 uvec4
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define float3x3 mat3
#define float4x4 mat4
#define atan2 atan
#define lerp mix
#define rsqrt inversesqrt
#define static
#define mul(a,b) (a) * (b)
#define sincos(x,s,c) {s=sin(x);c=cos(x);}
#define saturate(x) clamp(x,0.0f,1.0f)
#define frac(x) fract(x)
#define asuint floatBitsToUint
#define asfloat uintBitsToFloat
#define groupshared shared
#define WaveActiveSum subgroupAdd
#define WaveGetLaneCount() gl_SubgroupSize
#define WaveActiveCountBits(x) subgroupBallotBitCount(uvec4(x,0,0,0))
#define WaveIsFirstLane subgroupElect
#define GroupMemoryBarrierWithGroupSync barrier
#define f32tof16(f) packHalf2x16(vec2(f, 0))
#define f16tof32(u) unpackHalf2x16(u).x

#endif // S2H_GLSL
