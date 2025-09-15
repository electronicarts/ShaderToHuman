/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

// OpenGL style math !

// 1.0f/256.0f is good for 8 bit, up to 1.0f, useful for testing
#define ALPHA_CUTOFF (1.0f/256.0f)

// see https://www.shadertoy.com/view/Xc2XRz
// the bounding primitive for the gaussian is a ellipsoid at the cutoff values
// this factor is computed to account for this when computing the bounds
// for float power	 = -0.5f * dot(..
#define GAUSSIAN_CUTOFF_SCALE (sqrt(2 * log(1.0f / ALPHA_CUTOFF)))

#define _E			2.7182818284590452353602874713527
#ifndef FLT_MAX 
#define FLT_MAX		3.402823466e+38
#endif

// around sqrt(2), depending on other settings, todo: revise
#define MIN_PIXEL_RADIUS 1.0f

#define FIXUP_MUL 0.25f
// 0: off
// 1: on (not working, dead end?)
#define WEIGHT_EXPERIMENT 0

struct SplatParams
{
	//
	float4 colorAndAlpha;
	// in object space
	float3 pos;
	// rotation in object space, quaternion, should be normalized
	float4 rot;
	// >=0
	float3 linearScale;
};

float2x2 inverse(float2x2 m)
{
	float a = m[0][0], b = m[0][1], c = m[1][0], d = m[1][1];
	return (1.0 / (a*d - b*c))*float2x2(d, -b, -c, a);
}

//
float4x4 construct4x4(float4 a, float4 b, float4 c, float4 d)
{
	float4x4 ret = { a, b, c, d };
	return transpose(ret);
}

float3x3 construct3x3(float3 a, float3 b, float3 c)
{
	float3x3 ret = { a, b, c };
	return transpose(ret);
}

float4x4 scale4x4(float3 s)
{
	return construct4x4(float4(s.x, 0, 0, 0), float4(0, s.y, 0, 0), float4(0, 0, s.z, 0), float4(0, 0, 0, 1));
}

float4x4 translate4x4(float3 p)
{
	return construct4x4(float4(1, 0, 0, 0), float4(0, 1, 0, 0), float4(0, 0, 1, 0), float4(p, 1));
}

// SRT: scale rotation translate
// @param s non uniform scale 
// @param r rotation as 3x3 matrix, can already include scale
// @param t translation
float4x4 constructSRT(float3 s, float3x3 r, float3 t)
{
	float4x4 rot4x4 = {
		float4(r[0], 0),
		float4(r[1], 0),
		float4(r[2], 0),
		float4(0, 0, 0, 1)
	};

	return mul(translate4x4(t), mul(rot4x4, scale4x4(s)));
}

