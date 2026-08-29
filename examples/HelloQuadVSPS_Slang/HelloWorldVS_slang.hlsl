//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

#include "../../include/s2h.hlsl"

//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

struct VSOutput // AKA PSInput
{
	float2 uv : TEXCOORD0;

	// object space
	float3 osPos : TEXCOORD1;

	// clip space, for xbox needs this to be last
	float4 csPos : SV_POSITION;
};


VSOutput computeVS(uint vertexId, float4x4 worldToClip, float4x4 worldToView)
{
	VSOutput output = (VSOutput) 0;
	uint id = vertexId % 6;

	float2 uv = float2(0, 0);
	if (id == 1)
		uv = float2(1, 0);
	if (id == 2 || id == 3)
		uv = float2(1, 1);
	if (id == 4)
		uv = float2(0, 1);
	

	// x:-1 / 1, y:-1 / 1
//	float2 xy = uv * 2.0f - 1.0f;
	float2 xy = uv * 2.0f + 1;

	output.osPos = float3(xy, 0);
	output.csPos = mul(worldToClip, float4(output.osPos, 1));

	output.uv = float2(uv.x, 1 - uv.y);

	return output;
}



struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};


VSOutput mainVS(VSInput input)
{
    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

	return computeVS(input.vertexId, worldToClip, worldToView);
}
