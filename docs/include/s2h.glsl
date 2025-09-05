

































/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

// Any potentially API breaking update we should increase the version by 1 allowing other code to adapt to S2H.


// pixel shader or compute shader looping through all pixels

// Example:
// #include "s2h.h"
// {
//   ContextGather ui;
//   // pxPos is the integer pixel position + 0.5f (pixel centered)
//   s2h_init(ui, pxPos + 0.5f);
//   // print AB 
//   s2h_printTxt(ui, _A, _B);
//   // Note: ui.dstColor is premultiplied
//   linearColor = linearBackground * (1.0f - ui.dstColor.a) + ui.dstColor;
//   // for correct AntiAliasing 
//   srgbColor = float4(s2h_accurateLinearToSRGB(linearColor.rgb), 1);
// }

// documentation:
struct ContextGather
{
	// in pixels, no fractional part (half pixel offset)
	vec2 pxCursor;
	// 1/2/3/4
	float scale;
	// .xy:-100,-100 if not yet set, .xy:absolutePos, z:leftMouse 0/1, w:rightMouse 0/1, no fractional part (half pixel offset)
	vec4 mouseInput;

	// window left top, no fractional part (half pixel offset), set by s2h_setPos(), used by s2h_printLF()
	float pxLeftX;
	// in pixels, no fractional part (half pixel offset), set by s2h_init()
	vec2 pxPos;
	// premultiplied RGBA, alpha 1 is assumed to be opaque, don't init with a color or s2h_button() will not work
	vec4 dstColor;

	//

	// RGBA, alpha 1 is assumed to be opaque, s2h_progress()
	vec4 textColor;
	// for s2h_frame()
	vec4 frameFillColor;
	// for s2h_frame()
	vec4 frameBorderColor;
	// for s2h_button(), s2h_checkbox(), s2h_radiobutton, s2h_progress(), s2h_sliderFloat()
	vec4 buttonColor;
	//
	float lineWidth;

	// private ----------------------

	// for interactive UI, read int4 state from former frame
	ivec4 s2h_State;
};

struct s2h_Triangle
{
    vec2 A;
    vec2 B;
    vec2 C;
};

// first call this
void s2h_init(out ContextGather ui);
// set text cursor position, next printLF() will reset to this x position
void s2h_setCursor(inout ContextGather ui, vec2 inpxLeftTop);
// @param s2h_State write int4 state for next frame, don't call if you don't want UI State
void s2h_deinit(inout ContextGather ui, out ivec4 s2h_State);
// @param scale 1:pixel perfect, 2:2x, 3:3x, ..
void s2h_setScale(inout ContextGather ui, float scale);
// e.g. ui.s2h_printTxt('I', ' ', 'a', 'm');
// @param a ascii character or 0
void s2h_printTxt(inout ContextGather ui, uint a, uint b, uint c, uint d, uint e, uint f);
// useful for table headers and to center text
void s2h_printSpace(inout ContextGather ui, float numberOfChars);
// jump to next line (line feed)
void s2h_printLF(inout ContextGather ui);
// @param value e.g. 123, 0
void s2h_printInt(inout ContextGather ui, int value);
// print hexadecimal e.g. "0000aa34"
// @param value 32bit e.g. 0x123, 0xff00
void s2h_printHex(inout ContextGather ui, uint value);
// @param output e.g. g_output from RWTexture2D<float3> g_output : register(u0, space0);
// @param pos in pixels from left top, left top of the printout
// @param value
void s2h_printFloat(inout ContextGather ui, float value);
// don't use directly
void s2h_printCharacter(inout ContextGather ui, uint ascii);
// circle in a s2h_fontSize() x s2h_fontSize() character
void s2h_printDisc(inout ContextGather ui, vec4 color);
// block in a s2h_fontSize() x s2h_fontSize() character
void s2h_printBox(inout ContextGather ui, vec4 color);
// useful for table headers
// similar to s2h_button but not interactive, call after using s2h_printTxt()
void s2h_frame(inout ContextGather ui, uint widthInCharacters);

// draw anti aliased filled disc 
void s2h_drawDisc(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color);
// draw anti aliased circle
void s2h_drawCircle(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color, float pxThickness);
// draw anti aliased circle
void s2h_drawHalfSpace(inout ContextGather ui, vec3 halfSpace, vec2 visualizePoint, vec4 color, float pxCircleRadius, float pxLineRadius);
// draw not anti aliased rectangle (fast and simple), 
// @param pxLeftTop included
// @param pxBottomRight excluded
void s2h_drawRectangle(inout ContextGather ui, vec2 pxLeftTop, vec2 pxBottomRight, vec4 color);
// border half inwards and half outwards, pxThickness >0 results in rounded corners
void s2h_drawRectangleAA(inout ContextGather ui, vec2 pxA, vec2 pxB, vec4 borderColor, vec4 innerColor, float pxThickness);
// anti aliased, px position should be pixel centered (+0.5)
void s2h_drawCrosshair(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color, float pxThickness);
// hard edges, anti aliased, px position should be pixel centered (+0.5)
void s2h_drawLine(inout ContextGather ui, vec2 pxBegin, vec2 pxEnd, vec4 color, float pxThickness);
// anti aliased px position should be pixel centered (+0.5)
void s2h_drawArrow(inout ContextGather ui, vec2 pxStart, vec2 pxEnd, vec4 color, float arrowHeadLength, float arrowHeadWidth);
// anti aliased px position should be pixel centered (+0.5)
void s2h_drawTriangle(inout ContextGather ui, s2h_Triangle tri, vec4 color);
// 256x32 horizontal color ramp in sRGB space, 128 should be in the middle, RGB color gradient on outside
void s2h_drawSRGBRamp(inout ContextGather ui, vec2 pxPos);


// ------------------------------------------

// for state-full UI:

