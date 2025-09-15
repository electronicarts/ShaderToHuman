/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "SplatCommon.hlsl"

/*$(ShaderResources)*/

struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};


struct VSOutput // AKA PSInput
{
	// one splat, see struct SplatRasterizeParams
	nointerpolation float4 a : TEXCOORD0;
	nointerpolation float4 b : TEXCOORD1;
	nointerpolation float3 c : TEXCOORD2;
	// for debugging
	float2 uv : TEXCOORD3;

	// for xbox needs this to be last
	float4 position : SV_POSITION;

	// for randomization
	uint splatId : TEXCOORD4;
};

struct PSOutput
{
	// linear color, not sRGB
	float4 colorTarget : SV_Target0;
	float depth :SV_DEPTH; 
	uint coverage : SV_Coverage;
};

/*
// @param xy x:-1 / 1, y:-1 / 1
float2 computeCorner(float2 xy, float3 csConic, float2 resolution)
{
	float a = csConic.x;
	float b = 0.5f * csConic.y;
	float c = csConic.z;

	// see ShaderToy https://www.shadertoy.com/view/msGcDh
	float baseHalf = (a + c) * 0.5f;
	float rootHalf = 0.5f * sqrt((a - c) * (a - c) + 4.0f * b * b);
	float rx	   = rsqrt(baseHalf + rootHalf);
	float ry	   = rsqrt(baseHalf - rootHalf);

	float2 k = float2(a - c, 2.0f * b);

	// if splat gets thinner than a pixel, keep it pixel size for antialiasing, this works with aspectRatio
//	rx = max(rx, 1.0f / resolution.y);
//	ry = max(ry, 1.0f / resolution.x);

	// half vector, should be faster than atan()
	float2 axis0 = normalize(k + float2(length(k), 0));

	float2 axis1 = float2(axis0.y, -axis0.x);

	return (axis0 * (rx * xy.x) - axis1 * (ry * xy.y)) * float2(resolution.y / resolution.x, 1.0f);
}
*/

// @param xy to identify corner x:-1 / 1, y:-1 / 1
// @return relative pixel pos
float2 computeCornerPs(float2 xy, float3 psConic)
{
//	return float2(10,0) * xy.x - float2(0,10) * xy.y;

	float a = psConic.x;
	float b = 0.5f * psConic.y;
	float c = psConic.z;

	// see ShaderToy https://www.shadertoy.com/view/msGcDh
	float baseHalf = (a + c) * 0.5f;
	float rootHalf = 0.5f * sqrt((a - c) * (a - c) + 4.0f * b * b);
	float rx	   = rsqrt(baseHalf + rootHalf);
	float ry	   = rsqrt(baseHalf - rootHalf);

	float2 k = float2(a - c, 2.0f * b);

	// if splat gets thinner than a pixel, keep it pixel size for antialiasing, this works with aspectRatio
//	rx = max(rx, 1.0f / resolution.y);
//	ry = max(ry, 1.0f / resolution.x);

	// half vector, should be faster than atan()
	float2 axis0 = normalize(k + float2(length(k), 0));

	float2 axis1 = float2(axis0.y, -axis0.x);

	return (axis0 * (rx * xy.x) + axis1 * (ry * xy.y));
}


// @param projection also called viewToClip
float deviceDepthFromViewLinearDepth(float viewSpaceZ, float4x4 projection)
{
	// can be optimized
	float deviceDepth = (projection._34 / viewSpaceZ - projection._33) / projection._43;

	return deviceDepth;
}

// inverse of ScreenFromClip()
// for debugging
// @param deviceDepth see deviceDepthFromViewLinearDepth() and viewLinearDepthFromDeviceDepth()
// @return clipPos
float4 ClipFromScreen(float2 pixelPos, float deviceDepth)
{
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

	// float2(0..1, 0..1)
	float2 uv = pixelPos / dimensions;

	return float4(uv * float2(2, -2) - float2(1, -1), deviceDepth, 1.0f);
}

VSOutput mainVS(VSInput input)
{
	VSOutput output = (VSOutput)0;

	uint id = input.vertexId % 6;

	float2 uv = float2(0, 0);
	if(id == 1) uv = float2(1, 0);
	if(id == 2 || id == 3) uv = float2(1, 1);
	if(id == 4) uv = float2(0, 1);


	// x:-1 / 1, y:-1 / 1
	float2 xy = uv * 2.0f - 1.0f;

	uint splatId = input.instanceId;

    float2 resolution = /*$(Variable:iFrameBufferSize)*/.xy;

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

	SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);

    SplatRasterizeParams params;
    bool visible = computeSplatRasterizeParams(splatParams, params, dimensions, worldToClip, viewToClip, worldToView);

	// why - ?
	output.position = ClipFromScreen(params.psCenter, deviceDepthFromViewLinearDepth(-params.splatZ.x, viewToClip));	// todo depth
 
	float aspectRatio = resolution.x / resolution.y;
	// ps from cs scale
	float2 s = float2(2, -2) / resolution.xy;
	float invAspectRatio = viewToClip._m11 / viewToClip._m00;

	float3 psConicMul1 = params.psConicMul / log2((float)_E);
	float3 psConic = psConicMul1 / -0.5f;

	float2 cornerPos = computeCornerPs(xy, psConic) / resolution * float2(2, -2);

	output.position.xy += cornerPos * output.position.w * GAUSSIAN_CUTOFF_SCALE; 

	params.toInterpolator(output.a, output.b, output.c);

	output.uv = uv;
	output.splatId = splatId;

	return output;
}


