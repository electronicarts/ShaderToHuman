/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_scatter.hlsl"
#include "../../include/s2h_3d.hlsl"
#include "SplatCommon.hlsl"

// 1: low quality
// 16: high quality
// 64: very high quality
#define SAMPLE_COUNT 64

// RWStructuredBuffer<Struct_UIState> UIState : register(u1);  // need to be transient to maintain state

/*$(ShaderResources)*/

void scene(inout Context3D context)
{
    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    float3 offset = float3(0,-1,0);

    s2h_drawCheckerBoard(context, offset);

    // todo: check for sRGB correct blending, a=0.5 seems too faint

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    // world basis
//    float4x4 identity = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
//    drawBasis(context, identity, 10.0f);

    // center
//    drawSphereWS(context, getSplatParams(0).pos, float4(1, 0, 0, 0.5f), 0.2f);

    SplatRasterizeParams params;

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

    uint splatId = 0;

	SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);

	float4x4 splatBase = computeSplatBase(splatParams);

    // splat basis
    s2h_drawBasis(context, splatBase, GAUSSIAN_CUTOFF_SCALE);
}

// clear to black and render base of the splat together with World Space basis
[numthreads(8, 8, 1)]
void baseCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;
    float2 pxPosFloat = pxPos + 0.5f;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float2 uv = pxPosFloat / dimensions.xy;

    // clear screen
    float3 background = float3(0.1f, 0.2f, 0.3f) * 0.7f;
    float4 linearOutput = float4(background,1);

    float3 worldPos;
    {
        float2 screenPos = uv * 2.0 - 1.0;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, /*$(Variable:CameraNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }

    Context3D context;

    s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

#if TESTID != 1 // CS Ray is doing intersection with scene in mainCS
    scene(context);
    linearOutput = lerp(linearOutput, float4(context.dstColor.rgb, 1), context.dstColor.a);
#endif

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 40));
        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;

        ui.textColor.rgb = float3(1,1,1);

        s2h_setScale(ui, 3);
        s2h_printTxt(ui, 'S', 'p', 'l', 'a');
        s2h_printTxt(ui, 't', 'T', 'e', 's', 't');
        s2h_printLF(ui);

        s2h_setScale(ui, 2);
        s2h_printLF(ui);

#if TESTID == 0 // CS Raster
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 's', 't', 'e', 'r');
        s2h_printLF(ui);
#elif TESTID == 1 // CS Ray
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 'y');
        s2h_printLF(ui);
        s2h_printTxt(ui, 'P', 'e', 'r', 's', 'p');
        s2h_printTxt(ui, 'e', 'c', 't', 'i', 'v');
        s2h_printTxt(ui, 'e', 'C', 'o', 'r', 'r');
        s2h_printTxt(ui, 'e', 'c', 't');
        s2h_printLF(ui);
#elif TESTID == 2 // VSPS Raster
        s2h_printTxt(ui, 'V', 'S', 'P', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 's', 't', 'e', 'r');
        s2h_printLF(ui);
#elif TESTID == 3 // CS Ray many splats
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 'y');
        s2h_printLF(ui);
        s2h_printTxt(ui, 'M', 'a', 'n', 'y', 'S');
        s2h_printTxt(ui, 'p', 'l', 'a', 't', 's');
        s2h_printLF(ui);
#endif

		s2h_drawSRGBRamp(ui, float2(2, 2));

        linearOutput = lerp(linearOutput, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
    }

    float4 sRGBOutput = float4(s2h_accurateLinearToSRGB(linearOutput.rgb), linearOutput.a);

    // sRGB test ramp/gradient on top of the screen, first 256 pixels should have a ramp of color from 0 to 255 
    // this means we output directly in sRGB space
//    if(DTid.y < 32)
//        sRGBOutput = float4(pxPos.xxx / 256.0f, 1);


    Output[DTid] = sRGBOutput;
}

// @return linearColor with Alpha
void stochasticSplats(inout Context3D context, inout uint rndState)
{
    float3 rayStart = context.ro + context.rd * /*$(Variable:rayStart)*/;

    // maxT is defined by the scene content (checkerboard and the UI settings)
    float maxT = min(/*$(Variable:rayEnd)*/, context.depth) - /*$(Variable:rayStart)*/;

    for(uint i = 0; i < 6; ++i)
//    for(uint i = 0; i < 1; ++i)
    {
	    uint splatId = i;

        SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);

        float rndDepth = nextRand(rndState);
        float4 sRGBOutput = SplatRayCast(rayStart, context.rd, splatParams, rndDepth, maxT);

        if(1)   // stochastic
        {
            if(sRGBOutput.a > nextRand(rndState))
            if(rndDepth < context.depth)
            {
                context.depth = rndDepth;
                context.dstColor = float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), 1);
//                context.dstColor = float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), sRGBOutput.a);
//                context.dstColor = float4(sRGBOutput.rgb, 1);
                // 
//                todo: depth
            }
        }
        else
        {
            // this composites the splat onto the screen
//            linearOutput = lerp(linearOutput, float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), 1), sRGBOutput.a);
        }
    }
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    if(DTid.y < 32)
        return;

    uint2 pxPos = DTid;
    float2 pxPosFloat = pxPos + 0.5f;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float2 uv = pxPosFloat / dimensions.xy;

    float3 worldPos;
    {
        float2 screenPos = uv * 2.0 - 1.0;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, /*$(Variable:CameraNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }

    Context3D context;

    s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

    // linear output, not sRGB
    float4 linearOutput = float4(s2h_accurateSRGBToLinear(Output[DTid].rgb), Output[DTid].a);

#if TESTID == 1 // CS Ray is doing intersection with scene in mainCS
    scene(context);
    linearOutput = lerp(linearOutput, float4(context.dstColor.rgb, 1), context.dstColor.a);
#endif

    uint splatId = 0;

    SplatRasterizeParams params;

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

	SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);

    bool visible = computeSplatRasterizeParams(splatParams, params, dimensions, worldToClip, viewToClip, worldToView);

    uint rndState = initRand(dot(uint3(DTid,0), uint3(82927, 21313, 1)), 0x12345678 + /*$(Variable:frameRandom)*/ * /*$(Variable:iFrame)*/);

    if(visible)
    {
    	// seems 3DGS is defined in sRGB, which seems wrong but makes porting to older platforms and the web easier
        // the rasterizer code
        float4 sRGBOutput;

        float3 rayStart = context.ro + context.rd * /*$(Variable:rayStart)*/;

#if TESTID == 0 // CS Raster
        sRGBOutput = params.evaluate(pxPos + 0.5f);
        // this composites the splat onto the screen
        linearOutput = lerp(linearOutput, float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), 1), sRGBOutput.a);

        // visualize bounding ellipse
        if(1)
        {
            float a = params.computeOriginalConicPs().x;
            float b = params.computeOriginalConicPs().y;
            float c = params.computeOriginalConicPs().z;

            float x = pxPosFloat.x - params.psCenter.x;
            float y = pxPosFloat.y - params.psCenter.y;

            float gaussianCutoffScale = GAUSSIAN_CUTOFF_SCALE;

            float error = a * x * x + 2.0 * b * x * y + c * y * y - gaussianCutoffScale * gaussianCutoffScale;

            if(abs(error) < 0.1)
                linearOutput = lerp(linearOutput, float4(0, 1, 0, 1), 0.5f);
        }

        // UI2D
        if(1)       // draw 2D AABB (2D rectangle) around the splat
        {
            ContextGather ui;

            s2h_init(ui, pxPos);
            s2h_setCursor(ui, float2(10, 10));

            if(visible)
            {
                float3 wsPos = splatParams.pos;
    //            float3 wsPos = float3(0,-1,0);
                float4 csPos = mul(worldToClip, float4(wsPos, 1));
                // left..right: -1..1, bottom..top:-1..1
                float2 uvPos = csPos.xy / csPos.w * float2(0.5f, -0.5f) + 0.5f;
                float2 pxPos = uvPos * dimensions;
            

    //            s2h_drawCrosshair(ui, pxPos, 20, float4(1, 1, 1, 1), 4);

                float4 aabb2 = params.computeAABB();

    //            s2h_drawRectangle(ui, aabb2.xy, aabb2.zw, float4(0, 1, 0, 0.5f));
                s2h_drawRectangleAA(ui, aabb2.xy, aabb2.zw, float4(0, 1, 1, 0.5f), float4(0,0,0,0), 3);

                linearOutput = float4(linearOutput.rgb * (1 - ui.dstColor.a) + ui.dstColor.rgb, linearOutput.a);
            }
        }