// call after using s2h_printTxt()
// e.g. if(s2h_button(ui, 5, float4(1,0,1,1))) do();
bool s2h_button(inout ContextGather ui, uint widthInCharacters);
// circle in a s2h_fontSize() x s2h_fontSize() character with mouse over
// e.g. if(s2h_radioButton(ui, float4(1,0,0,1), UIState[0].SplatMode == 0) && leftMouse) UIState[0].SplatMode = 0;
// @param checked fill inside using textColor
// @return mouseOver (can be used as button or radio button)
bool s2h_radioButton(inout ContextGather ui, bool checked);
// e.g. if(s2h_checkBox(ui, UIState[0].UICheckboxState == 0) && leftMouseClicked) UIState[0].UICheckboxState = !UIState[0].UICheckboxState;
// @param checked fill inside using textColor
bool s2h_checkBox(inout ContextGather ui, bool checked);
// @param fraction 0..1
void s2h_progress(inout ContextGather ui, uint widthInCharacters, float fraction);
//
void s2h_sliderFloat(inout ContextGather ui, uint widthInCharacters, inout float value, float minValue, float maxValue);
// LDR color (0..1 range)
void s2h_sliderRGB(inout ContextGather ui, uint widthInCharacters, inout vec3 value);
// LDR color (0..1 range) with alpha
void s2h_sliderRGBA(inout ContextGather ui, uint widthInCharacters, inout vec4 value);

// not yet for GLSL 

















// helper functions ----------------------------------------------------------------------

// slow but accurate
vec3 s2h_accurateLinearToSRGB(vec3 linearCol);
// slow but accurate
vec3 s2h_accurateSRGBToLinear(vec3 sRGBCol);
// extremely different colors, 0 is black
// intentionally not randomized so small indices result in human recognizable colors
// repeats every 512 elements
vec3 s2h_indexToColor(uint index);
// @param 0..1
// @return 0:red, 0.5:green, 1:blue, outside is clamped
vec3 s2h_colorRampRGB(float value);


// implementation ----------------------------------------------------------------------



     const float S2H_FLT_MAX = intBitsToFloat(2139095039);





// You can define this to provide your own font (different size, visual or better lookup performance by using a texture)




	const uint g_miniFont[] = uint[](



    0x00306c6cu, 0x30003860u, 0x18600000u, 0x00000006u, 
    0x00786c6cu, 0x7cc66c60u, 0x30306630u, 0x0000000cu, 
    0x00786cfeu, 0xc0cc38c0u, 0x60183c30u, 0x00000018u, 
    0x0030006cu, 0x78187600u, 0x6018fffcu, 0x00fc0030u, 
    0x003000feu, 0x0c30dc00u, 0x60183c30u, 0x00000060u, 
    0x0000006cu, 0xf866cc00u, 0x30306630u, 0x300030c0u, 
    0x0030006cu, 0x30c67600u, 0x18600000u, 0x30003080u, 
    0x00000000u, 0x00000000u, 0x00000000u, 0x60000000u, 
    0x7c307878u, 0x1cfc38fcu, 0x78780000u, 0x18006078u, 
    0xc670ccccu, 0x3cc060ccu, 0xcccc3030u, 0x300030ccu, 
    0xce300c0cu, 0x6cf8c00cu, 0xcccc3030u, 0x60fc180cu, 
    0xde303838u, 0xcc0cf818u, 0x787c0000u, 0xc0000c18u, 
    0xf630600cu, 0xfe0ccc30u, 0xcc0c0000u, 0x60001830u, 
    0xe630ccccu, 0x0ccccc30u, 0xcc183030u, 0x30fc3000u, 
    0x7cfcfc78u, 0x1e787830u, 0x78703030u, 0x18006030u, 
    0x00000000u, 0x00000000u, 0x00000060u, 0x00000000u, 
    0x7c30fc3cu, 0xf8fefe3cu, 0xcc781ee6u, 0xf0c6c638u, 
    0xc6786666u, 0x6c626266u, 0xcc300c66u, 0x60eee66cu, 
    0xdecc66c0u, 0x666868c0u, 0xcc300c6cu, 0x60fef6c6u, 
    0xdecc7cc0u, 0x667878c0u, 0xfc300c78u, 0x60fedec6u,
    0xdefc66c0u, 0x666868ceu, 0xcc30cc6cu, 0x62d6cec6u,
    0xc0cc6666u, 0x6c626066u, 0xcc30cc66u, 0x66c6c66cu,
    0x78ccfc3cu, 0xf8fef03eu, 0xcc7878e6u, 0xfec6c638u,
    0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
    0xfc78fc78u, 0xfcccccc6u, 0xc6ccfe78u, 0xc0781000u,
    0x66cc66ccu, 0xb4ccccc6u, 0xc6ccc660u, 0x60183800u,
    0x66cc66e0u, 0x30ccccc6u, 0x6ccc8c60u, 0x30186c00u,
    0x7ccc7c70u, 0x30ccccd6u, 0x38781860u, 0x1818c600u,
    0x60dc6c1cu, 0x30ccccfeu, 0x38303260u, 0x0c180000u,
    0x607866ccu, 0x30cc78eeu, 0x6c306660u, 0x06180000u,
    0xf01ce678u, 0x78fc30c6u, 0xc678fe78u, 0x02780000u,
    0x00000000u, 0x00000000u, 0x00000000u, 0x000000ffu,
    0x3000e000u, 0x1c003800u, 0xe0300ce0u, 0x70000000u, 
    0x30006000u, 0x0c006c00u, 0x60000060u, 0x30000000u, 
    0x18786078u, 0x0c786076u, 0x6c700c66u, 0x30ccf878u, 
    0x000c7cccu, 0x7cccf0ccu, 0x76300c6cu, 0x30feccccu, 
    0x007c66c0u, 0xccfc60ccu, 0x66300c78u, 0x30feccccu, 
    0x00cc66ccu, 0xccc0607cu, 0x6630cc6cu, 0x30d6ccccu, 
    0x0076dc78u, 0x7678f00cu, 0xe678cce6u, 0x78c6cc78u, 
    0x00000000u, 0x000000f8u, 0x00007800u, 0x00000000u, 
    0x00000000u, 0x10000000u, 0x0000001cu, 0x18e076ffu, 
    0x00000000u, 0x30000000u, 0x00000030u, 0x1830dcffu, 
    0xdc76dc7cu, 0x7cccccc6u, 0xc6ccfc30u, 0x183000ffu,
    0x66cc76c0u, 0x30ccccd6u, 0x6ccc98e0u, 0x001c00ffu, 
    0x66cc6678u, 0x30ccccfeu, 0x38cc3030u, 0x183000ffu, 
    0x7c7c600cu, 0x34cc78feu, 0x6c7c6430u, 0x183000ffu, 
    0x600cf0f8u, 0x1876306cu, 0xc60cfc1cu, 0x18e000ffu, 
    0xf01e0000u, 0x00000000u, 0x00f80000u, 0x000000ffu

	);




