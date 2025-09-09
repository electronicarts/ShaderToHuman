/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

struct VSOutput // AKA PSInput
{
	float2 uv : TEXCOORD0;

	// object space
	float3 osPos : TEXCOORD1;

	// view space
	float4 vsPos : TEXCOORD2;

	// clip space, for xbox needs this to be last
	float4 csPos : SV_POSITION;
};


VSOutput computeVS(uint vertexId, float4x4 worldToClip, float4x4 worldToView)
{
	VSOutput output = (VSOutput)0;
	uint id = vertexId % 6;

	float2 uv = float2(0, 0);
	if(id == 1) uv = float2(1, 0);
	if(id == 2 || id == 3) uv = float2(1, 1);
	if(id == 4) uv = float2(0, 1);
	

	// x:-1 / 1, y:-1 / 1
//	float2 xy = uv * 2.0f - 1.0f;
	float2 xy = uv * 2.0f + 1;

	output.osPos = float3(xy, 0);
	output.vsPos = mul(worldToView, float4(output.osPos, 1));
	output.csPos = mul(worldToClip, float4(output.osPos, 1));

	output.uv = float2(uv.x, 1 - uv.y);

	return output;
}
