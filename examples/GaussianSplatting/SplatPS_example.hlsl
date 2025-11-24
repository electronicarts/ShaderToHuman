//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "SplatCommon.hlsl"

/*$(ShaderResources)*/


struct PSOutput
{
	// linear color, not sRGB
	float4 colorTarget : SV_Target0;
	float depth :SV_DEPTH; 
	uint coverage : SV_Coverage;
};


// @param projection also called viewToClip
float deviceDepthFromViewLinearDepth(float viewSpaceZ, float4x4 projection)
{
	// can be optimized
	float deviceDepth = (projection._34 / viewSpaceZ - projection._33) / projection._43;

	return deviceDepth;
}


PSOutput mainPS(VSOutput_Splat input)
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
		sRGBOutput.a = 1;
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