#elif TESTID == 1 // CS Ray
        // maxT is defined by the scene content (checkerboard and the UI settings)
        float maxT = min(/*$(Variable:rayEnd)*/, context.depth) - /*$(Variable:rayStart)*/;

        float rndDepth = FLT_MAX;
        sRGBOutput = SplatRayCast(rayStart, context.rd, splatParams, rndDepth, maxT);
        // this composites the splat onto the screen
        linearOutput = lerp(linearOutput, float4(s2h_accurateSRGBToLinear(sRGBOutput.rgb), 1), sRGBOutput.a);
#elif TESTID == 3 // CS Ray many splats

        // CS Ray is doing intersection with scene in mainCS
        scene(context);
        {
            const uint count = SAMPLE_COUNT;

            float4 sum = 0;
            for(uint i = 0; i < count; ++i)
            {
                Context3D innerContext = context;

                stochasticSplats(innerContext, rndState);
                sum += float4(innerContext.dstColor.rgb * innerContext.dstColor.a, innerContext.dstColor.a);    // do premultplied (todo)
            }
            context.dstColor = sum / count;
            if(context.dstColor.a > 0.0001f)
                context.dstColor = float4(context.dstColor.rgb / context.dstColor.a, context.dstColor.a);   // undo premultiplied
        }

        linearOutput = lerp(linearOutput, float4(context.dstColor.rgb, 1), context.dstColor.a);
#endif
    }

    Output[DTid] = float4(s2h_accurateLinearToSRGB(linearOutput.rgb), linearOutput.a);
}