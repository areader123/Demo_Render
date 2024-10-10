Shader "Unlit/GF2_eye"
{

    Properties
    {
           
        
            _BaseColor("BaseColor",Color) = (1,1,1,1)
            _MainTex ("BaseTex", 2D) = "white" {}
            [NoScaleOffset]_PBRMask("Matcap",2D) = "white" {}
            _lerp("_lerp",Range(0,1)) = 0.5

       
       
    


            

        [Space(50)]
        _reverseACESIntensity("reverseACESIntensity",Range(0,1)) = 0.5
        _DiffuseSmoothStep("漫反射平滑",Range(0,1)) = 0.1
        _DiffuseBias("半兰伯特偏移",Range(0,1)) = 0.1
        _specColor("头发高光",color) = (1,1,1,1)
        _SpecIntensity("头发强度",Range(0,1))= 0.5


        _Colorintensity("眼睛主光强度",Range(0,3)) = 1
        _AddColorIntensity("眼睛附加光强度",Range(0,3)) = 1
        _Alpha("眼睛透明度",Range(0,1)) = 1
    }

    HLSLINCLUDE
            //#pragma target 3.0

            #pragma shader_feature _SHADOW_RAMP_ON
            #pragma shader_feature _INDIR_CUBEMAP_ON
			#pragma shader_feature _INDIR_MATCAP_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

            #define UNITY_PI            3.14159265359f
            #define UNITY_HALF_MIN      6.103515625e-5


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                //float2 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPoint : TEXCOORD4;

                float3 worldTangent : TEXCOORD5;
                float3 worldBiTangent : TEXCOORD6;
                float3 shadowCoord : TEXCOORD7;
            };


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D(_Bump);
            SAMPLER(sampler_Bump);


            TEXTURE2D(_IlmMask);
            SAMPLER(sampler_IlmMask);


            TEXTURE2D(_PBRMask);
            SAMPLER(sampler_PBRMask);

            TEXTURE2D(_Ramp);
            SAMPLER(sampler_Ramp);

            TEXTURE2D(_ILMMapAO);
            SAMPLER(sampler_ILMMapAO);

            TEXTURE2D(_ILMMapSpecMask);
            SAMPLER(sampler_ILMMapSpecMask);

            TEXTURE2D(_ILMMapSpecType);
            SAMPLER(sampler_ILMMapSpecType);

            TEXTURE2D(_IndirSpecCubemap);
            SAMPLER(sampler_IndirSpecCubemap);
            
            SAMPLER(sampler_unity_SpecCube0);


            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _IndirSpecCubemap_HDR;
            half3	_BaseColor;
            float4	_BaseMap_ST;
			half	_bumpScale;
            float _RampDirDiffY;
            float _RampDirSpecY;

			// PBR Properties
			half	_Metallic;
			half	_Smoothness;
			half	_Occlusion;
			half	_NdotVAdd;

			// Direct Light
			half4	_SelfLight;
			half	_MainLightColorLerp;
			half	_DirectOcclusion;

			// Shadow
			
			float   _ShadowOffset;
			float   _ShadowSmooth;
			float   _ShadowStrength;
			half4 	_SecShadowColor;
			float   _SecShadowStrength;

			// Indirect
            half4	_SelfEnvColor;
            half	_EnvColorLerp;
			half	_IndirDiffUpDirSH;
			half	_IndirDiffIntensity;
			half	_IndirSpecLerp;
			half	_IndirSpecMatcapTile;
			half	_IndirSpecIntensity;

			// Emission
			half4	_EmissionCol;
            
            float _TestMode;
            float _max;
            float _min;
            float _delt;
            float _ViewDir;

            float4 _Color;
            //描边强度
            float _OutlinePower;
            //描边颜色
            float4 _LineColor;

            float _reverseACESIntensity;


            float _Colorintensity;
            float _AddColorIntensity;
            float _Alpha;


            float  _lerp;

            CBUFFER_END
    
    ENDHLSL
    
    SubShader
    {
        LOD 300

        Pass
        {
            Name "GF2_eyeadd"
            Tags { "RenderType"=" Transparent" "Queue"=" Transparent" "RenderPipeline"="UniversalPipeline" }
             Blend  One One
			
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
 
            
           // float4 _LightColor0;

           float3 reverseACES(float3 color)
            {
                return  3.4475 * color * color * color - 2.7866 * color * color + 1.2281 * color - 0.0056;
            }   

         



            v2f vert  (a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                
                o.worldPoint = TransformObjectToWorld(v.vertex);
                //o.uv0 = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
               // o.uv.zw = v.uv1;
                //o.uv0.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.xy = TRANSFORM_TEX(v.uv0,_MainTex);   
                o.worldNormal =  TransformObjectToWorldNormal(v.normal);
                o.worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.worldBiTangent = cross(o.worldNormal,o.worldTangent) * v.tangent.w;

                o.shadowCoord = TransformWorldToShadowCoord(o.worldPoint);
                //TRANSFER_SHADOW(o);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 uv0 = i.uv.xy;
               // float2 uv1 = i.uv.zw;
            
                float3x3 TBN = float3x3(i.worldTangent,i.worldBiTangent,i.worldNormal);
                half3 TSBump = UnpackNormalScale(SAMPLE_TEXTURE2D(_Bump,sampler_Bump,uv0),_bumpScale);
                
                //half3 WSBump = normalize(mul(TSBump,TBN));
                float3 worldNormal = normalize(mul(TSBump,TBN));
                
                Light light = GetMainLight();
                 //worldNormal = normalize(i.worldNormal);
                float3 worldLightDir = normalize(light.direction);
                float3 worldViewDir = normalize(GetWorldSpaceViewDir(i.worldPoint));
               // return half4(worldViewDir,1);
               // worldLightDir = i.worldViewDir;

                //half shadow = MainLightRealtimeShadow(i.shadowCoord);


               // fixed shadowAttenuation = SHADOW_ATTENUATION(i);
                float3 lightColor = light.color * light.shadowAttenuation;

                //float4 shadowCoords = TransformWorldToShadowCoord(i.worldPoint);

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv0);
                half4 pbrMask = SAMPLE_TEXTURE2D(_PBRMask,sampler_PBRMask,uv0);
              
                float3 reverseACESBaseColor = reverseACES(mainTex.rgb); 
                mainTex.rgb = lerp(mainTex.rgb,reverseACESBaseColor,_reverseACESIntensity);

                float ilmAO = SAMPLE_TEXTURE2D(_ILMMapAO,sampler_ILMMapAO,uv0).b;
                ilmAO = lerp(1 - _SecShadowStrength,1,ilmAO);
                float ilmSpecMask = SAMPLE_TEXTURE2D(_ILMMapSpecMask,sampler_ILMMapSpecMask,uv0).r;

                float3 H = normalize(worldLightDir + worldViewDir);
                float NdotV = saturate(dot(worldNormal,worldViewDir));
                float NdotL = saturate(dot(worldNormal,worldLightDir));
                float NdotH = saturate(dot(worldNormal,H));
                float HdotV = saturate(dot(H,worldViewDir));
                float LdotH = saturate(dot(worldLightDir,H));

               // return half4(H,1);


     
                 float3 NormalBlend_MatcapUV_Detail = mul( UNITY_MATRIX_V,worldNormal) * float3(-1,-1,1);
                float3 NormalBlend_MatcapUV_Base = (mul(UNITY_MATRIX_V,float4(worldViewDir,0))).rgb;
                float3 noSknewViewNormal = NormalBlend_MatcapUV_Base*dot(NormalBlend_MatcapUV_Base, NormalBlend_MatcapUV_Detail)/NormalBlend_MatcapUV_Base.b - NormalBlend_MatcapUV_Detail;                
                float2 ViewNormalAsMatCapUV = (noSknewViewNormal.rg * 0.5 + 0.5); 

                //return half4(NormalBlend_MatcapUV_Detail,1);
                
                float3 MatCap = SAMPLE_TEXTURE2D(_PBRMask,sampler_PBRMask,ViewNormalAsMatCapUV).xyz;
                half3 albedo = mainTex.rgb * _BaseColor.rgb;

                half3 Final = lerp(albedo,MatCap,_lerp);

               
                float halfLambert =  dot(worldNormal,worldLightDir) * 0.5 + 0.5;



                int pixelLightCount = GetAdditionalLightsCount();
                float3 finalAdditionalLightingColor = float3(0,0,0);
                float3 finalAddRimColor =    float3(0,0,0);
                float addatten = 0;
                for ( int lightIndex = 0 ; lightIndex<pixelLightCount ; lightIndex++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex , i.worldPoint);
                    finalAddRimColor += additionalLight.color*_AddColorIntensity;
                    addatten+=additionalLight.distanceAttenuation;
                }


                float3 finalcolor = lerp(Final.rgb*_Colorintensity,Final.rgb*_AddColorIntensity*finalAddRimColor,saturate(addatten));

                return  half4(finalcolor,saturate(mainTex.a * _Alpha));  


            }
            ENDHLSL

        }
        
        
    }
    FallBack "VertexLit"
}