// todo: consider define or static cost int or float
// 8x8 font 
float s2h_fontSize() { return 8.0f; }

// don't use directly
// can be used for scatter and gather
// @param ascii 32..127 are valid characters
// @param pxPos int2(0..s2h_fontSize()-1, 0..s2h_fontSize-1)
// @return true if there should be a pixel, false if not or outside the valid range
bool s2h_fontLookup(uint ascii, ivec2 pxPos)
{
	if(uint(pxPos.x) >= 8u || uint(pxPos.y) >= 8u)
        return false;

    if (ascii <= 32u || ascii > 127u)
        return false;

    // 0..16*6-1
    uint chr = ascii - 32u;
    // uint2(0..127, 0..47) 
    uvec2 chrPos = uvec2(chr % 16u, chr / 16u);
    uvec2 pixel = uvec2(chrPos.x * 8u + uint(pxPos.x), chrPos.y * 8u + uint(pxPos.y));
    uint dwordId = pixel.x / 32u + (pixel.y * 4u);
    // 0..31
    uint bitId	= uint(pixel.x) & 0x1fu;

    // 0..ff
    uint dwordValue = g_miniFont[dwordId];

    return ((dwordValue >> (31u - bitId)) & 1u) != 0u;
}

void s2h_printCharacter(inout ContextGather ui, uint ascii)
{
	ivec2 pxLocal = ivec2(floor((ui.pxPos - ui.pxCursor) / ui.scale));

	if(s2h_fontLookup(ascii, pxLocal))
		ui.dstColor = mix(ui.dstColor, vec4(ui.textColor.rgb, 1), ui.textColor.a);

	ui.pxCursor.x += s2h_fontSize() * ui.scale;
}



 const uint _A = 65u;
 const uint _B = 66u;
 const uint _C = 67u;
 const uint _D = 68u;
 const uint _E = 69u;
 const uint _F = 70u;
 const uint _G = 71u;
 const uint _H = 72u;
 const uint _I = 73u;
 const uint _J = 74u;
 const uint _K = 75u;
 const uint _L = 76u;
 const uint _M = 77u;
 const uint _N = 78u;
 const uint _O = 79u;
 const uint _P = 80u;
 const uint _Q = 81u;
 const uint _R = 82u;
 const uint _S = 83u;
 const uint _T = 84u;
 const uint _U = 85u;
 const uint _V = 86u;
 const uint _W = 87u;
 const uint _X = 88u;
 const uint _Y = 89u;
 const uint _Z = 90u;

 const uint _a = (_A + 32u);
 const uint _b = (_B + 32u);
 const uint _c = (_C + 32u);
 const uint _d = (_D + 32u);
 const uint _e = (_E + 32u);
 const uint _f = (_F + 32u);
 const uint _g = (_G + 32u);
 const uint _h = (_H + 32u);
 const uint _i = (_I + 32u);
 const uint _j = (_J + 32u);
 const uint _k = (_K + 32u);
 const uint _l = (_L + 32u);
 const uint _m = (_M + 32u);
 const uint _n = (_N + 32u);
 const uint _o = (_O + 32u);
 const uint _p = (_P + 32u);
 const uint _q = (_Q + 32u);
 const uint _r = (_R + 32u);
 const uint _s = (_S + 32u);
 const uint _t = (_T + 32u);
 const uint _u = (_U + 32u);
 const uint _v = (_V + 32u);
 const uint _w = (_W + 32u);
 const uint _x = (_X + 32u);
 const uint _y = (_Y + 32u);
 const uint _z = (_Z + 32u);

 const uint _SINGLEQUOTE = 39u;   // '
 const uint _UNDERSCORE = 95u;    // _
 const uint _MINUS = 45u;         // -
 const uint _PLUS = 43u;          // +
 const uint _ASTERISK = 42u;      // *
 const uint _PERIOD = 46u;        // .
 const uint _COLON = 58u;         // :
 const uint _COMMA = 44u;         // ,
 const uint _SPACE = 32u;         //  
 const uint _LESS = 60u;          // <
 const uint _EQUAL = 61u;         // =
 const uint _GREATER = 62u;       // >
 const uint _SLASH = 47u;         // /
 const uint _BACKSLASH = 92u;     //
 const uint _0 = 48u;
 const uint _1 = 49u;
 const uint _2 = 50u;
 const uint _3 = 51u;
 const uint _4 = 52u;
 const uint _5 = 53u;
 const uint _6 = 54u;
 const uint _7 = 55u;
 const uint _8 = 56u;
 const uint _9 = 57u;

