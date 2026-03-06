//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#ifdef S2H_GLSL
    // shadertoy
    #define S2S_FRAMEBUFFERSIZE() iResolution.xy
    #define S2S_TIME() iTime
    #define S2S_MOUSE() iMouse
    #define S2S_NEAR() 0.1f
    #define S2S_INV_VIEW_PROJECTION() u_worldFromClip
// todo
    #define S2S_CAMERA_POS() vec3(0,0,0)
#else
    // gigi
    #define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
    #define S2S_TIME() /*$(Variable:iTime)*/
    #define S2S_MOUSE() /*$(Variable:MouseState)*/
    #define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
    #define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
    #define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
/*$(ShaderResources)*/
#endif

// animation experiment (move into s2h library), immediate mode like ImGui/S2H

// use s2h_init() to setup
struct s2h_AnimContext
{
	// from s2h_init(), for user convenience
	float absTime;
	// from last s2h_animKey() call
	float absStartTime;
	// computed in s2h_animKey() call, 0..1
	float alpha;
};

void s2h_init(out s2h_AnimContext anim, float inAbsTime)
{
	anim.absTime = inAbsTime;
	anim.absStartTime = 0.0f;
}

void s2h_animKey(inout s2h_AnimContext anim, float endAbsTime)
{
	if (anim.absTime > endAbsTime)
	{
		// already done
		anim.alpha = 1.0f;
		anim.absStartTime = endAbsTime;
		return;
	}
	if (anim.absTime <= anim.absStartTime)
	{
		anim.alpha = 0.0f;
		return; // not yet
	}

	if (endAbsTime <= anim.absStartTime)
	{
		anim.alpha = 0.0f;
		return; // input error, avoid div by 0
	}
	
	anim.alpha = (anim.absTime - anim.absStartTime) / (endAbsTime - anim.absStartTime);
	anim.absStartTime = endAbsTime;
}

// 2D
void s2h_animLerp(inout s2h_AnimContext anim, inout float2 pos, float2 destPos)
{
	// 0..1
	pos = lerp(pos, destPos, anim.alpha);
}

// 1D
void s2h_animLerp(inout s2h_AnimContext anim, inout float _pos, float _destPos)
{
	float2 pos = _pos;
	float2 destPos = _destPos;

	s2h_animLerp(anim, pos, destPos);
	_pos = pos.x;
}

static const float2 g_A = float2(100.0f, 150.0f);
static const float2 g_B = float2(200.0f, 150.0f);
static const float2 g_C = float2(200.0f, 250.0f);
static const float2 g_D = float2(240.0f, 310.0f);

// example object to blend
struct MyAnimObject
{
	// pixel position
	float2 pos;
	// (0..1, 0..1, 0..1)
	float3 color;
	// 0:hidden .. 1:opaque
	float alpha;
};

MyAnimObject computeCircle(float absTime)
{
	MyAnimObject ret = (MyAnimObject)0;
	
	// t0
	s2h_AnimContext anim;
	s2h_init(anim, absTime);

	// start condition
	ret.pos = g_A;
	ret.color = float3(1.0f, 1.0f, 1.0f);
	ret.alpha = 1.0f;

	// control position and alpha (explicit)
	float t0 = 0.0f;
	// control color (implicit)
	ret.color = lerp(float3(1, 0, 1), float3(0, 1, 0), sin(absTime) * 0.5f + 0.5f);

	t0 += 5.0f; // pause n seconds

	s2h_animKey(anim, t0);
	s2h_animLerp(anim, ret.pos, ret.pos); // don't move

	t0 += 10.0f; // move over n seconds

	s2h_animKey(anim, t0);
	s2h_animLerp(anim, ret.alpha, 0.1f);
	s2h_animLerp(anim, ret.pos, g_B); // move to B over 10 sec

	t0 += 10.0f; // move over n seconds

	s2h_animKey(anim, t0);
	s2h_animLerp(anim, ret.alpha, 1.0f);
	s2h_animLerp(anim, ret.pos, g_C); // move to C over 10 sec

	t0 += 5.0f; // move over n seconds

	s2h_animKey(anim, t0);
	s2h_animLerp(anim, ret.pos, ret.pos); // don't move

	t0 = 30.0f + 40.0f; // move to reach at absolute time

	s2h_animKey(anim, t0);
	s2h_animLerp(anim, ret.pos, g_D); // move to D over 40 sec (slower)

	t0 += 5.0f;

	s2h_animKey(anim, t0); s2h_animKey(anim, t0);	// do not interpolate
	
	s2h_animLerp(anim, ret.alpha, 0.0f);
	
	t0 += 1.0f; // 1 sec off

	s2h_animKey(anim, t0); s2h_animKey(anim, t0); // do not interpolate
	
	s2h_animLerp(anim, ret.alpha, 1.0f);

	return ret;
}