// @param pixelSize a value around 1 is for AA, larger values can be used for Depth of Field
// @param viewDimensions xy, 1.0 / xy
// @param alpha this is a inout todo: confusing API
// @return psConic clip pixel space
float3 computeConicPs(float4x4 objectToWorld, float4x4 worldToView, float4x4 viewToClip, float4 viewDimensions, float pixelSize, float coc, inout float alpha)
{
	// just reading 3 floats
	float3 wsCenterPos = mul(objectToWorld, float4(0, 0, 0, 1)).xyz;
	float4 vsCenterPosHom = mul(worldToView, float4(wsCenterPos, 1));
	float3 vsCenterPos	  = vsCenterPosHom.xyz;

	// covariance Matrix in world space, symmetric, can be optimized
	float3x3 wsBigSigma = mul((float3x3)objectToWorld, transpose((float3x3)objectToWorld));

	// covariance Matrix in view space, symmetric, can be optimized
	float3x3 W			= (float3x3)worldToView;
	float3x3 vsBigSigma = mul(W, mul(wsBigSigma, transpose(W)));

	float2 focalLength = float2(viewToClip._m11, viewToClip._m11);

	// the following lines are copied from https://github.com/aras-p/UnityGaussianSplatting/blob/main/Assets/GaussianSplatting/Shaders/GaussianSplatting.hlsl
	float tanFovX = rcp(viewToClip._m00);
	float tanFovY = rcp(viewToClip._m11);
	float limX	  = 1.3 * tanFovX;
	float limY	  = 1.3 * tanFovY;
	vsCenterPos.x = clamp(vsCenterPos.x / vsCenterPos.z, -limX, limX) * vsCenterPos.z;
	vsCenterPos.y = clamp(vsCenterPos.y / vsCenterPos.z, -limY, limY) * vsCenterPos.z;

	// Jacobian of perspective matrix = affine approximation at location csCenterPos
	// we only need 2x2 part
	float3x3 J = float3x3(
		focalLength.x / vsCenterPos.z, 0, -(focalLength.x * vsCenterPos.x) / (vsCenterPos.z * vsCenterPos.z),
		0, focalLength.y / vsCenterPos.z, -(focalLength.y * vsCenterPos.y) / (vsCenterPos.z * vsCenterPos.z),
		0, 0, 0);
	
	float2x2 csBigSigma = (float2x2)mul(J, mul(vsBigSigma, transpose(J)));

	// for AA
	if(1)
	{
		float invResolution2y = viewDimensions.w * viewDimensions.w;

		csBigSigma._m00 += pixelSize * pixelSize * invResolution2y;
		csBigSigma._m11 += pixelSize * pixelSize * invResolution2y;

		float before = determinant(csBigSigma);

		// Apply low-pass filter: every Gaussian should be at least
		// one pixel wide/high. Discard 3rd row and column.
		csBigSigma._m00 += coc * coc * invResolution2y;
		csBigSigma._m11 += coc * coc * invResolution2y;

		float after = determinant(csBigSigma);

		// larger splats should get fainter
		alpha *= before / after;
	}

	// result is symmetrical so it can be stored in 3 coefficients, one coefficient is there twice => *2
	float2x2 invCov = inverse((float2x2)csBigSigma);

	float3 csConic = float3(invCov._m00, 2 * invCov._m01, invCov._m11);

	// ps from cs scale
	float2 s = float2(2, -2) * viewDimensions.zw;

	// todo: is this resolution.y/resolution.x ? can we optimize
	float invAspectRatio = viewToClip._m11 / viewToClip._m00;

	float3 csConic2 = float3(csConic.x * invAspectRatio * invAspectRatio, csConic.y * invAspectRatio, csConic.z); 
 	float3 psConic = float3(csConic2.x * s.x * s.x, csConic2.y * s.x * s.y, csConic2.z * s.y * s.y); 

	return psConic;
}

// @param projection also called viewToClip
float viewLinearDepthFromDeviceDepth(float deviceDepth, float4x4 projection)
{
	float viewSpaceZ = projection._34 / (deviceDepth * projection._43 + projection._33);
	return viewSpaceZ;
}

// compute as much as possible to allow for efficient evaluation of a single splat
// from screen space position
struct SplatRasterizeParams 
{
	// not premultiplied e.g. float4(premultipliedColor.rgb / (premultipliedColor.w + 0.0001f), premultipliedColor.w);
	float4 colorAndAlpha;
	// pixel space
	float2 psCenter;
	// float2(centerZ, widthZ), needed for GOBuffer, in world space units
	float2 splatZ;
	// pixel space mul -0.5 and multiplier to use exp2 instead of exp() which is faster
	float3 psConicMul;

	// @param wsRotMulScale from splat
	// @param wsPos from splat
	// @param widthZ ~ length(wsScale[0]), this assumes uniform scale so it's just a crude approximation
	// @param colorAndAlpha from splat, .a = el.linearOpacity * g_constants.getOpacityScale()
	// @param viewDimensions x, y, 1/x, /1y
	// @param cof circle of confusion for depth of field
	void setup(
		float3x3 wsRotMulScale, float3 wsPos, float widthZ, float4 inColorAndAlpha,
		float4x4 viewToClip, float4x4 worldToClip, float4x4 worldToView, float4 viewDimensions, float cof = 0)
	{
		float4x4 objectToWorld = constructSRT(1, wsRotMulScale, wsPos);

		float3 worldPos = wsPos;

		float4 positionHom = mul(worldToClip, float4(worldPos, 1));
		float3 position = positionHom.xyz / positionHom.w;

		// todo: why - ?
		float depth = -viewLinearDepthFromDeviceDepth(position.z, viewToClip);

		colorAndAlpha = inColorAndAlpha;

		// fixes NaN, could be moved to C++
		colorAndAlpha.a = max(0, colorAndAlpha.a);

		float2 centerPixelPos = (position.xy * float2(0.5f, -0.5f) + 0.5f) * viewDimensions.xy;

		psCenter = centerPixelPos;
		splatZ = float2(depth, widthZ);

		float3 psConic = computeConicPs(objectToWorld, worldToView, viewToClip, viewDimensions, MIN_PIXEL_RADIUS, cof, colorAndAlpha.a);

		float3 psConicMul1 = -0.5f * psConic;
		// exp2() is faster than exp() so we move the multiplied into the constants
		// exp(power) = exp2(power * log2(_E))
		psConicMul = psConicMul1 * log2((float)_E);		
	}

