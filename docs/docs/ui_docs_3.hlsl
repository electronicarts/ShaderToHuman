



































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
            s2h_sliderFloat(ui, 8u, UIState[0].colorSlider0.a, 0.0f, 1.0f);
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
            s2h_printTxt(ui, _F, _l, _o, _a, _t);
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

