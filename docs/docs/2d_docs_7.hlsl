




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();













































































    for(int i = 0; i < 5; ++i)
    {
        float w = float(i) * 1.1f + 1.0f;
        float2 center = float2(50, 50) + float2(90 * i, 0);
        float2 sc = float2(sin(w), cos(w)) * 20.0f;
        s2h_drawLine(ui, center + sc, center - sc, float4(s2h_indexToColor(uint(i)), 1), 1.0f + float(i) * 4.0f);
    }


















    float3 background = float3(0.7f, 0.4f, 0.4f);
    float3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = float4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