PSOutput mainPS(VSOutput input)
{
	int2 pixPos = (int2)input.position.xy;

	SplatRasterizeParams params;

	params.fromInterpolator(input.a, input.b, input.c);

	// seems 3DGS is defined in sRGB, which seems wrong but makes porting to older platforms and the web easier
	float4 sRGBOutput = params.evaluate(input.position.xy);

//	float4 linearOutput = float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), sRGBOutput.a);
	float4 linearOutput = float4(sRGBOutput.rgb, sRGBOutput.a);

	// visualize 2D OBB (oriented bounding box = quad) around the splat that is the quad
	if(0)
	{
		float2 m = min(input.uv, 1.0f - input.uv);
		float d = min(m.x, m.y);
		bool binaryTest = d < 0.01f;
		linearOutput = lerp(linearOutput, float4(1, 0, 1, 1), binaryTest * 0.4f);
	}

	PSOutput ret = (PSOutput)0;

	// can be optimized? Looks like 3DGS is in sRGB space which seems wrong. So this is needed:
	ret.colorTarget = linearOutput;

	// Frame buffer blend is not doing this so we have to do it here
//	ret.colorTarget.rgb *= ret.colorTarget.a;
	ret.colorTarget.a = 1;

    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
	ret.depth = deviceDepthFromViewLinearDepth(-params.splatZ.x, viewToClip);

    uint rndState = initRand(dot(uint3(pixPos,0), uint3(82927, 21313, 1)), input.splatId * 12345 + 0x12345678 + /*$(Variable:frameRandom)*/ * /*$(Variable:iFrame)*/);

	// 0..1
	float rnd = nextRand(rndState);

	// no MSAA
//#if MSAA == 1
	// test

//	ret.coverage = 0x1;
//	if(sRGBOutput.a <= rnd)
//		clip(-1);
//#elif MSAA == 8
//	ret.colorTarget.rgb = 1;

//#else
	// 4: 4x MSAA
	// 8: 8x MSAA
	const uint sampleCount = 8;

	const uint sampleMask = (1u << sampleCount) - 1;

	// 0..1
//	uint step = floor(saturate(sRGBOutput.a) * (sampleCount));	// no rnd
//	uint step = floor(saturate(sRGBOutput.a) * (sampleCount - 2) + 1 + rnd);	// always one sample, nice only fopr one splat
	uint step = floor(saturate(sRGBOutput.a) * (sampleCount - 1) + rnd);	// smooth for 1..8 range, noisy in 0 range for single splat
	float steps = step / (float)sampleCount;

	uint coverage = 0xff;

#if WEIGHT_EXPERIMENT == 1

//	float quantizedAlpha = floor(saturate(1-sRGBOutput.a) * (sampleCount - 0.001f));
//	coverage = sampleMask >> (uint)floor(saturate(1-sRGBOutput.a) * (sampleCount - 0.001f) + rnd);	// todo: improve
//	coverage = sampleMask >> (uint)floor(saturate(1-sRGBOutput.a) * (sampleCount - 0.001f) + 1);	// todo: improve
	coverage = sampleMask >> (uint)(sampleCount - step);	// todo: improve


//	overage = sampleMask >> (uint)quantizedAlpha;	// todo: improve

//	coverage = 0xff;


	float fixup = sRGBOutput.a / steps;

	// at least smooth
	fixup = fixup * (1 - steps);
	// remap to be linear
	fixup = fixup / (1 - sRGBOutput.a);

/*	if(step == 0)
	{
		if(sRGBOutput.a * sampleCount <= rnd)
			coverage = 0;
		else
			coverage = 0x1;

	//	coverage = sampleMask >> (uint)floor(saturate(1-sRGBOutput.a) * (sampleCount - 0.001f) + rnd);	// todo: improve
		fixup = 1.0f;
	}
*/

	ret.colorTarget.a = fixup * FIXUP_MUL;

#else // WEIGHT_EXPERIMENT == 1

//	coverage = sampleMask >> (uint)floor(saturate(1-sRGBOutput.a) * (sampleCount - 0.001f) + rnd);	// todo: improve
	coverage = sampleMask >> (uint)(sampleCount - step);	// todo: improve

#endif

	// reference: n independent random events
	if(0)
	{
		coverage = 0;
		for(uint i = 0; i < sampleCount; ++i)
		{
			if(sRGBOutput.a > nextRand(rndState))
				coverage |= 1u << i;
		}
	}

	// reference: scramble, slow
	if(1)
	{
		for(uint i = 0; i < 20; ++i)
		{
			// 0..sampleCount-1
			uint bitN = (uint)floor(nextRand(rndState) * sampleCount);

			// flip bit0 with bitN
			bool old0 = (coverage & 1u) != 0;
			bool oldN = (coverage & (1u << bitN)) != 0;
			coverage &= ~1u;
			coverage &= ~(1u << bitN);
			if(old0)
				coverage |= (1u << bitN);			
			if(oldN)
				coverage |= 1u;

			coverage = coverage | (coverage << sampleCount);
			coverage = (coverage >> 1) & sampleMask;
		}
	}

	// random offset for overlapping primitives, could be improved further, ideally all bits are independent
	{
		coverage = coverage | (coverage << sampleCount);
		// todo: something is wrong here
		coverage = coverage >> uint((sampleCount - 0.001f) * rnd);
	}
	ret.coverage = coverage;
//#endif

	return ret;
}
