



































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/















void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y - 1.0f);

    float4 ret = float4(0,0,0,0);

    {
        ContextGather ui;





        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, float2(10, 10));
        s2h_setScale(ui, 2.0f);
        ui.s2h_State = UIState[0].s2h_State;





        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;


        ui.textColor.rgb = float3(1,1,1);


        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_printInt(ui, int(UIState[0].UIRadioState));
            s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
            s2h_printTxt(ui, _C, _l, _e, _a, _r);
            if(s2h_button(ui, 5u) && leftMouse) UIState[0].UIRadioState = 0u;
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _b, _u, _t, _t, _o, _n);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }












































































        // opaque green background
        float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;




    }
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor;
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

