/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_3d.hlsl"

/*$(ShaderResources)*/

bool s2h_tableLookupInt(uint column, uint row, out int outValue)
{
	if(column == 1) // Id
	{
		if(row > 10)
			return false;

		outValue = 2 + row * row;
	}
	else    // Cnt
	{
		if(row > 12)
			return false;

		outValue = row;
	}
	return true;
}

bool s2h_tableLookupFloat(uint column, uint row, out float outValue)
{
	float time = /*$(Variable:iTime)*/;
	if(column == 2)
	{
		if(row > 10)
			return false;
		outValue = sin(time + row * 0.5f);
	}
	else // 3
	{
		if(row > 10)
			return false;
		outValue = cos(time + row * 0.5f);
	}
	return true;
}

float s2h_floatLookupFloat(uint functionId, float x)
{
	float time = /*$(Variable:iTime)*/;
	return sin(x) + cos(time * 3.0f + x * 15.0f) * 0.1f;
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 10));
        ui.s2h_State = UIState[0].s2h_State;

        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

        ui.textColor.rgb = float3(1,1,1);

        s2h_setScale(ui, 3);
        s2h_printTxt(ui, 'T', 'a', 'b', 'l', 'e');
        s2h_printTxt(ui, 'T', 'e', 's', 't');
        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0,0);
        s2h_setScale(ui, 2);
        s2h_printTxt(ui, 'P', 'i', 'x', 'e', 'l', '=');
        s2h_printTxt(ui, 'T', 'h', 'r', 'e', 'a', 'd');
        s2h_setScale(ui, 3);
        s2h_printLF(ui);

        s2h_printLF(ui);
        s2h_setScale(ui, 2);
        s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, 't', 'a', 'b', 'l', 'e');
        s2h_printLF(ui);
        s2h_printLF(ui);

        // header
        s2h_printSpace(ui, 0.5f);
        s2h_printTxt(ui, 'I', 'd');
        s2h_printSpace(ui, 0.5f);
        s2h_frame(ui, 3);

        s2h_printSpace(ui, 1);
        s2h_printTxt(ui, 'C', 'n', 't');
        s2h_printSpace(ui, 1);
        s2h_frame(ui, 5);

        s2h_printSpace(ui, 3);
        s2h_printTxt(ui, 'x');
        s2h_printSpace(ui, 3);
        s2h_frame(ui, 7);

        s2h_printSpace(ui, 3);
        s2h_printTxt(ui, 'y');
        s2h_printSpace(ui, 3);
        s2h_frame(ui, 7);

        s2h_printLF(ui);

        s2h_tableInt(ui, 0, float4(1,1,1,0.35f), int2(3, 15), true);
        s2h_tableInt(ui, 1, float4(0.4f,0.4f,0.4f,0.75f), int2(5, 15), true);
        s2h_tableFloat(ui, 2, float4(1,0,0,0.35f), int2(7, 15), true);
        s2h_tableFloat(ui, 3, float4(0,1,0,0.25f), int2(7, 15), false);

        s2h_printLF(ui);
        s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE, 'f', 'u');
        s2h_printTxt(ui, 'n', 'c', 't', 'i', 'o', 'n');
        s2h_printLF(ui);

        ui.textColor.rgb = float3(1,1,1);
        float2 rangeX = float2(0, 3.14159265f * 2);
        float2 rangeY = float2(1.3f, -1.3f);
        s2h_function(ui, 0, float4(0,0,0,0.45f), int2(22, 8), rangeX, rangeY);

        s2h_setScale(ui, 1);
        ui.textColor.rgb = float3(0, 0, 0);
        s2h_printTxt(ui, 'x', ':', ' ');
        s2h_printFloat(ui, rangeX.x);
        s2h_printTxt(ui, ' ', '.', '.', ' ');
        s2h_printFloat(ui, rangeX.y);
        s2h_printLF(ui);
        s2h_printTxt(ui, 'y', ':', ' ');
        s2h_printFloat(ui, rangeY.x);
        s2h_printTxt(ui, ' ', '.', '.', ' ');
        s2h_printFloat(ui, rangeY.y);
        s2h_printLF(ui);


        // opaque green background
        float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);

        Output[DTid] = float4(background.rgb * (1 - ui.dstColor.a) + ui.dstColor.rgb, 1.0f);

        s2h_deinit(ui, UIState[0].s2h_State);
    }
}