	// @param psPos e.g. ClipFromScreen(input.position.xy, 1).xy, no need to be interpolated with perspective
	// @return premultiplied RGBA in sRGB space
	float4 evaluate(float2 psPos)
	{
		float2 d = psPos - psCenter;
		float power	 = dot(psConicMul, float3(d.x * d.x, d.x * d.y, d.y * d.y));

		// Note: exp2() is faster than exp()
		// exp(power) = exp2(power * log2(_E))
		float alpha = saturate(exp2(power));

		// uncomment to visualize quad
	//	alpha = alpha * 0.5f + 0.5f;

		// only needed if ALPHA_CUTOFF is larger or many quads accumulate and we want to avoid the quad shape appearing
		if (alpha < ALPHA_CUTOFF)
			alpha = 0.0f;

		return float4(colorAndAlpha.rgb, colorAndAlpha.a * alpha);
	}

	void toInterpolator(out float4 a, out float4 b, out float3 c)
	{
		a = colorAndAlpha;
		b = float4(psCenter, splatZ);
		c = psConicMul;
	}

	void fromInterpolator(float4 a, float4 b, float3 c)
	{
		colorAndAlpha = a;
		psCenter = b.xy;
		splatZ = b.zw;
		psConicMul = c;
	}

	// for debugging
	// for ellipse definition a * x^2 + 2*b *x*y + c * y^2 = gaussianCutoffScale * gaussianCutoffScale
	// @return float3(a, b, c)
	float3 computeOriginalConicPs()
	{
		float3 psConicMul1 = psConicMul / log2((float)_E);
		float3 psConic = - psConicMul1 / 0.5f;

		return psConic * float3(1, 0.5f, 1);
	}

	// not optimized yet
	// @return float4(minx,miny,maxx,maxy), in pixels
	float4 computeAABB() 
	{
		float3 conic = computeOriginalConicPs();
		float a = conic.x;
		float b = conic.y;
		float c = conic.z;
		float k = GAUSSIAN_CUTOFF_SCALE;
		float2 halfSize;
		halfSize.x = k / sqrt((a - b * b / c));
		halfSize.y = k / sqrt((c - b * b / a));
		return float4(psCenter - halfSize, psCenter + halfSize);
	}
};

float3x3 matrixFromQuaternion(float4 q)
{
	float3x3 m;

	// has positive effect on some content
	q = normalize(q);

    float r = q.x;
    float x = q.y;
    float y = q.z;
    float z = q.w;

    // Compute rotation matrix from quaternion
    m = float3x3(
        1.f - 2.f * (y * y + z * z), 2.f * (x * y - r * z), 2.f * (x * z + r * y),
        2.f * (x * y + r * z), 1.f - 2.f * (x * x + z * z), 2.f * (y * z - r * x),
        2.f * (x * z - r * y), 2.f * (y * z + r * x), 1.f - 2.f * (x * x + y * y));

	return m;
}


