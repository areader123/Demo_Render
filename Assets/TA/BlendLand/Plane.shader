Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        [Toggle(_BLENDWEIGHT)]_BLENDWEIGHT ("_BLENDWEIGHT", float) = 0
        BlendContrast_Weight("BlendContrast_Weight",Range(0,0.1)) = 0.05
        //first
        _BaseMap ("Base Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        //[Toggle(_NORMALMAP)]_NORMALMAP ("NormalMap", float) = 0
        [Normal]_BumpMap ("Normal Texture", 2D) = "bump" { }
        _BumpScale ("Normal Scale", Float) = 1

        [Toggle(_RGBAMAP_FIR_ON)]_RGBAMAP_FIR_ON ("_RGBAMAP_FIR_ON", float) = 0
        [NoScaleOffset]_MetallicSmoothnessMap ("R-Metallic,G-Smoothness,B-AO,A-Emission", 2D) = "white" { }
        _MetallicMap("_MetallicMap",2D) ="white" {}
        _SmoothnessMap("_SmoothnessMap",2D) ="white" {}
        _AOMap("_AOMap",2D) ="white" {}
        _HeightMap("_HeightMap",2D) = "white" {}

        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _OcclusionPower ("OcclusionPower", Range(0, 1)) = 1
        [FoldoutEnd][Emission]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)


        //second
        _BaseMap_Sec ("Base Texture Sec", 2D) = "white" { }
        _BaseColor_Sec ("Base Color Sec", Color) = (1, 1, 1, 1)

        //[Toggle(_NORMALMAP)]_NORMALMAP ("NormalMap", float) = 0
        [Normal]_BumpMap_Sec ("Normal Texture Sec", 2D) = "bump" { }
        _BumpScale_Sec ("Normal Scale Sec", Float) = 1

        [Toggle(_RGBAMAP_SEC_ON)]_RGBAMAP_SEC_ON ("_RGBAMAP_SEC_ON", float) = 0

        [NoScaleOffset]_MetallicSmoothnessMap_Sec ("R-Metallic,G-Smoothness,B-AO,A-Emission Sec", 2D) = "white" { }
        _MetallicMap_Sec("_MetallicMap_Sec",2D) ="white" {}
        _SmoothnessMap_Sec("_SmoothnessMap_Sec",2D) ="white" {}
        _AOMap_Sec("_AOMap_Sec",2D) ="white" {}
        _HeightMap_Sec("_HeightMap_Sec",2D) = "white" {}

        _Smoothness_Sec ("Smoothness Sec", Range(0, 1)) = 0.5
        _Metallic_Sec ("Metallic Sec", Range(0.0, 1.0)) = 0.0
        _OcclusionPower_Sec ("OcclusionPower Sec", Range(0, 1)) = 1

        [FoldoutEnd][Emission]_EmissionColor_Sec ("Emission Color Sec", Color) = (0, 0, 0, 0)

        //third
        _BaseMap_Thi ("Base Texture Sec", 2D) = "white" { }
        _BaseColor_Thi ("Base Color Sec", Color) = (1, 1, 1, 1)

        //[Toggle(_NORMALMAP)]_NORMALMAP ("NormalMap", float) = 0
        [Normal]_BumpMap_Thi ("Normal Texture Sec", 2D) = "bump" { }
        _BumpScale_Thi ("Normal Scale Sec", Float) = 1

        [Toggle(_RGBAMAP_THI_ON)]_RGBAMAP_THI_ON ("_RGBAMAP_THI_ON", float) = 0

        [NoScaleOffset]_MetallicSmoothnessMap_Thi ("R-Metallic,G-Smoothness,B-AO,A-Emission Sec", 2D) = "white" { }
        _MetallicMap_Thi("_MetallicMap_Sec",2D) ="white" {}
        _SmoothnessMap_Thi("_SmoothnessMap_Sec",2D) ="white" {}
        _AOMap_Thi("_AOMap_Sec",2D) ="white" {}
        _HeightMap_Thi("_HeightMap_Thi",2D) = "white" {}

        _Smoothness_Thi ("Smoothness Sec", Range(0, 1)) = 0.5
        _Metallic_Thi ("Metallic Sec", Range(0.0, 1.0)) = 0.0
        _OcclusionPower_Thi ("OcclusionPower Sec", Range(0, 1)) = 1

        [FoldoutEnd][Emission]_EmissionColor_Thi ("Emission Color Sec", Color) = (0, 0, 0, 0)
        

        BlendContrast_Fir("BlendContrast_Fir",Range(0,1)) = 0.5 
        BlendContrast_Sec("BlendContrast_Sec",Range(0,1)) = 0.5 
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Assets/Shader/BlendMap.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _BumpScale;
            float4 _EmissionColor;
            float _Smoothness;
            float _Metallic;
            float _OcclusionPower;

            float _Cutoff;

            float4 _BaseMap_Sec_ST;
            float4 _BaseColor_Sec;
            float _BumpScale_Sec;
            float4 _EmissionColor_Sec;
            float _Smoothness_Sec;
            float _Metallic_Sec;
            float _OcclusionPower_Sec;

            float4 _BaseMap_Thi_ST;
            float4 _BaseColor_Thi;
            float _BumpScale_Thi;
            float4 _EmissionColor_Thi;
            float _Smoothness_Thi;
            float _Metallic_Thi;
            float _OcclusionPower_Thi;

            float BlendContrast_Fir;
            float BlendContrast_Sec;
            float BlendContrast_Weight;
            
        CBUFFER_END

        TEXTURE2D(_MetallicSmoothnessMap);
        SAMPLER(sampler_MetallicSmoothnessMap);

        TEXTURE2D(_MetallicSmoothnessMap_Sec);
        SAMPLER(sampler_MetallicSmoothnessMap_Sec);

        TEXTURE2D(_MetallicSmoothnessMap_Thi);
        SAMPLER(sampler_MetallicSmoothnessMap_Thi);

        TEXTURE2D(_SmoothnessMap);
        SAMPLER(sampler_SmoothnessMap);
        TEXTURE2D(_MetallicMap);
        SAMPLER(sampler_MetallicMap);
        TEXTURE2D(_AOMap);
        SAMPLER(sampler_AOMap);
        TEXTURE2D(_HeightMap);
        SAMPLER(sampler_HeightMap);



        TEXTURE2D(_BumpMap_Sec);
        SAMPLER(sampler_BumpMap_Sec);
        TEXTURE2D(_BaseMap_Sec);
        SAMPLER(sampler_BaseMap_Sec);

        TEXTURE2D(_MetallicMap_Sec);
        SAMPLER(sampler_MetallicMap_Sec);
        TEXTURE2D(_SmoothnessMap_Sec);
        SAMPLER(sampler_SmoothnessMap_Sec);
        TEXTURE2D(_AOMap_Sec);
        SAMPLER(sampler_AOMap_Sec);
        TEXTURE2D(_HeightMap_Sec);
        SAMPLER(sampler_HeightMap_Sec);


        
        TEXTURE2D(_BumpMap_Thi);
        SAMPLER(sampler_BumpMap_Thi);
        TEXTURE2D(_BaseMap_Thi);
        SAMPLER(sampler_BaseMap_Thi);

        // TEXTURE2D(_MetallicMap_Thi);
        // SAMPLER(sampler_MetallicMap_Thi);
        // TEXTURE2D(_SmoothnessMap_Thi);
        // SAMPLER(sampler_SmoothnessMap_Thi);
        // TEXTURE2D(_AOMap_Thi);
        // SAMPLER(sampler_AOMap_Thi);
        // TEXTURE2D(_HeightMap_Thi);
        // SAMPLER(sampler_HeightMap_Thi);


        



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
            #pragma shader_feature _RGBAMAP_FIR_ON
            #pragma shader_feature _RGBAMAP_SEC_ON
            #pragma shader_feature _RGBAMAP_THI_ON
            #pragma shader_feature _BLENDWEIGHT
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
                float4 color : TEXCOORD8;
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
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap_Sec);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap_Thi);

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
                //albedo
                //TRANSFORM_TEX(IN.uv,BaseMap_Sec);
                half4 albedoAlpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half4 albedoAlpha_Sec = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap_Sec, sampler_BaseMap_Sec));
                half4 albedoAlpha_Thi = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap_Thi, sampler_BaseMap_Thi));
                //height
                half Height_Fir = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,IN.uv).r;
                half Height_Sec = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap_Sec,sampler_MetallicSmoothnessMap_Sec,IN.uv).r;
                half Height_Thi = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap_Thi,sampler_MetallicSmoothnessMap_Thi,IN.uv).r;

                surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
                //surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * IN.color.r;
                surfaceData.albedo = lerp(albedoAlpha_Sec.rgb,albedoAlpha.rgb,HeigthLerp(Height_Fir,IN.color.r,BlendContrast_Fir));
                surfaceData.albedo = lerp(albedoAlpha_Thi.rgb,surfaceData.albedo.rgb,HeigthLerp(Height_Fir,IN.color.g,BlendContrast_Sec));
                //surfaceData.albedo =IN.color.rgb;
                half4 mask_Sec = 0;
                half4 mask_Thi = 0;
                half4 mask = 0;

                //surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                surfaceData.normalTS = lerp(SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap_Sec, sampler_BumpMap_Sec), _BumpScale),SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale_Sec),HeigthLerp(Height_Fir,IN.color.r,BlendContrast_Fir));
                surfaceData.normalTS = lerp(SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap_Thi, sampler_BumpMap_Thi), _BumpScale_Thi),surfaceData.normalTS,HeigthLerp(Height_Fir,IN.color.g,BlendContrast_Sec));

                #if defined(_RGBAMAP_FIR_ON)
                     mask = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap, sampler_MetallicSmoothnessMap, IN.uv);
                #endif
                #if defined(_RGBAMAP_SEC_ON)
                     mask_Sec = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap_Sec, sampler_MetallicSmoothnessMap_Sec, IN.uv);
                #endif
                #if defined(_RGBAMAP_THI_ON)
                     mask_Thi = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap_Thi, sampler_MetallicSmoothnessMap_Thi, IN.uv);
                #endif

                #ifdef _EMISSION
                    surfaceData.emission = albedoAlpha.rgb * _EmissionColor * mask.a;
                #else
                    surfaceData.emission = half3(0, 0, 0);
                #endif
                
                mask.b = SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap,IN.uv);
                mask.g =1 - SAMPLE_TEXTURE2D(_SmoothnessMap,sampler_SmoothnessMap,IN.uv);
                mask.r = SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap,IN.uv);
               

                // mask_Sec.b = SAMPLE_TEXTURE2D(_AOMap_Sec,sampler_AOMap_Sec,IN.uv);
                // mask_Sec.g =1 - SAMPLE_TEXTURE2D(_SmoothnessMap_Sec,sampler_SmoothnessMap_Sec,IN.uv);
                // mask_Sec.r = SAMPLE_TEXTURE2D(_MetallicMap_Sec,sampler_MetallicMap_Sec,IN.uv);  

                // mask_Thi.b = SAMPLE_TEXTURE2D(_AOMap_Thi,sampler_AOMap_Thi,IN.uv);
                // mask_Thi.g = SAMPLE_TEXTURE2D(_SmoothnessMap_Thi,sampler_SmoothnessMap_Thi,IN.uv);
                // mask_Thi.r = SAMPLE_TEXTURE2D(_MetallicMap_Thi,sampler_MetallicMap_Thi,IN.uv);  

                
                surfaceData.occlusion = lerp(LerpWhiteTo(mask_Sec.b,_OcclusionPower_Sec),LerpWhiteTo(mask.b, _OcclusionPower),HeigthLerp(Height_Fir,IN.color.r,BlendContrast_Fir));

                surfaceData.occlusion = lerp(LerpWhiteTo(mask_Thi.b, _OcclusionPower_Thi),surfaceData.occlusion,HeigthLerp(Height_Fir,IN.color.g,BlendContrast_Sec));

                surfaceData.smoothness =lerp(mask.g * _Smoothness,mask_Sec.g * _Smoothness_Sec,HeigthLerp(Height_Fir,IN.color.r,BlendContrast_Fir));

                surfaceData.smoothness =lerp(mask_Thi.g * _Smoothness_Thi,surfaceData.smoothness , HeigthLerp(Height_Fir,IN.color.g,BlendContrast_Sec));   

                surfaceData.metallic =lerp(mask.r * _Metallic,mask_Sec.r * _Metallic_Sec,HeigthLerp(Height_Fir,IN.color.r,BlendContrast_Fir));

                surfaceData.metallic =lerp(mask_Thi.r * _Metallic_Thi,surfaceData.metallic,HeigthLerp(Height_Fir,IN.color.g,BlendContrast_Sec));

                #if defined(_BLENDWEIGHT)
                    half3 vertexWeight = BlendWeightWithHeight(IN.color,BlendContrast_Weight,Height_Fir,Height_Sec,Height_Thi);
                    //albedo
                    surfaceData.albedo = albedoAlpha.rgb * vertexWeight.r + albedoAlpha_Sec.rgb * vertexWeight.g + albedoAlpha_Thi.rgb * vertexWeight.b;
                    surfaceData.alpha = albedoAlpha.a * vertexWeight.r + albedoAlpha_Sec.a * vertexWeight.g + albedoAlpha_Thi.a * vertexWeight.b;
                    surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap_Sec, sampler_BumpMap_Sec), _BumpScale) * vertexWeight.g +SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale_Sec) * vertexWeight.r + SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap_Thi, sampler_BumpMap_Thi), _BumpScale_Thi) * vertexWeight.b;
                    surfaceData.occlusion =  LerpWhiteTo(mask.b, _OcclusionPower) * vertexWeight.r + LerpWhiteTo(mask_Sec.b,_OcclusionPower_Sec) * vertexWeight.g + LerpWhiteTo(mask_Thi.b, _OcclusionPower_Thi)* vertexWeight.b;
                    surfaceData.smoothness = mask.g * _Smoothness * vertexWeight.r + mask_Sec.g * _Smoothness_Sec * vertexWeight.g + mask_Thi.g * _Smoothness_Thi* vertexWeight.b;
                    //
                    //surfaceData.metallic = mask.r * _Metallic * vertexWeight.r + mask_Sec.r * _Metallic_Sec * vertexWeight.g + mask_Thi.r * _Metallic_Thi * vertexWeight.b;
                #endif

                return surfaceData;
            }



            half4 frag(Varyings IN) : SV_Target
            {
                SurfaceData surfaceData = InitializeSurfaceData(IN);
                //return half4(surfaceData.albedo,1);
                
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
