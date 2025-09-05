


































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/


void mainImage( out float4 fragColor, in float2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y));
 
    s2h_setCursor(ui, float2(10, 10));
    s2h_setScale(ui, 2.0f);
    ui.textColor.rgb = float3(1,1,1);










































    ui.textColor = float4(1, 1, 1, 1);
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _H, _e, _x);
    s2h_printLF(ui);
    s2h_printLF(ui);

    ui.textColor = float4(0, 0, 0, 1);
    s2h_printHex(ui, 0x1297ABu);
    s2h_printLF(ui);
    s2h_printLF(ui);




























































    float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);
    fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor;
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

