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
	// absolute time - codeTime, is changed on s2h_anim... calls, used to compute current animation state
	float momentTime;
};

void s2h_init(out s2h_AnimContext anim, float inAbsTime)
{
	anim.absTime = inAbsTime;
	anim.momentTime = anim.absTime;
}

void s2h_animPause(inout s2h_AnimContext anim, float deltaTime)
{
	if (anim.momentTime > deltaTime)
	{
		// not yet
		anim.momentTime -= deltaTime;
		return;
	}
	anim.momentTime = 0.0f;
}

void s2h_animMoveTo(inout s2h_AnimContext anim, float deltaTime, inout float2 pos, float2 destPos)
{
	if (anim.momentTime > deltaTime)
	{
		// already done
		pos = destPos;
		anim.momentTime -= deltaTime;
		return;
	}
	if (anim.momentTime <= 0.0f)
	{
		// not yet
		return;
	}
	// 0..1
	float alpha = anim.momentTime / deltaTime;
	pos = lerp(pos, destPos, alpha);
	anim.momentTime = 0.0f;
}

static const float2 g_A = float2(100.0f, 100.0f);
static const float2 g_B = float2(200.0f, 100.0f);
static const float2 g_C = float2(200.0f, 200.0f);
static const float2 g_D = float2(230.0f, 280.0f);

float2 computeCirclePos(float absTime)
{
	s2h_AnimContext anim;
	s2h_init(anim, absTime);

	// the property we want to animate
	float2 pos = g_A;

	s2h_animPause(anim, 5.0f); // pause 5 sec
	s2h_animMoveTo(anim, 10.0f, pos, g_B); // move to B over 10 sec
	s2h_animMoveTo(anim, 10.0f, pos, g_C); // move to C over 10 sec
	s2h_animPause(anim, 5.0f); // pause 5 sec 
	s2h_animMoveTo(anim, 40.0f, pos, g_D); // move to D over 40 sec (slower)
	
	return pos;
}

float s2h_floatLookupFloat(uint functionId, float x)
{
	float2 circlePos = computeCirclePos(x);

	if (functionId == 0)
		return circlePos.x;
	if (functionId == 1)
		return circlePos.y;

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

	s2h_printLF(ui);
	s2h_printLF(ui);
	s2h_setScale(ui, 1.0f);
	
	s2h_setCursor(ui, float2(10, 320));
	
	// in seconds
	const float maxTime = 100.0f;
	// to make time progress faster (>1)
	const float timeScale = 4.0f;

	// 0 .. maxTime
	float currentTime = frac(S2S_TIME() * timeScale / maxTime) * maxTime;
	
	// in characters
	const int2 functionCharSize = int2(80, 15);
	const float2 timeRange = float2(0.0f, 100.0f);
	const float2 valueRange = float2(50, 350); // the points ABCD use this x and y range plus some padding
	float scaledFontSize = s2h_fontSize() * ui.scale;
	// in pixels
	int2 functionPxSize = functionCharSize * scaledFontSize;
	
	float2 functionCursorPos = ui.pxCursor;
	
	// ###### s2h_function x red
	ui.textColor = float4(1,0,0,1);
	float2 userPos = s2h_function(ui, 0, float4(0.1f, 0.1f, 0.1f, 1), functionCharSize, timeRange, valueRange, 1);
	
	if (userPos.x != S2H_FLT_MAX)
		currentTime = userPos.x;

	// draw 2 functions on top of each other
	ui.pxCursor = functionCursorPos;
	
	// ###### s2h_function y green
	ui.textColor = float4(0, 1, 0, 1);
	s2h_function(ui, 1, 0.0f, functionCharSize, timeRange, valueRange, 1);

	float currentTimePx = ui.pxCursor.x + invLerp(timeRange.x, timeRange.y, currentTime) * functionPxSize.x;

	// white
	ui.textColor = 1.0f;

	s2h_drawLine(ui, float2(currentTimePx, ui.pxCursor.y + 10), float2(currentTimePx, ui.pxCursor.y - functionPxSize.y - 10), 1);

	s2h_setCursor(ui, float2(currentTimePx, ui.pxCursor.y + 20));
	s2h_printTxt(ui, _t, _EQUAL);
	s2h_printFloat(ui, currentTime);

	float2 circlePos = computeCirclePos(currentTime);

	s2h_drawCircle(ui, circlePos, 16.0f, 1);
	
	s2h_setScale(ui, 2u);

	ui.textColor = float4(1,0,0,1);
	s2h_setCursor(ui, float2(400, 40));
	s2h_printTxt(ui, _X, _EQUAL);
	s2h_printFloat(ui, circlePos.x);
	s2h_printLF(ui);
	ui.textColor = float4(0, 1, 0, 1);
	s2h_printTxt(ui, _Y, _EQUAL);
	s2h_printFloat(ui, circlePos.y);
	 
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

// todo:
// * better sample
// * move code out of HelloCS
// * sample for multiple independent animations
// * repeat
// * plot graph over time