// input content, could also lookup into ply file data
// @param SplatOffset /*$(Variable:SplatOffset)*/
// @return visible
SplatParams getSplatParams(uint splatId, float3 SplatOffset)
{
	SplatParams ret;

    ret.colorAndAlpha = float4(1.0f, 0.7f, 0.2f, 1.0f);
    ret.pos = float3(4, -1, 4) + SplatOffset;
	ret.rot = normalize(float4(1, 2, 3, 1));
	ret.linearScale = float3(1,2,3) * 0.4f;

    float angle = splatId / 6.0f * 3.14159265f * 2;
    ret.pos += float3(sin(angle), 0, cos(angle)) * 2.0f;
    ret.colorAndAlpha.rgb = float3(sin(angle), 0.5f, cos(angle)) * 0.3f + 0.3f;
    if(splatId == 0)
        ret.colorAndAlpha.rgb = 1;

	// uncomment to only see one splat
//    if(splatId != 0) { ret.linearScale = 0; ret.colorAndAlpha.a = 0; }

	return ret;
}


// assumes splatParams.rot is normalized
float4x4 computeSplatBase(SplatParams splatParams)
{
    float3 wsPos = splatParams.pos;
    float3x3 osRot = matrixFromQuaternion(splatParams.rot);
    float3 osScale = splatParams.linearScale;
    float3x3 osRotMulScale = mul(osRot, float3x3(float3(osScale.x, 0, 0), float3(0, osScale.y, 0), float3(0, 0, osScale.z)));
    float3x3 wsRotMulScale = osRotMulScale;

	return float4x4(float4(wsRotMulScale[0], wsPos.x), float4(wsRotMulScale[1], wsPos.y), float4(wsRotMulScale[2], wsPos.z), float4(0, 0, 0, 1));
}

// worldToObject
// SRT: scale rotation translate
float3x4 constructInvSRmatT(float3 s, float3x3 inR, float3 t)
{
	// reference
//	return (float3x4)inverse(constructSRmatT(s, inR, t));

	// can be optimized further but compiler seems to do a good job already

	float3 invS = 1.0f / s;

	float4x4 r = {
		float4(inR[0].x * invS.x, inR[1].x * invS.x, inR[2].x * invS.x, 0),
		float4(inR[0].y * invS.y, inR[1].y * invS.y, inR[2].y * invS.y, 0),
		float4(inR[0].z * invS.z, inR[1].z * invS.z, inR[2].z * invS.z, 0),
		float4(0, 0, 0, 1)
	};

	return (float3x4)mul(r, translate4x4(-t));
}

// assumes splatParams.rot is normalized
// input content, could also lookup into ply file data
// @return visible
bool computeSplatRasterizeParams(
	SplatParams splatParams,
	out SplatRasterizeParams params,
	float2 dimensions,
	float4x4 worldToClip,
	float4x4 viewToClip,
	float4x4 worldToView)
{
    float3 wsPos = splatParams.pos;
    float3x3 osRot = matrixFromQuaternion(splatParams.rot);
    float3 osScale = splatParams.linearScale;
    float3x3 osRotMulScale = mul(osRot, float3x3(float3(osScale.x, 0, 0), float3(0, osScale.y, 0), float3(0, 0, osScale.z)));
    float3x3 wsRotMulScale = osRotMulScale;
    float widthZ = length(osScale[0]);

    params.setup(wsRotMulScale, wsPos, widthZ, splatParams.colorAndAlpha,
        viewToClip, worldToClip, worldToView, float4(dimensions, 1.0f / dimensions));

    // if not behind camera
    bool visible = params.splatZ.x < 0.0f; 

    return visible;
}

// Inigo Quilez sphere ray intersection
// @param rayDir must be normalized
// https://iquilezles.org/articles/intersectors
float2 hit_sphere(float3 center, float radius, float3 rayStart, float3 rayDir)
{
    float3 oc = rayStart - center;
    float b = dot(oc, rayDir);
    float3 qc = oc - b * rayDir;
    float h = radius * radius - dot( qc, qc );
    if( h < 0.0f ) 
		return float2(-1, -1); // no intersection
    h = sqrt( h );
    return float2(-b -h, -b + h);
}

