




































//!KEEP #include "include/s2h.hlsl"
//!KEEP #include "include/s2h_scatter.hlsl"



/*$(ShaderResources)*/


void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float2 uv = fragCoord / dimensions; uv.y = 1.0f - uv.y;
    float2 pxPos = uv * dimensions - 0.5f;
 
    float4 ret = float4(0,0,0,0);

    {
        ContextGather ui;

        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, float2(10, 10));

        s2h_setScale(ui, 2.0f);

        ui.textColor.rgb = float3(1,1,1);
























































































































































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

