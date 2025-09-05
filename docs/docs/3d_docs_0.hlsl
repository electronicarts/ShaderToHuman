





































//!KEEP #include "include/s2h.hlsl"
//!KEEP #include "include/s2h_3d.hlsl"


// 1:no Anti-Aliasing (fast), 2:2x2, 3:3x3 (pretty)
static const int AA = 3;


/*$(ShaderResources)*/


float4x4 lookAt(float3 eye, float3 target, float3 up)
{
    float3 zaxis = normalize(target - eye);
    float3 xaxis = normalize(cross(up, zaxis));
    float3 yaxis = cross(zaxis, xaxis);
    return S2S_MAKE_FLOAT4x4(float4(xaxis, 0), float4(yaxis, 0), float4(zaxis, 0), float4(eye, 1));
}

void scene(inout Context3D context)
{
    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    float3 offset = float3(0,-1,0);

    s2h_drawCheckerBoard(context, offset);
























}

float3 computeSkyColor(inout Context3D context)
{
    return normalize(context.rd * 0.5 + 0.5) * 0.5f;
}

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

	Context3D context;
    ContextGather ui;

    float3 wsCamPos = S2S_CAMERA_POS();

    s2h_init(ui, float2(pxPos));
    s2h_setCursor(ui, float2(10, 10));
    s2h_printTxt(ui, _P, _o, _s, _COLON);
    s2h_printFloat(ui, wsCamPos.x); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, wsCamPos.y); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, wsCamPos.z);
    s2h_printLF(ui);
    s2h_printLF(ui);

    s2h_setScale(ui, 3.0f);
    s2h_printTxt(ui, _SPACE, _W);
    s2h_printLF(ui);
    s2h_printTxt(ui, _A, _S, _D);

    float4 tot = float4(0, 0, 0, 0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        float2 subPixel = float2(float(m), float(n)) / float(AA) - float2(0.5, 0.5);
        float2 uv = (float2(pxPos) + subPixel) / S2S_FRAMEBUFFERSIZE();

        float3 worldPos;
        {
            float2 screenPos = uv * 2.0f - 1.0f;

            screenPos.y = -screenPos.y;
            float4 worldPosHom = mul(float4(screenPos, S2S_NEAR(), 1), S2S_INV_VIEW_PROJECTION());
            worldPos = worldPosHom.xyz / worldPosHom.w;
        }

        s2h_init(context, S2S_CAMERA_POS(), normalize(worldPos - context.ro));

        // uncomment to composite with former pass
        context.dstColor = float4(computeSkyColor(context), 1);

        sceneWithShadows(context);















        tot += context.dstColor;
    }
    tot /= float(AA*AA);

	// visualize transparency
	fragColor = float4(0, 0, 0, 0);
    // composite 3D UI on top   
    fragColor = lerp(fragColor, float4(tot.rgb, 1), tot.a);
    // composite 2D UI on top
    fragColor = fragColor * (1.0f - ui.dstColor.a) + ui.dstColor;
}



[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

