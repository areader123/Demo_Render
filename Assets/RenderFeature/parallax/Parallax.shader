Shader "Unlit/Parallax"
{
    Properties
    {
        _BaseMap ("Base Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        //[Toggle(_NORMALMAP)]_NORMALMAP ("NormalMap", float) = 0
        [Normal]_BumpMap ("Normal Texture", 2D) = "bump" { }
        _BumpScale ("Normal Scale", Float) = 1

        [NoScaleOffset]_MetallicSmoothnessMap ("R-Metallic,G-Smoothness,B-AO,A-Emission", 2D) = "white" { }
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _OcclusionPower ("OcclusionPower", Range(0, 1)) = 1

        [Foldout(_EMISSION)]_EMISSION ("Emission", float) = 0
        [FoldoutEnd][Emission]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)

        [Foldout()]_PARALLAX ("ParallaxMapping", Float) = 0
        [NoScaleOffset]_ParallaxMap ("ParallaxMap", 2D) = "white" { }
        [Toggle(_POM)] _POM ("POM", float) = 0
        _Steps ("Steps", Range(1, 64)) = 8
        [Toggle(_JITTER)] _JITTER ("Jitter", float) = 0
        [FoldoutEnd][ShowIf(_JITTER)]_JitterScale ("JitterScale", Range(0, 1)) = 0.5
        [FoldoutEnd] _ParallaxAmplitude ("Parallax Amplitude", Range(0, 0.2)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _BumpScale;
            float4 _EmissionColor;
            float _Smoothness;
            float _Metallic;
            float _OcclusionPower;
            float _Cutoff;
            float _Parallax;
            float _ParallaxAmplitude;
            float _Steps;
            float _JitterScale;
        CBUFFER_END

        TEXTURE2D(_MetallicSmoothnessMap);
        SAMPLER(sampler_MetallicSmoothnessMap);

        TEXTURE2D(_ParallaxMap);
        SAMPLER(sampler_ParallaxMap);
        ENDHLSL

        Pass
        {
            Name "Example"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma only_renderers gles gles3 glcore d3d11

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            //#pragma shader_feature _METALLICSPECGLOSSMAP
            //#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature _OCCLUSIONMAP
            //#pragma shader_feature _ _CLEARCOAT _CLEARCOATMAP // URP v10+

            //#pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            //#pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _POM
            #pragma shader_feature _JITTER

            // URP Keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #define  _NORMALMAP
            //#define BUMP_SCALE_NOT_SUPPORTED 0
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "Assets/Shader/Noise.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
            };


            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                #ifdef REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
                    float3 positionWS : TEXCOORD2;
                #endif

                float3 normalWS : TEXCOORD3;
                #ifdef _NORMALMAP
                    float4 tangentWS : TEXCOORD4;
                #endif

                float3 viewDirWS : TEXCOORD5;
                half4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light

                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    float4 shadowCoord : TEXCOORD7;
                #endif
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                OUT.color = IN.color;

                #ifdef REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
                    OUT.positionWS = positionInputs.positionWS;
                #endif

                OUT.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                OUT.normalWS = normalInputs.normalWS;
                #ifdef _NORMALMAP
                    real sign = IN.tangentOS.w * GetOddNegativeScale();
                    OUT.tangentWS = half4(normalInputs.tangentWS.xyz, sign);
                #endif

                half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
                half fogFactor = ComputeFogFactor(positionInputs.positionCS.z);

                OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUV);
                OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);

                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    OUT.shadowCoord = GetShadowCoord(positionInputs);
                #endif

                return OUT;
            }

            InputData InitializeInputData(Varyings IN, half3 normalTS)
            {
                InputData inputData = (InputData)0;

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = IN.positionWS;
                #endif

                half3 viewDirWS = SafeNormalize(IN.viewDirWS);

                #ifdef _NORMALMAP
                    float sgn = IN.tangentWS.w; // should be either +1 or -1
                    float3 bitangent = sgn * cross(IN.normalWS.xyz, IN.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normalWS.xyz));
                #else
                    inputData.normalWS = IN.normalWS;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = viewDirWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = IN.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                inputData.fogCoord = IN.fogFactorAndVertexLight.x;
                inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(IN.lightmapUV, IN.vertexSH, inputData.normalWS);
                return inputData;
            }

            SurfaceData InitializeSurfaceData(Varyings IN)
            {
                SurfaceData surfaceData = (SurfaceData)0;

                half4 albedoAlpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
                surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * IN.color.rgb;

                half4 mask = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap, sampler_MetallicSmoothnessMap, IN.uv);

                surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

                #ifdef _EMISSION
                    surfaceData.emission = albedoAlpha.rgb * _EmissionColor * mask.a;
                #else
                    surfaceData.emission = half3(0, 0, 0);
                #endif

                surfaceData.occlusion = LerpWhiteTo(mask.b, _OcclusionPower);

                surfaceData.smoothness = mask.g * _Smoothness;

                surfaceData.metallic =mask.r * _Metallic;

                return surfaceData;
            }

            //视差贴图采样
            //不同于平常的视差贴图采样 有点不一样
            //unity 提供了官方的视差贴图采样
            inline float2 ParallaxOcclusionMapping(TEXTURE2D_PARAM(heightMap, sampler_heightMap), float2 uvs, float2 dx, float2 dy,
            float3 viewDirTan, int numSteps, float parallax, float refPlane)
            {
                float3 result = 0;
                int stepIndex = 0;
                float layerHeight = 1.0 / numSteps;
                float2 plane = parallax * (viewDirTan.xy / viewDirTan.z);
                uvs.xy += refPlane * plane;
                float2 deltaTex = -plane * layerHeight;
                float2 prevTexOffset = 0;
                float prevRayZ = 1.0f;
                float prevHeight = 0.0f;
                float2 currTexOffset = deltaTex;
                float currRayZ = 1.0f - layerHeight;
                float currHeight = 0.0f;
                float intersection = 0;
                float2 finalTexOffset = 0;
                while (stepIndex < numSteps + 1)
                {
                    currHeight = SAMPLE_TEXTURE2D_GRAD(heightMap, sampler_heightMap, uvs + currTexOffset, dx, dy).r;
                    if (currHeight > currRayZ)
                    {
                        stepIndex = numSteps + 1;
                    }
                    else
                    {
                        stepIndex++;
                        prevTexOffset = currTexOffset ;
                        prevRayZ = currRayZ;
                        prevHeight = currHeight;
                        currTexOffset += deltaTex;
                        currRayZ -= layerHeight;
                    }
                }
                int sectionSteps = 2;
                int sectionIndex = 0;
                float newZ = 0;
                float newHeight = 0;
                while (sectionIndex < sectionSteps)
                {
                    intersection = (prevHeight - prevRayZ) / (prevHeight - currHeight + currRayZ - prevRayZ);
                    finalTexOffset = prevTexOffset +intersection * deltaTex;
                    newZ = prevRayZ - intersection * layerHeight;
                    newHeight = SAMPLE_TEXTURE2D_GRAD(heightMap, sampler_heightMap, uvs + finalTexOffset, dx, dy).r;
                    if (newHeight > newZ)
                    {
                        currTexOffset = finalTexOffset;
                        currHeight = newHeight;
                        currRayZ = newZ;
                        deltaTex = intersection * deltaTex;
                        layerHeight = intersection * layerHeight;
                    }
                    else
                    {
                        prevTexOffset = finalTexOffset;
                        prevHeight = newHeight;
                        prevRayZ = newZ;
                        deltaTex = (1 - intersection) * deltaTex;
                        layerHeight = (1 - intersection) * layerHeight;
                    }
                    sectionIndex++;
                }
                return uvs.xy + finalTexOffset;
            }


            half4 frag(Varyings IN) : SV_Target
            {

                half3 viewDirWS = SafeNormalize(IN.viewDirWS);
                float3 viewDirTS = GetViewDirectionTangentSpace(IN.tangentWS, IN.normalWS, viewDirWS);

                #if defined(_POM)
                    uint minSteps = 1;
                    uint maxSteps = _Steps;

                    #ifdef _JITTER
                        float noise = InterleavedGradientNoise(IN.positionCS, 0);
                        noise = noise * _JitterScale;
                        maxSteps = maxSteps * 0.5 + maxSteps * noise;
                        maxSteps = max(maxSteps, 1);
                    #endif
                    
                    // 根据视角距离计算迭代次数(视角越远迭代次数越少)
                    float distMask = 1 - saturate(length(IN.viewDirWS) * 0.01);
                    // 根据法线和视角夹角计算迭代次数(法线和视角夹角越大迭代次数越少)
                    float NdotV = 1 - saturate(dot(IN.normalWS, viewDirWS));

                    distMask *= NdotV;
                    int numSteps = (int)lerp((float)minSteps, (float)maxSteps, distMask);

                    float2 offset = ParallaxOcclusionMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), IN.uv,
                    ddx(IN.uv), ddy(IN.uv), viewDirTS, numSteps, _ParallaxAmplitude, 0);
                    IN.uv = offset;
                #else
                //此处是unity提供的视差贴图采样
                    float2 offset = ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _ParallaxAmplitude, IN.uv);
                    IN.uv += offset;
                #endif


                SurfaceData surfaceData = InitializeSurfaceData(IN);

                
                InputData inputData = InitializeInputData(IN, surfaceData.normalTS);

                half4 color = UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic,
                surfaceData.specular, surfaceData.smoothness,
                surfaceData.occlusion,
                surfaceData.emission, surfaceData.alpha);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                color.a = saturate(color.a);

                return color;
            }
            ENDHLSL
        }

        // UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        // Note, you can do this, but it will break batching with the SRP Batcher currently due to the CBUFFERs not being the same.
        // So instead, we'll define the pass manually :
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
            //#pragma target 4.5

            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
