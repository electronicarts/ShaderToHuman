




































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

































        {
            s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _p, _r, _i, _n, _t);
            s2h_printTxt(ui, _T, _x, _t);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor.rgb = float3(0,0,0);
            s2h_setScale(ui, 3.0f);
            s2h_printLF(ui);

            s2h_setScale(ui, 8.0f);

            ui.textColor.rgb = float3(1,0,0);
            s2h_printTxt(ui, _R);
            ui.textColor.rgb = float3(0,1,0);
            s2h_printTxt(ui, _G);
            ui.textColor.rgb = float3(0,0,1);
            s2h_printTxt(ui, _B);
            s2h_printTxt(ui, _SPACE);
            ui.textColor.rgb = float3(0,0,0);
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