void s2h_init(out ContextGather ui, vec2 inPxPos)
{
	// white, opaque 
	ui.textColor = vec4(1, 1, 1, 1); 
	ui.pxLeftX = 0.0f; 
	ui.pxCursor = vec2(0, 0); 
	ui.scale = 1.0f;
	ui.mouseInput = vec4(-100, -100, 0, 0); 

	ui.pxPos = inPxPos;
	// see through
	ui.dstColor = vec4(0, 0, 0, 0);
	ui.s2h_State = ivec4(0, 0, 0, 0);

	ui.frameFillColor = vec4(0.9f, 0.9f, 0.9f, 1);
	ui.frameBorderColor = vec4(0.7f, 0.7f, 0.7f, 1);
	ui.buttonColor = vec4(0.5f, 0.5f, 0.5f, 1);
	ui.lineWidth = 2.0f;
}

void s2h_setCursor(inout ContextGather ui, vec2 inpxLeftTop)
{
	ui.pxCursor = inpxLeftTop; 
	ui.pxLeftX = inpxLeftTop.x;
}

void s2h_deinit(inout ContextGather ui, out ivec4 s2h_State)
{
	// if mouse input was set and mouse is released, we forget which button was active
	if(ui.mouseInput.x != -100.0f && ui.mouseInput.z == 0.0f)
		ui.s2h_State = ivec4(0,0,0,0);

	s2h_State = ui.s2h_State;
}

void s2h_setScale(inout ContextGather ui, float scale)
{
	ui.scale = scale;
}

void s2h_printTxt(inout ContextGather ui, uint a)
{
	s2h_printCharacter(ui, a);
}
// glsl has no default arguments to we implement multiple functions instead making porting easier
void s2h_printTxt(inout ContextGather ui, uint a, uint b)
{ s2h_printTxt(ui, a); s2h_printCharacter(ui, b); }
void s2h_printTxt(inout ContextGather ui, uint a, uint b, uint c)
{ s2h_printTxt(ui, a, b); s2h_printCharacter(ui, c); }
void s2h_printTxt(inout ContextGather ui, uint a, uint b, uint c, uint d)
{ s2h_printTxt(ui, a, b, c); s2h_printCharacter(ui, d); }
void s2h_printTxt(inout ContextGather ui, uint a, uint b, uint c, uint d, uint e)
{ s2h_printTxt(ui, a, b, c, d); s2h_printCharacter(ui, e); }
void s2h_printTxt(inout ContextGather ui, uint a, uint b, uint c, uint d, uint e, uint f)
{ s2h_printTxt(ui, a, b, c, d, e); s2h_printCharacter(ui, f); }

void s2h_printSpace(inout ContextGather ui, float numberOfChars)
{
	ui.pxCursor.x += s2h_fontSize() * numberOfChars * ui.scale;
}

void s2h_printLF(inout ContextGather ui)
{
	ui.pxCursor.x = ui.pxLeftX;
	ui.pxCursor.y += s2h_fontSize() * ui.scale;
}

void s2h_printInt(inout ContextGather ui, int value)
{
	// leading '-'
	if (value < 0)
	{
		s2h_printCharacter(ui, _MINUS);
		value = -value;
	}
	if (value == 0)
	{
		s2h_printCharacter(ui, _0);
		return;
	}
	// move to right depending on number length
	{
		uint tmp = uint(value);
		while (tmp != 0u)
		{
			ui.pxCursor.x += s2h_fontSize() * ui.scale;
			tmp /= 10u;
		}
	}
	// digits
	{
		float backup = ui.pxCursor.x;
		uint tmp = uint(value);
		while (tmp != 0u)
		{
			// 0..9
			uint digit = tmp % 10u;
			tmp /= 10u;
			// go backwards
			ui.pxCursor.x -= s2h_fontSize() * ui.scale;
			s2h_printCharacter(ui, _0 + digit);
			// counter +=s2h_fontSize() from printCharacter ()
			ui.pxCursor.x -= s2h_fontSize() * ui.scale;
		}
		ui.pxCursor.x = backup;
	}
}

void s2h_printHex(inout ContextGather ui, uint value)
{
	// 8 nibbles
	for(int i = 7; i >= 0; --i)
	{
		// 0..15
		uint nibble = (value >> (uint(i) * 4u)) & 0xfu;
		uint start = (nibble < 10u) ? _0 : (_A - 10u);
		s2h_printCharacter(ui, start + nibble);
	}
}

void s2h_printFloat(inout ContextGather ui, float value)
{
	s2h_printInt(ui, int(value));
	float fractional = fract(abs(value));

	s2h_printCharacter(ui, _PERIOD);

	uint digitCount = 3u;

	// todo: unit tests, this is likely wrong at lower precision

	// fractional digits
	for(uint i = 0u; i < digitCount; ++i)
	{
		fractional *= 10.0f;
		// 0..9
		uint digit = uint(fractional);
		fractional = fract(fractional);
		s2h_printCharacter(ui, _0 + digit);
	}
}

void s2h_printBox(inout ContextGather ui, vec4 color)
{
	vec2 pxLocal = vec2(ui.pxPos - ui.pxCursor) / float(ui.scale) - vec2(4, 4);

	float mask = clamp(4.0f - max(abs(pxLocal.x), abs(pxLocal.y)),0.0f,1.0f);

//	dstColor = lerp(dstColor, float4(color.rgb, 1), color.a * mask);
	if(mask > 0.0f)
		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a);

	ui.pxCursor.x += s2h_fontSize() * ui.scale;
}

void s2h_drawDisc(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color)
{
	vec2 pxLocal = ui.pxPos - pxCenter;

	float len = length(pxLocal);
	float mask = clamp(pxRadius - len,0.0f,1.0f);

	ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * mask);
}

void s2h_drawCircle(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color, float pxThickness)
{
	float r = pxThickness * 0.5f;
	vec2 pxLocal = ui.pxPos - pxCenter;

	float len = length(pxLocal);
	float mask = clamp(pxRadius - len + r,0.0f,1.0f) * (1.0f - clamp(pxRadius - len - r,0.0f,1.0f));

	ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * mask);
}

