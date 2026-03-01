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
	// clip space, for xbox needs this to be last
	float4 csPos : SV_POSITION;
};

struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
};


VSOutput mainVS(VSInput input)
{
	uint id = input.vertexId % 6;

	float2 uv = float2(0, 0);
	if (id == 1)
		uv = float2(1, 0);
	if (id == 2 || id == 3)
		uv = float2(1, 1);
	if (id == 4)
		uv = float2(0, 1);

	// x:-1 / 1, y:-1 / 1
	float2 xy = uv * 2.0f - 1.0f;
	
	VSOutput ret;

	ret.csPos = float4(xy, 0.5f, 1.0f);
	
	return ret;
}
