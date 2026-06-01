




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);














































































































    float2 center = S2S_FRAMEBUFFERSIZE() / 2.0f;

    ui.lineWidth = 3.0f;

    for (int i = 5; i >= 1; i--)
    {
        float size = i * 25.0f;
        float alpha = 0.3f + (i * 0.1f);

        s2h_Triangle tri;
        tri.A = center + float2(0.0f, -size);
        tri.B = center + float2(-size * 0.866f, size * 0.5f);
        tri.C = center + float2(size * 0.866f, size * 0.5f);

        float t = float(i) / 5.0f;
        float4 color = float4(0.1f + t * 0.7f, 0.2f + t * 0.5f, 0.9f - t * 0.6f, alpha);

        s2h_drawTriangle(ui, tri, color);
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

