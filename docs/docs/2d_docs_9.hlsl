




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();

    float2 clockCenter = float2(150.0f, S2S_FRAMEBUFFERSIZE().y / 2.0f);

    ui.lineWidth = 3.0f;
    s2h_drawCircle(ui, clockCenter, 120.0f, float4(0.0f, 0.0f, 0.0f, 1.0f));

    float2 mousePos = float2(ui.mouseInput.x, ui.mouseInput.y);
    float2 dir = normalize(mousePos - clockCenter);

    float angle = 3.14159265f / 4.0f;
    float2 dir2 = float2(dir.x * cos(angle) - dir.y * sin(angle),
                         dir.x * sin(angle) + dir.y * cos(angle));

    ui.lineWidth = 5.0f;
    s2h_drawArrow(ui, clockCenter, clockCenter + dir * 70.0f,
                  float4(0.0f, 0.0f, 1.0f, 1.0f), 15.0f, 10.0f);
    s2h_drawArrow(ui, clockCenter, clockCenter + dir2 * 35.0f,
                  float4(0.5f, 0.5f, 1.0f, 1.0f), 12.0f, 9.0f);

    float2 rightPos = float2(S2S_FRAMEBUFFERSIZE().x - 150.0f, S2S_FRAMEBUFFERSIZE().y / 2.0f);

    s2h_drawArrow(ui, rightPos + float2(0.0f, -40.0f), rightPos + float2(120.0f, -40.0f),
                  float4(0.6f, 0.2f, 0.8f, 1.0f), 20.0f, 15.0f);
    s2h_drawArrow(ui, rightPos, rightPos + float2(120.0f, 0.0f),
                  float4(1.0f, 0.4f, 0.7f, 1.0f), 20.0f, 15.0f);
    s2h_drawArrow(ui, rightPos + float2(0.0f, 40.0f), rightPos + float2(120.0f, 40.0f),
                  float4(1.0f, 0.6f, 0.5f, 1.0f), 20.0f, 15.0f);


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