void s2h_drawHalfSpace(inout ContextGather ui, vec3 halfSpace, vec2 visualizePoint, vec4 color, float pxCircleRadius, float lineRadius)
{
    // normalize
    halfSpace /= length(halfSpace.xy);

    //
    vec2 onPoint = visualizePoint - halfSpace.xy * dot(halfSpace, vec3(visualizePoint, 1));

    float planeDist = dot(halfSpace, vec3(ui.pxPos, 1));
    float diskDist = length(onPoint - ui.pxPos);

	// 0..1
    float sideMask = clamp(planeDist,0.0f,1.0f);
	// 0..1
    float lineMask = clamp(ui.lineWidth - abs(planeDist - ui.lineWidth),0.0f,1.0f) * clamp(lineRadius - diskDist,0.0f,1.0f);
	// 0..1
    float semiDiskMask = clamp(pxCircleRadius - diskDist,0.0f,1.0f) * sideMask;
    float mask = max(semiDiskMask, lineMask);

	ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * mask);
}

void s2h_drawRectangle(inout ContextGather ui, vec2 pxLeftTop, vec2 pxBottomRight, vec4 color)
{
	if(ui.pxPos.x >= pxLeftTop.x && ui.pxPos.y >= pxLeftTop.y && ui.pxPos.x < pxBottomRight.x && ui.pxPos.y < pxBottomRight.y)
		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a);
}

void s2h_drawRectangleAA(inout ContextGather ui, vec2 pxA, vec2 pxB, vec4 borderColor, vec4 innerColor, float pxThickness)
{
	float r = pxThickness * 0.5f;

	vec2 pxCenter = (pxA + pxB) * 0.5f;
	vec2 pxHalfSize = abs(pxB - pxA) * 0.5f;
	
	vec2 pxLocalOuter = max(abs(ui.pxPos - pxCenter) - pxHalfSize, vec2(0, 0));
	vec2 pxLocalInner = max(abs(ui.pxPos - pxCenter) - pxHalfSize + r, vec2(0, 0));

	float maskOuter = clamp(1.0f + r - length(pxLocalOuter),0.0f,1.0f);
	float maskInner = clamp(length(pxLocalInner) - 0.5f,0.0f,1.0f);

	vec4 color = mix(innerColor, vec4(borderColor.rgb, 1), borderColor.a * maskInner);

	ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * maskOuter);
}

void s2h_drawCrosshair(inout ContextGather ui, vec2 pxCenter, float pxRadius, vec4 color, float pxThickness)
{
	vec2 h = vec2(pxRadius, 0);
	vec2 v = vec2(0, pxRadius);

	s2h_drawLine(ui, pxCenter - h , pxCenter + h, color, pxThickness);
	s2h_drawLine(ui, pxCenter - v, pxCenter + v, color, pxThickness);
}

void s2h_drawLine(inout ContextGather ui, vec2 pxBegin, vec2 pxEnd, vec4 color, float pxThickness)
{
	pxThickness++;
	float r = pxThickness * 0.5f;
	vec2 delta = pxEnd - pxBegin;
	float len = length(delta);
	if(len > 0.01f)
	{
		vec2 tangent = delta / len;
		vec2 normal = vec2(tangent.y, -tangent.x);
		vec2 local = vec2(ui.pxPos) - pxBegin;
		vec2 uv = vec2(dot(local, tangent), dot(local, normal));
		// 0...1
		float mask = clamp(r - abs(uv.y),0.0f,1.0f) * clamp(r - uv.x + len,0.0f,1.0f) * clamp(r + uv.x,0.0f,1.0f);

		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * mask);
	}
}

vec3 s2h_getHalfSpacePlane(vec2 pointA, vec2 pointB)
{
    vec2 ab = normalize(pointA - pointB);
    vec3 abPlane = vec3(-ab.y, ab.x, 0);
    abPlane.z = dot(abPlane.xy, -pointA);

    return abPlane;
}

void s2h_drawTriangle(inout ContextGather ui, s2h_Triangle tri, vec4 color)
{
    vec3 abPlane = s2h_getHalfSpacePlane(tri.A, tri.B);
    float abMask = clamp(dot(abPlane, vec3(ui.pxPos, 1)) - 0.5f,0.0f,1.0f);

    vec3 bcPlane = s2h_getHalfSpacePlane(tri.B, tri.C);
    float bcMask = clamp(dot(bcPlane, vec3(ui.pxPos, 1))- 0.5f,0.0f,1.0f);

    vec3 caPlane = s2h_getHalfSpacePlane(tri.C, tri.A);
    float caMask = clamp(dot(caPlane, vec3(ui.pxPos, 1)) - 0.5f,0.0f,1.0f);
    
    float mask = abMask * bcMask * caMask;
    ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a * mask);
}

void s2h_drawArrow(inout ContextGather ui, vec2 pxStart, vec2 pxEnd, vec4 color,  float arrowHeadLength, float arrowHeadWidth)
{
    vec2 direction = vec2(0,1);
    direction = normalize(pxEnd - pxStart);

    ui.scale = 2.0f;
    s2h_printFloat(ui, 1234.0f);
    const float Thickness = 10.0f;

    vec2 lineStart = pxStart;
    // Subtract the arrow length from lineEnd - arrow fits in pxStart...pxEnd
    vec2 lineEnd = pxEnd - direction * arrowHeadLength;

    vec2 perpendicularDir = normalize(vec2(direction.y, -direction.x)); 

    s2h_drawLine(ui, lineStart, lineEnd, color, Thickness);

    s2h_Triangle triA;
    triA.A = lineEnd - perpendicularDir * arrowHeadWidth;
    triA.B = lineEnd + direction * arrowHeadLength;
    triA.C = lineEnd + perpendicularDir * arrowHeadWidth;
    s2h_drawTriangle(ui, triA, color);
}

