/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

#include "../../include/s2h.hlsl"
#include "QuadCommon.hlsl"

struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};


struct PSOutput
{
	// linear color, not sRGB
	float4 colorTarget : SV_Target0;
};

VSOutput mainVS(VSInput input)
{
    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

	return computeVS(input.vertexId, worldToClip, worldToView);
}

PSOutput mainPS(VSOutput input)
{
	float4 linearOutput = float4(0, 0, 0, 1);

	// visualize 2D OBB (oriented bounding box = quad)
	if(1)
	{
		float2 m = min(input.uv, 1.0f - input.uv);
		float d = min(m.x, m.y);
		bool binaryTest = d < 0.01f;
		linearOutput = lerp(linearOutput, float4(1, 0, 1, 1), binaryTest * 0.4f);
	}

	PSOutput ret = (PSOutput)0;

	// can be optimized? Looks like 3DGS is in sRGB space which seems wrong. So this is needed:
	ret.colorTarget = linearOutput;

	struct ContextGather ui;
	s2h_init(ui, input.uv * 128);
	s2h_setCursor(ui, float2(10, 10));
	s2h_printTxt(ui, 'C', 'a', 'm', 'e', 'r', 'a');
	s2h_printTxt(ui, 'P', 'o', 's', ':');
	s2h_printLF(ui);
	s2h_printLF(ui);
	s2h_printSpace(ui, 2);
	s2h_printFloat(ui, /*$(Variable:CameraPos)*/.x);
	s2h_printLF(ui);
	s2h_printSpace(ui, 2);
	s2h_printFloat(ui, /*$(Variable:CameraPos)*/.y);
	s2h_printLF(ui);
	s2h_printSpace(ui, 2);
	s2h_printFloat(ui, /*$(Variable:CameraPos)*/.z);
	s2h_printLF(ui);
	s2h_printLF(ui);
	s2h_printTxt(ui, 'C', 'a', 'm', 'e', 'r', 'a');
	s2h_printTxt(ui, 'A', 'n', 'g', 'l', 'e', 's');
	s2h_printTxt(ui, ':');
	s2h_printLF(ui);
	s2h_printLF(ui);
	s2h_printSpace(ui, 2);
	s2h_printFloat(ui, /*$(Variable:CameraAltitudeAzimuth)*/.x);
	s2h_printLF(ui);
	s2h_printSpace(ui, 2);
	s2h_printFloat(ui, /*$(Variable:CameraAltitudeAzimuth)*/.y);
	s2h_printLF(ui);

	// play around with the Near and Far Z in Gigi Viewer "System Variables" under "Camera Settings"
	float4 visualizeZ = float4(input.csPos.zzz, 1);	// black:zFar, white:zNear

	s2h_drawRectangle(ui, float2(10, 98), float2(64 - 5, 118), visualizeZ);
	ui.pxCursor = float2(10, 98) + 3;
	s2h_printTxt(ui, 'X');

	float4 visualizeW = float4(frac(input.csPos.www), 1);

	s2h_drawRectangle(ui, float2(64 + 5, 98), float2(118, 118), visualizeW);
	ui.pxCursor = float2(64 + 5, 98) + 3;
	s2h_printTxt(ui, 'f', 'r', 'a', 'c', 'W');

	ret.colorTarget = lerp(ret.colorTarget, float4(ui.dstColor.rgb,1), ui.dstColor.a);

	// Frame buffer blend is not doing this so we have to do it here
//	ret.colorTarget.rgb *= ret.colorTarget.a;

	return ret;
}
