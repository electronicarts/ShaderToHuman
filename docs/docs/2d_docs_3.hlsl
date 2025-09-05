




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();




















    s2h_drawCrosshair(ui, ui.mouseInput.xy + 0.5f, 10.0f, float4(1,1,1,1), 2.0f);
    int edgeCount = 3;
    bool inside = true;
    float insideAA = 1.0f;
    for(int i = 0; i < edgeCount; ++i)
    {
        float2 center = float2(150, 50);

        float w = float(i) * 3.14159265f * 2.0f / float(edgeCount) + 0.2f;
        float3 halfSpace = float3(sin(w), cos(w), -20);
        halfSpace.z -= dot(halfSpace, float3(center, 0));

        s2h_drawHalfSpace(ui, halfSpace, ui.mouseInput.xy + 0.5f, float4(s2h_indexToColor(uint(i + 1)),1), 10.0f, 20.0f);

        if(dot(halfSpace, float3(ui.pxPos, 1)) > 0.0f)
            inside = false;
 
        insideAA *= saturate(0.5f - dot(halfSpace, float3(ui.pxPos - float2(200, 0), 1)));
    }

    if(inside) ui.dstColor = float4(1, 1, 1, 1);
    ui.dstColor = lerp(ui.dstColor, float4(1,1,1,1), insideAA);

    s2h_setScale(ui, 2.0f);
    s2h_setCursor(ui, float2(166, 10));
    s2h_printTxt(ui, _n, _o, _A, _A);
    s2h_setCursor(ui, float2(366, 10));
    s2h_printTxt(ui, _A, _A);






















































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

