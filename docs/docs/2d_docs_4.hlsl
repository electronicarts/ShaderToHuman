




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();




















































    s2h_drawRectangle(ui, float2(100, 10), float2(300, 90), float4(1,0,0,1));
    s2h_drawRectangle(ui, float2(200, 50), float2(400, 65), float4(0,1,0,1));
    s2h_drawRectangle(ui, float2(150, 25), float2(350, 75), float4(0,0,0,0.5f));















































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

