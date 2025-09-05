




































//!KEEP #include "include/s2h.hlsl"


void mainImage( out float4 fragColor, in float2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y));

    s2h_printLF(ui);
    s2h_setScale(ui, 8.0);
    s2h_printSpace(ui, 2.4f);
    ui.textColor.rgb = float3(1, 0, 0); s2h_printTxt(ui, _S);
    ui.textColor.rgb = float3(0, 1, 0); s2h_printTxt(ui, _2);
    ui.textColor.rgb = float3(0, 0, 1); s2h_printTxt(ui, _H);
    s2h_printLF(ui);
    s2h_setScale(ui, 2.0);

    s2h_printSpace(ui, 8.0f);
    ui.textColor.rgb = float3(0.5f, 0.5f, 0.5f);
    s2h_printTxt(ui, _S, _2, _H, _UNDERSCORE);
    s2h_printTxt(ui, _V, _E, _R, _S);
    s2h_printTxt(ui, _I, _O, _N, _COLON);
    s2h_printInt(ui, 10);

    fragColor = float4(ui.dstColor.rgb, 1);
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