void s2h_drawSRGBRamp(inout ContextGather ui, vec2 pxPos)
{
	// snap to pixel center
	pxPos = floor(pxPos) + 0.5f;

	vec2 local = ui.pxPos - pxPos;

	float u = local.x / 256.0f;

	if(local.y > 16.0f)
		u = floor(u * 16.0f) / 16.0f;

	vec3 col = s2h_accurateSRGBToLinear(vec3(u, u, u));

	s2h_drawRectangle(ui, pxPos - 2.0f, pxPos + vec2(256, 32) + 2.0f, vec4(s2h_colorRampRGB(u), 1));
	s2h_drawRectangle(ui, pxPos, pxPos + vec2(256, 32), vec4(col, 1));

	ContextGather backup = ui;
	s2h_setScale(ui, 1.0f);
	ui.textColor = vec4(1, 1, 1, 1);
	s2h_setCursor(ui, pxPos + vec2(2.0f, 22));
	s2h_printTxt(ui, _0);
	s2h_setCursor(ui, pxPos + vec2(128.0f - 1.5f * 8.0f, 22));
	s2h_printTxt(ui, _1, _2, _7);
	ui.textColor = vec4(0, 0, 0, 1);
	s2h_setCursor(ui, pxPos + vec2(256.0f - 3.2f * 8.0f, 22));
	s2h_printTxt(ui, _2, _5, _5);

	ui.pxCursor = backup.pxCursor;
	ui.scale = backup.scale;
	ui.textColor = backup.textColor;
}

void s2h_printDisc(inout ContextGather ui, vec4 color) 
{ 
	vec2 pxLocal = vec2(ui.pxPos - ui.pxCursor) / float(ui.scale) - vec2(4, 4); 
 
	float mask = clamp(4.0f - length(pxLocal),0.0f,1.0f); 
 
//	dstColor = lerp(stColor, float4(color.rgb, 1), color.a * mask); 
	// no AA for now
	if(mask > 0.0f) 
		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a);
 
	ui.pxCursor.x += s2h_fontSize() * ui.scale; 
}

float s2h_computeDistToBox(inout ContextGather ui, vec2 p, vec2 center, vec2 halfSize)
{
	vec2 pxLocal = vec2(p - center);// - float2(3.5f, 3.5f) * ui.scale;
	vec2 dist2 = max(vec2(0, 0), abs(pxLocal) - halfSize);
	return max(dist2.x, dist2.y);
}

// @param aabb .x:minx, .y:miny, z:maxx, w:maxy
float s2h_computeDistToBox(inout ContextGather ui, vec2 p, vec4 aabb)
{
	vec2 center = (aabb.xy + aabb.zw) * 0.5f; 
	vec2 halfSize = (aabb.zw - aabb.xy) * 0.5f;
	vec2 pxLocal = vec2(p - center);// - float2(3.5f, 3.5f) / ui.scale;
	vec2 dist2 = max(vec2(0, 0), abs(pxLocal) - halfSize);
	return max(dist2.x, dist2.y);
}

void s2h_frame(inout ContextGather ui, uint widthInCharacters)
{
	vec4 aabb = vec4(ui.pxCursor - vec2(widthInCharacters, 0) * s2h_fontSize() * ui.scale, ui.pxCursor);

	// shrink
	aabb += vec4(4, 4, -4, 4) * ui.scale;

	float dist = s2h_computeDistToBox(ui, ui.pxPos, aabb) / ui.scale;

	float rimMask = clamp(3.0f - dist,0.0f,1.0f);
	float outerMask = clamp(4.0f - dist,0.0f,1.0f);

	vec4 localColor = vec4(0,0,0,0);

	// no AA for now
	if(outerMask > 0.0f)
		localColor = ui.frameBorderColor;

	if(rimMask > 0.0f)
		localColor = ui.frameFillColor;

	ui.dstColor = mix(ui.dstColor, vec4(localColor.rgb, 1), localColor.a * (1.0f - ui.dstColor.a));
}

bool s2h_button(inout ContextGather ui, uint widthInCharacters)
{
	vec4 color = ui.buttonColor;
	const float border = 0.0f;

	vec4 aabb = vec4(ui.pxCursor - vec2(widthInCharacters, 0) * s2h_fontSize() * ui.scale, ui.pxCursor);

	// shrink
	aabb += vec4(4, 4, -4, 4) * ui.scale;

	float dist = s2h_computeDistToBox(ui, ui.pxPos, aabb) / ui.scale;
	bool mouseOver = s2h_computeDistToBox(ui, ui.mouseInput.xy, aabb) / ui.scale < 5.0f + border;

	float rimMask = clamp(5.0f - dist + border,0.0f,1.0f);
	float outerMask = clamp(4.0f - dist + border,0.0f,1.0f);

	vec4 localColor = vec4(0,0,0,0);

	if(mouseOver && rimMask > 0.0f)
		localColor = vec4(1, 1, 1, 1);

	// no AA for now
	if(outerMask > 0.0f)
		localColor = color;

	ui.dstColor = mix(ui.dstColor, vec4(localColor.rgb, 1), localColor.a * (1.0f - ui.dstColor.a));

	vec2 delta = round(ui.mouseInput.xy + 0.5f - ui.pxPos);

	return mouseOver && delta.x == 0.0f && delta.y == 0.0f;
}