float s2h_floatLookupFloat(uint functionId, float x)
{
	MyAnimObject obj = computeCircle(x);

	if (functionId == 0)
		return obj.pos.x;
	if (functionId == 1)
		return obj.pos.y;
	if (functionId == 2)
		return obj.alpha;

	return 0.0f;
}

float invLerp(float minX, float maxX, float x)
{
	return (x - minX) / (maxX - minX);
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
	// pixel centered (+0.5f);
    float2 pxPos = DTid + 0.5f;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
	// (0,0) .. (1, 1) 
    float2 uv = (float2)pxPos / (float2)dimensions; 

    ContextGather ui;
    s2h_init(ui, pxPos);
	ui.mouseInput = S2S_MOUSE();
    s2h_setCursor(ui, float2(10, 10));

    s2h_setScale(ui, 3.0f);
    s2h_printTxt(ui, _H, _e, _l, _l, _o);
    s2h_printTxt(ui, _A, _n, _i, _m);
	
	
	const float2 origin = float2(50, 110);
	const float gridSize = 20.0f;
	const float dotSize = 2.0f;
	float2 d = frac((ui.pxPos - origin + dotSize / 2) / gridSize) * gridSize;

	float4 gridColor = float4(0, 0, 0, 0.1f);

	if (all(d < dotSize))
		gridColor = float4(1, 1, 1, 0.5f);

	s2h_drawRectangle(ui, origin  - gridSize * 1.5f, origin + gridSize * 11.5f, gridColor);
	
	ui.lineWidth = (d.x < dotSize) ? 6.0f : 2.0f;
	s2h_drawArrow(ui, float2(10, 110), float2(300, 110), 1.0f, 16.0f, 8.0f);
	ui.lineWidth = (d.y < dotSize) ? 6.0f : 2.0f;
	s2h_drawArrow(ui, float2(50, 70), float2(50, 360), 1.0f, 16.0f, 8.0f);
	ui.lineWidth = 2.0f;
	
	
//	s2h_drawCrosshair(ui, origin, 10, float4(1, 1, 0, 1));

	s2h_setScale(ui, 1.0f);
	
	s2h_setCursor(ui, float2(10, 380));
	
	// in seconds
	const float maxTime = 100.0f;
	// to make time progress faster (>1)
	const float timeScale = 4.0f;

	// 0 .. maxTime
	float currentTime = frac(S2S_TIME() * timeScale / maxTime) * maxTime;
	
	// in characters
	const int2 functionCharSize = int2(80, 17);
	const float2 timeRange = float2(0.0f, 100.0f);
	const float2 valueRange = float2(50, 450); // the points ABCD use this x and y range plus some padding
	float scaledFontSize = s2h_fontSize() * ui.scale;
	// in pixels
	int2 functionPxSize = functionCharSize * scaledFontSize;
	
	float2 functionCursorPos = ui.pxCursor;
	
	float3 graphBackground = float3(0.1f, 0.1f, 0.1f);

	// border around s2h_function	
	s2h_printBar(ui, float4(graphBackground, 1.0f), functionCharSize, 4.0f);
	
	// ###### s2h_function x red
	ui.textColor = float4(1,0,0,1);
	float2 userPos = s2h_function(ui, 0, float4(graphBackground, 1), functionCharSize, timeRange, valueRange, 1);
	
	if (userPos.x != S2H_FLT_MAX)
		currentTime = userPos.x;

	// ###### s2h_function y green
	ui.pxCursor = functionCursorPos;
	ui.textColor = float4(0, 1, 0, 1);
	s2h_function(ui, 1, 0.0f, functionCharSize, timeRange, valueRange, 1);

	// ###### s2h_function alpah blue
	ui.pxCursor = functionCursorPos;
	ui.textColor = float4(0.1f, 0.1f, 1, 1);
	s2h_function(ui, 2, 0.0f, functionCharSize, timeRange, float2(0, 1), 1);
	
	// color bar
	{
		// todo: improve API
		float localX = (ui.pxCursor.x - ui.pxPos.x) / (functionPxSize.x);
		float localT = lerp(timeRange.x, timeRange.y, localX);
		s2h_printBar(ui, float4(computeCircle(localT).color, 1), int2(functionCharSize.x, 2), 4.0f);
	}
	
	float currentTimePx = ui.pxCursor.x + invLerp(timeRange.x, timeRange.y, currentTime) * functionPxSize.x;

	// white
	ui.textColor = 1.0f;

	s2h_drawLine(ui, float2(currentTimePx, ui.pxCursor.y + 30), float2(currentTimePx, ui.pxCursor.y - functionPxSize.y - 10), 1);

	s2h_setCursor(ui, float2(currentTimePx, ui.pxCursor.y + 40));
	s2h_printTxt(ui, _t, _EQUAL);
	s2h_printFloat(ui, currentTime);

	MyAnimObject obj = computeCircle(currentTime);

	s2h_drawCircle(ui, obj.pos, 16.0f, float4(obj.color, obj.alpha));
	
	s2h_setScale(ui, 2u);

	s2h_setCursor(ui, float2(400, 40));

	ui.textColor = float4(1, 0, 0, 1);
	s2h_printTxt(ui, _SPACE, _SPACE, _SPACE, _SPACE);
	s2h_printTxt(ui, _X, _EQUAL);
	s2h_printFloat(ui, obj.pos.x);
	s2h_printLF(ui);

	ui.textColor = float4(0, 1, 0, 1);
	s2h_printTxt(ui, _SPACE, _SPACE, _SPACE, _SPACE);
	s2h_printTxt(ui, _Y, _EQUAL);
	s2h_printFloat(ui, obj.pos.y);
	s2h_printLF(ui);

	ui.textColor = float4(0.1f, 0.1f, 1, 1);
	s2h_printTxt(ui, _a, _l, _p, _h, _a, _EQUAL);
	s2h_printFloat(ui, obj.alpha);
	 
	// grey
	ui.textColor = float4(0.5f, 0.5f, 0.5f, 1.0f);

	// ABCD lines
	s2h_drawLine(ui, g_A, g_B, 0.5f);
	s2h_drawLine(ui, g_B, g_C, 0.5f);
	s2h_drawLine(ui, g_C, g_D, 0.5f);

	// ABCD names
	s2h_setCursor(ui, g_A - 8 + 1);
	s2h_printTxt(ui, _A);
	s2h_setCursor(ui, g_B - 8 + 1);
	s2h_printTxt(ui, _B);
	s2h_setCursor(ui, g_C - 8 + 1);
	s2h_printTxt(ui, _C);
	s2h_setCursor(ui, g_D - 8 + 1);
	s2h_printTxt(ui, _D);
	
    float4 background = float4(0.1f, 0.1f, 0.3f, 1.0f);
    Output[DTid] = lerp(background, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
}

// this sample demonstrates:
// * 2D linear movement
// * 2D pause movement
// * 1D fade in/out (to 0.1)
// * 1D hide / unhide (same method can be used to teleport too)


// todo:
// * rename s2h_function to printFunction?
// * s2h_drawRectangleAA should use lineWidth and outer border
// * better function box rendering (rounded corners)
// * cubic spline animation
// * render axis with steps, move to s2h.hlsl
// * orientation
// * lerp 3D, 4D, struct
// * move code out of HelloCS
// * sample for multiple independent animations
// * repeat
