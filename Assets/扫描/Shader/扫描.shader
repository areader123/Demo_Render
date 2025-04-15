Shader "扫描"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"
        }
        ZTest Always
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // Blit.hlsl 提供 vertex shader (Vert), input structure (Attributes) and output strucutre (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary//SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uvs[9] : TEXCOORD0;
                float4 screenPos : TEXCOORD11;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD12;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float4 _ScanColor;

            //用uv获取世界坐标


            // 中心渐变的范围
            #define centerFadeoutDistance1 1
            #define centerFadeoutDistance2 6

            float3 scanColorHead;
            float3 scanColor;
            float outlineWidth;
            float outlineBrightness;
            float outlineStarDistance;

            float scanLineInterval;
            float scanLineWidth;
            float scanLineBrightness;
            float scanRange;

            float4 scanCenterWS;
            float headScanLineDistance;
            float headScanLineWidth;
            float headScanLineBrightness;

            float4x4 _ViewToWorld;

            v2f vert(appdata v)
            {
                v2f o;
                //o.vertex = GetFullScreenTriangleVertexPosition(v.vertexID);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                //float2 uv = GetFullScreenTriangleTexCoord(v.vertexID);
                o.uvs[4] = v.uv;
                o.uvs[0] = v.uv + _ScreenSize.zw * half2(-1, 1) * outlineWidth;
                o.uvs[1] = v.uv + _ScreenSize.zw * half2(0, 1) * outlineWidth;
                o.uvs[2] = v.uv + _ScreenSize.zw * half2(1, 1) * outlineWidth;
                o.uvs[3] = v.uv + _ScreenSize.zw * half2(-1, 0) * outlineWidth;

                o.uvs[5] = v.uv + _ScreenSize.zw * half2(1, 0) * outlineWidth;
                o.uvs[6] = v.uv + _ScreenSize.zw * half2(-1, -1) * outlineWidth;
                o.uvs[7] = v.uv + _ScreenSize.zw * half2(0, -1) * outlineWidth;
                o.uvs[8] = v.uv + _ScreenSize.zw * half2(1, -1) * outlineWidth;
                o.worldPos = mul(UNITY_MATRIX_M, float4(v.vertex.xyz, 1)).xyz;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float3 GetPixelWorldPosition(float2 uv, float depth01)
            {
                //重建世界坐标
                //NDC反透视除法
                float3 farPosCS = float3(uv.x * 2 - 1, uv.y * 2 - 1, 1) * _ProjectionParams.z;

                //反投影
                float3 farPosVS = mul(unity_CameraInvProjection, farPosCS.xyzz).xyz;
                //获得裁切空间坐标
                float3 posVS = farPosVS * depth01;
                //return posVS;
                //转化为世界坐标
                float3 posWS = mul(_ViewToWorld, float4(posVS, 1.0)).xyz;
                return posWS;
            }

            half calculaateVerticalOutline(float2 uvs[9])
            {
                // 使用sobel算子计算深度纹理的梯度:-1 0 1 -2 0 2 -1 0 1   
                half color = 0;
                color += Linear01Depth(SampleSceneDepth(uvs[0]), _ZBufferParams) * -
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[1]), _ZBufferParams) * -
                    2;
                color += Linear01Depth(SampleSceneDepth(uvs[2]), _ZBufferParams) * -
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[6]), _ZBufferParams) *
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[7]), _ZBufferParams) *
                    2;
                color += Linear01Depth(SampleSceneDepth(uvs[8]), _ZBufferParams) *
                    1;
                return color;
            }

            // 横向卷积描边
            half calculateHorizontalOutline(float2 uvs[9])
            {
                // 使用sobel算子计算深度纹理的梯度:-1 0 1 -2 0 2 -1 0 1   
                half color = 0;
                color += Linear01Depth(SampleSceneDepth(uvs[0]), _ZBufferParams) * -
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[3]), _ZBufferParams) * -
                    2;
                color += Linear01Depth(SampleSceneDepth(uvs[6]), _ZBufferParams) * -
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[2]), _ZBufferParams) *
                    1;
                color += Linear01Depth(SampleSceneDepth(uvs[5]), _ZBufferParams) *
                    2;
                color += Linear01Depth(SampleSceneDepth(uvs[8]), _ZBufferParams) *
                    1;
                return color;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;

                float depth01 = Linear01Depth(SampleSceneDepth(screenPos), _ZBufferParams);

                float3 posWS = GetPixelWorldPosition(screenPos, depth01);

                float distanceToCenter = distance(scanCenterWS, posWS);

                //头部扫描线
                // head123 范围由远到近
                float scanHeadLine1 = smoothstep(headScanLineDistance + 0.5 * distanceToCenter * 0.03,
                                 headScanLineDistance, distanceToCenter);
                float scanHeadLine2 = smoothstep(headScanLineDistance - headScanLineWidth * distanceToCenter * 0.2,
                 headScanLineDistance, distanceToCenter);
                float scanHeadLine = scanHeadLine1 * scanHeadLine2 * scanHeadLine2 * scanHeadLine2 *
                    headScanLineBrightness;
                float4 scanHeadLineColor = float4(scanColorHead * scanHeadLine, scanHeadLine);


                float scanHeadLine3 = smoothstep(headScanLineDistance - headScanLineWidth * distanceToCenter * 0.4,
                    headScanLineDistance, distanceToCenter);

                float scanHeadLineBlack = scanHeadLine1 * scanHeadLine3 * scanHeadLine3 * scanHeadLine3 *
                    headScanLineBrightness;
                float4 scanHeadLineColorBlack = float4(0, 0, 0, scanHeadLineBlack / 2);
                // 平行扫描线范围遮罩
                float scanLineRange2 = smoothstep(headScanLineDistance - distanceToCenter * 2.5 * scanRange,
                                                                          headScanLineDistance, distanceToCenter);
                float scanLineRange = scanHeadLine1 * scanLineRange2 * scanLineRange2;
                //return scanLineRange2;
                // 中心渐变 
                float centerFadeout = smoothstep(3, 6, distanceToCenter);


                //扫描
                float wave = frac(distanceToCenter / scanLineInterval);
                float scanLine1 = smoothstep(0.5 - scanLineWidth * distanceToCenter * 0.003, 0.5, wave);
                float scanLine2 = smoothstep(0.5 + scanLineWidth * distanceToCenter * 0.003, 0.5, wave);
                float scanLine = scanLine1 * scanLine2;
                scanLine *= scanLineRange * scanLineBrightness * centerFadeout;
                float4 scanLineColor = float4(scanColor * scanLine, scanLine);


                //描边
                half outlineV = calculaateVerticalOutline(i.uvs);
                half outlineH = calculateHorizontalOutline(i.uvs);
                half outline = sqrt(outlineV * outlineV + outlineH * outlineH);
                // return outline;
                //用来处理远处太亮的距离遮罩：近处接近1，中距离接近0，远处为0
                float depthMask = saturate(1 - distanceToCenter * 0.01);
                depthMask *= depthMask;
                //描边遮罩
                half outLineDistanceMask = smoothstep(outlineStarDistance - 10, outlineStarDistance, distanceToCenter);
                outline *= 1000 * depthMask;
                //除去大于1的outline
                outline = step(1, outline) * outLineDistanceMask * outlineBrightness * scanHeadLine1;
                float4 outlineColor = float4(scanColor * outline, outline);
                //return  depthMask;
                //return  outLineDistanceMask;
                float4 color = scanHeadLineColor + scanHeadLineColorBlack + scanLineColor + outlineColor;
                //return clamp(distanceToCenter/100,0,1);
                //return outline;
                //return outlineColor;
                return color;
            }
            ENDHLSL
        }
    }
}