bool s2h_radioButton(inout ContextGather ui, bool checked)
{
	vec4 color = ui.buttonColor;

	vec2 pxLocal = vec2(ui.pxPos - ui.pxCursor - 0.5f) / float(ui.scale) - vec2(3.5f, 3.5f);
	float dist = length(pxLocal);

	float rimMask = clamp(5.0f - dist,0.0f,1.0f);
	float outerMask = clamp(4.0f - dist,0.0f,1.0f);
	float innerMask = clamp(2.5f - dist,0.0f,1.0f);

	bool mouseOver = length(vec2(ui.mouseInput.xy - ui.pxCursor) / float(ui.scale) - vec2(3.5f, 3.5f)) < 4.0f;

	if(mouseOver && rimMask > 0.0f)
		ui.dstColor = vec4(1, 1, 1 ,1);

	// no AA for now
	if(outerMask > 0.0f)
		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a);
	if(checked && innerMask > 0.0f)
		ui.dstColor = mix(ui.dstColor, vec4(ui.textColor.rgb, 1), ui.textColor.a);

	ui.pxCursor.x += s2h_fontSize() * ui.scale;

	vec2 delta = round(ui.mouseInput.xy + 0.5f - ui.pxPos);

	return mouseOver && delta.x == 0.0f && delta.y == 0.0f;
}

bool s2h_checkBox(inout ContextGather ui, bool checked)
{
	vec4 color = ui.buttonColor;

	vec2 pxLocal = vec2(ui.pxPos - ui.pxCursor - 0.5f) / float(ui.scale) - vec2(3.5f, 3.5f);
	float dist = max(abs(pxLocal.x), abs(pxLocal.y));

	float rimMask = clamp(5.0f - dist,0.0f,1.0f);
	float outerMask = clamp(4.0f - dist,0.0f,1.0f);
	float innerMask = clamp(2.5f - dist,0.0f,1.0f);

	bool mouseOver = length(vec2(ui.mouseInput.xy - ui.pxCursor) / float(ui.scale) - vec2(3.5f, 3.5f)) < 4.0f;

	if(mouseOver && rimMask > 0.0f)
		ui.dstColor = vec4(1, 1, 1 ,1);

	// no AA for now
	if(outerMask > 0.0f)
		ui.dstColor = mix(ui.dstColor, vec4(color.rgb, 1), color.a);
	if(checked && innerMask > 0.0f)
		ui.dstColor = mix(ui.dstColor, vec4(ui.textColor.rgb, 1), ui.textColor.a);

	ui.pxCursor.x += s2h_fontSize() * ui.scale;

	vec2 delta = round(ui.mouseInput.xy + 0.5f - ui.pxPos);

	return mouseOver && delta.x == 0.0f && delta.y == 0.0f;
}


void s2h_progress(inout ContextGather ui, uint widthInCharacters, float fraction)
{
	vec4 color = ui.buttonColor;
	vec4 outerAABB = vec4(ui.pxCursor, ui.pxCursor + vec2(float(widthInCharacters) * s2h_fontSize(), s2h_fontSize() - 2.0f) * ui.scale);
	outerAABB += 0.5f;

	// shrink
	vec4 innerAABB = outerAABB + vec4(1, 1, -1, -1) * ui.scale;

	innerAABB.z = mix(innerAABB.x, innerAABB.z, clamp(fraction,0.0f,1.0f));

	float sliderDist = s2h_computeDistToBox(ui, ui.pxPos, outerAABB);
	float innerDist = s2h_computeDistToBox(ui, ui.pxPos, innerAABB);

	vec4 localColor = vec4(0,0,0,0);

	// no AA for now
	if(sliderDist <= 0.0f)
		localColor = color;

	if(innerDist <= 0.0f)
		localColor = mix(localColor, vec4(ui.textColor.rgb, 1), ui.textColor.a);

	ui.pxCursor.x += float(widthInCharacters) * s2h_fontSize() * ui.scale;

	ui.dstColor = mix(ui.dstColor, vec4(localColor.rgb, 1), localColor.a * (1.0f - ui.dstColor.a));
}


void s2h_sliderFloat(inout ContextGather ui, uint widthInCharacters, inout float value, float minValue, float maxValue)
{
	vec4 color = ui.buttonColor; 
	vec4 outerAABB = vec4(ui.pxCursor, ui.pxCursor + vec2(float(widthInCharacters) * s2h_fontSize(), s2h_fontSize() - 2.0f) * ui.scale);
 	outerAABB += 0.5f;

	float halfChar = s2h_fontSize() / 2.0f;
 
	// shrink 
	vec4 innerAABB = outerAABB + vec4(1, 1, -1, -1) * ui.scale;
 
	float sliderDist = s2h_computeDistToBox(ui, ui.pxPos, outerAABB);
 
	// todo: active button should be made for all UI interactive buttons (checkbox, radio, button)
	vec2 currentMouse = (ui.s2h_State.x == 0 && ui.s2h_State.y == 0) ? ui.mouseInput.xy : vec2(ui.s2h_State.xy);
 
	bool mouseOver = s2h_computeDistToBox(ui, currentMouse, outerAABB) <= 0.0f;
 
	vec3 knobColor = ui.textColor.rgb; 

	// mouse over and left mouse button pressed
	if(mouseOver && ui.mouseInput.z != 0.0f)
	{ 
		float newFraction = clamp((ui.mouseInput.xy.x - innerAABB.x) / (innerAABB.z - innerAABB.x),0.0f,1.0f); 
		value = mix(minValue, maxValue, newFraction); 
 
		knobColor = vec3(1, 1, 1); 
 
		// todo: active button should be made for all UI interactive buttons (checkbox, radio, button)
		if(ui.s2h_State.x == 0 && ui.s2h_State.y == 0)
			ui.s2h_State.xy = ivec2(ui.mouseInput.xy);
	} 
 
	float fraction = clamp((value - minValue) / (maxValue - minValue),0.0f,1.0f);

	float knobRange = (float(widthInCharacters) - 1.0f) * s2h_fontSize() * ui.scale;
	vec2 knobPos = ui.pxCursor + vec2(halfChar * ui.scale, 0.0f) + vec2(fraction * knobRange, 3.0f * ui.scale);
	vec2 knobSize = vec2(s2h_fontSize() - 4.0f, s2h_fontSize() - 4.0f) * 0.5f * ui.scale;
	vec4 knobAABB = vec4(knobPos - knobSize, knobPos + knobSize);
 	knobAABB += 0.5f;

	float knobDist = s2h_computeDistToBox(ui, ui.pxPos, knobAABB);

	vec4 localColor = vec4(0,0,0,0);

	if(mouseOver && sliderDist <= 2.0)
		localColor = vec4(1, 1, 1 ,1);

	// no AA for now
	if(sliderDist <= 0.0f)
		localColor = color;

//	if(innerDist <= 0.0f)
//		localColor = lerp(localColor, float4(ui.textColor.rgb, 1), ui.textColor.a);

	if(knobDist <= 0.0f)
		localColor = mix(localColor, vec4(knobColor, 1), ui.textColor.a);

	ui.pxCursor.x += float(widthInCharacters) * s2h_fontSize() * ui.scale;

	ui.dstColor = mix(ui.dstColor, vec4(localColor.rgb, 1), localColor.a * (1.0f - ui.dstColor.a));
} 