// Ray (infinite length) splat intersection. Also handles soft intersection with ray and ray endT
// rayPos = rayOrigin + t * rayDir, t = 0..maxT
// @param rayDir normalized
// @param inoutRndDepth input:rnd 0..1, output random t
float4 SplatRayCast(float3 rayOrigin, float3 rayDir, SplatParams splatParams, inout float inoutRndDepth, float maxT = FLT_MAX)
{
	// todo: compute
	float rayConeTan = 0.0001f;

	float3 linearScaleMul = splatParams.linearScale * GAUSSIAN_CUTOFF_SCALE;

	float3x4 worldToObject = constructInvSRmatT(linearScaleMul, matrixFromQuaternion(splatParams.rot), splatParams.pos);

	// 0..1
	float alphaAdjustmentForAA;
	{
		float distToSphere = length(splatParams.pos - rayOrigin);

		// limit size on screen for Anti-Aliasing
		float coneSizeAtSphere = distToSphere * rayConeTan;

		// todo: refine approximation
		float projectedAreaBefore = dot(linearScaleMul, linearScaleMul);

		linearScaleMul = max(linearScaleMul, coneSizeAtSphere);

		float projectedAreaAfter = dot(linearScaleMul, linearScaleMul);

		// pow is a hack, tweaked to give a similar opacity when small
		alphaAdjustmentForAA = pow(projectedAreaBefore / projectedAreaAfter, 1.5f);
	}


	float3 gsPos = mul(worldToObject, float4(rayOrigin, 1)).xyz;
	float3 gsDir = mul((float3x3)worldToObject, rayDir);

	// float2(first, second)
	float2 hit = hit_sphere(float3(0, 0, 0), 1.0f, gsPos, normalize(gsDir));
//	hit.xy /= length(gsDir);

	if (hit.y > 0) // touch sphere
	{
		// hit_sphere assumes normalized normal but we want distance in world space, not in this gaussian
		hit.xy /= length(gsDir);

		float4 finalColorWithAlpha;
		// compute Gaussian (todo: this is only approximate)
		{
			// rayDir needs to be normalized
			float3 rayDir = normalize(gsDir);
			// 0:center..1:rim
			float closest = length(gsPos + rayDir * dot(rayDir, float3(0, 0, 0) - gsPos));

			closest *= GAUSSIAN_CUTOFF_SCALE;
			float alpha = exp(-0.5f * closest * closest);

			// Looks like 3DGS is in sRGB space which seems wrong. So this is needed:
//			float3 splatColorLinear = s2h_accurateSRGBToLinear(splatParams.colorAndAlpha.rgb);
			float3 splatColorLinear = splatParams.colorAndAlpha.rgb;

			finalColorWithAlpha = float4(splatColorLinear.rgb, splatParams.colorAndAlpha.a * alpha * alphaAdjustmentForAA);
		}

		// adjust alpha if ray starts or ends inside splat
		{
			float withinStart = saturate(- hit.x / (hit.y - hit.x));
			float withinEnd = saturate((maxT - hit.x) / (hit.y - hit.x));
			float cdfStart = smoothstep(0.0f, 1.0f, withinStart);
			float cdfEnd = smoothstep(0.0f, 1.0f, withinEnd);
			float cdf = cdfEnd - cdfStart;
			finalColorWithAlpha.a *= cdf;
		}

		if(inoutRndDepth != FLT_MAX)
		{
//			inoutRndDepth = lerp(hit.x, hit.y, smoothstep(0.0f, 1.0f, inoutRndDepth));	// some artifact
			inoutRndDepth = lerp(hit.x, hit.y, inoutRndDepth);
		}


		return finalColorWithAlpha;
	}
	else
	{
		if(inoutRndDepth != FLT_MAX)
			inoutRndDepth = FLT_MAX;
	}


	return 0;
}


uint initRand(uint val0, uint val1, uint backoff = 16)
{
	uint v0 = val0, v1 = val1, s0 = 0;
	
	[unroll]
	for (uint n = 0; n < backoff; n++)
	{
		s0 += 0x9e3779b9;
		v0 += ((v1 << 4) + 0xa341316c) ^ (v1 + s0) ^ ((v1 >> 5) + 0xc8013ea4);
		v1 += ((v0 << 4) + 0xad90777d) ^ (v0 + s0) ^ ((v0 >> 5) + 0x7e95761e);
	}
	return v0;
}

// Returns a pseudorandom float in [0..1] from seed
float nextRand(inout uint rnd)
{
	rnd = (1664525u * rnd + 1013904223u);
	return float(rnd & 0x00FFFFFF) / float(0x01000000);
}