void s2h_sliderRGB(inout ContextGather ui, uint widthInCharacters, inout vec3 value)
{
	float r = 3.0f * s2h_fontSize() * 0.5f * ui.scale - 1.0f;
	vec4 backup = ui.buttonColor;

	vec2 initialPos = ui.pxCursor;
	vec2 pos = initialPos + vec2(3.0f * s2h_fontSize() * ui.scale, 0.0f);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(1,0.1f,0.1f,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.r, 0.0f, 1.0f);
	s2h_printLF(ui);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(0,1,0,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.g, 0.0f, 1.0f);
	s2h_printLF(ui);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(0.2f,0.2f,1,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.b, 0.0f, 1.0f);
	s2h_printLF(ui);

	// todo: don't abuse circle drawing for disk drawing
	// todo: check if sRGB blending is right, it looks wrong with white
	s2h_drawDisc(ui, initialPos + r, r, vec4(value, 1));

	ui.pxCursor = initialPos + vec2(float(widthInCharacters) * s2h_fontSize() * ui.scale, 0.0f);

	ui.buttonColor = backup;
}

void s2h_sliderRGBA(inout ContextGather ui, uint widthInCharacters, inout vec4 value)
{
	float r = 3.0f * s2h_fontSize() * 0.5f * ui.scale - 1.0f;
	vec4 backup = ui.buttonColor;

	vec2 initialPos = ui.pxCursor;
	vec2 pos = initialPos + vec2(3.0f * s2h_fontSize() * ui.scale, 0.0f);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(1,0.1f,0.1f,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.r, 0.0f, 1.0f);
	s2h_printLF(ui);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(0,1,0,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.g, 0.0f, 1.0f);
	s2h_printLF(ui);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(0.2f,0.2f,1,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.b, 0.0f, 1.0f);
	s2h_printLF(ui);

	ui.pxCursor.x = pos.x;
	ui.buttonColor = vec4(0.5f,0.5f,0.5f,1);
	s2h_sliderFloat(ui, widthInCharacters - 3u, value.a, 0.0f, 1.0f);
	s2h_printLF(ui);

	// todo: don't abuse circle drawing for disk drawing
	// todo: check if sRGB blending is right, it looks wrong with white
	s2h_drawDisc(ui, initialPos + r, r, value);

	ui.pxCursor = initialPos + vec2(float(widthInCharacters) * s2h_fontSize() * ui.scale, 0.0f);

	ui.buttonColor = backup;
}

// not yet for GLSL 































































































vec3 s2h_accurateLinearToSRGB(vec3 linearCol)
{
	vec3 sRGBLo = linearCol * 12.92;
	vec3 sRGBHi = (pow(abs(linearCol), vec3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
	vec3 sRGB;
	sRGB.r = linearCol.r <= 0.0031308 ? sRGBLo.r : sRGBHi.r;
	sRGB.g = linearCol.g <= 0.0031308 ? sRGBLo.g : sRGBHi.g;
	sRGB.b = linearCol.b <= 0.0031308 ? sRGBLo.b : sRGBHi.b;
	return sRGB;
}

vec3 s2h_accurateSRGBToLinear(vec3 sRGBCol)
{
	vec3 linearRGBLo = sRGBCol / 12.92;
	vec3 linearRGBHi = pow((sRGBCol + 0.055) / 1.055, vec3(2.4, 2.4, 2.4));
	vec3 linearRGB;
	linearRGB.r = sRGBCol.r <= 0.04045 ? linearRGBLo.r : linearRGBHi.r;
	linearRGB.g = sRGBCol.g <= 0.04045 ? linearRGBLo.g : linearRGBHi.g;
	linearRGB.b = sRGBCol.b <= 0.04045 ? linearRGBLo.b : linearRGBHi.b;
	return linearRGB;
}

vec3 s2h_indexToColor(uint index)
{
	uint a = index & (1u << 0u);
	uint d = index & (1u << 1u);
	uint g = index & (1u << 2u);

	uint b = index & (1u << 3u);
	uint e = index & (1u << 4u);
	uint h = index & (1u << 5u);

	uint c = index & (1u << 6u);
	uint f = index & (1u << 7u);
	uint i = index & (1u << 8u);

	return vec3(a * 4u + b * 2u + c, d * 4u + e * 2u + f, g * 4u + h * 2u + i) / 7.0f;
}

vec3 s2h_colorRampRGB(float value)
{
	return vec3(
		clamp(1.0f - abs(value) * 2.0f,0.0f,1.0f),
		clamp(1.0f - abs(value - 0.5f) * 2.0f,0.0f,1.0f),
		clamp(1.0f - abs(value - 1.0f) * 2.0f,0.0f,1.0f));
}
