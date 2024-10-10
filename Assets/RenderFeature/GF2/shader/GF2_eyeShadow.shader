Shader "Unlit/GF2_eyeShadow"
{
    Properties
    {
            _min("min",Range(0,10)) = 1
            _max("max",Range(0,10)) = 1
            _delt("delt",Range(0,10)) = 0.5
            _ViewDir("viewDir",Range(0,10)) = 1 
        
            _BaseColor("BaseColor",Color) = (1,1,1,1)
            _MainTex ("BaseTex", 2D) = "white" {}
            [NoScaleOffset]_PBRMask("BbrMask",2D) = "white" {}
            [NoScaleOffset]_Bump("Bump",2D) = "bump" {}
            [NoScaleOffset]_IlmMask("IlmMask",2D) = "white" {}
             [NoScaleOffset]_Ramp("Ramp",2D) = "white" {}

            [NoScaleOffset]_ILMMapSpecType  ("ILMMapSpecType", 2D)          		= "white" {}
            [NoScaleOffset]_ILMMapAO        ("ILMMapAO", 2D)                		= "white" {}
            [NoScaleOffset]_ILMMapSpecMask  ("ILMMapSpecMask", 2D)          		= "white" {}
            _bumpScale("bumpScale",Range(0,1)) = 0.5
        [Space(50)]

       
       
    


            _Metallic						("Metallic",Range(0,1)) 				= 0.5
            _Smoothness						("Smoothness",Range(0,1)) 				= 0.5
            _Occlusion						("Occlusion InDir",Range(0,1)) 				= 1
            _NdotVAdd						("NdotVAdd(Leather Reflect)",Range(0,2))= 0
        
        [Space(50)]
		// Direct LIght
		
            [HDR]_SelfLight					("SelfLight", Color) 					= (1,1,1,1)
            _MainLightColorLerp				("Unity Light or SelfLight", Range(0,1))= 0
            _DirectOcclusion				("DirectOcclusion",Range(0,1)) 			= 0.1
            
            [Title(Shadow)]
            _ShadowOffset       			("ShadowOffset",Range(-1,1))  			= 0.0
            _ShadowSmooth       			("ShadowSmooth", Range(0,1))  			= 0.0
            _ShadowStrength     			("ShadowStrength", Range(0,1))			= 1.0
			[Space(10)]
            _SecShadowColor     			("SecShadowColor (ILM AO)", Color)		= (0.5,0.5,0.5,1)
            _SecShadowStrength  			("SecShadowStrength", Range(0,1))		= 1.0

        [Space(50)]

		// Ramp

        _RampDirDiffY("RampDirectY",Range(0,1)) = 0.125
        _RampDirSpecY("RampDirSpecY",Range(0,1)) = 0.375
        
        [HideInInspector]_SHADOW_RAMP("_SHADOW_RAMP", float) = 0
            //[Ramp]_ShadowRampTex			("ShadowRampTex", 2D) 					= "white" { }
        [Space(50)]
		// Indirect Light
		
            [Title(Diffuse)]
            [HDR]_SelfEnvColor  			("SelfEnvColor", Color) 				= (0.5,0.5,0.5,0.5)
            _EnvColorLerp       			("Unity SH or SelfEnv", Range(0,1)) 	= 0.5
            _IndirDiffUpDirSH   			("IndirDiffUpDirSH", Range(0,1))		= 0.0
            _IndirDiffIntensity 			("IndirDiffIntensity", Range(0,1))		= 0.3
            [Title(Specular)]
            [Toggle(_INDIR_CUBEMAP_ON)] _INDIR_CUBEMAP ("自定义cubemap",int) = 0
            [NoScaleOffset]_IndirSpecCubemap("SpecCube", cube) 						= "_Skybox" {}
            [Toggle(_INDIR_MATCAP_ON)]_INDIR_MATCAP("自定义matcap", int) 			= 0
            _IndirSpecMatcap    			("Matcap", 2D) 							= "black" {}

            _IndirSpecMatcapTile			("MatcapTile", float)               	= 1.0
            _IndirSpecLerp      			("Unity Reflect or Self Map", Range(0,1))= 0.3
            _IndirSpecIntensity 			("IndirSpecIntensity", Range(0.01,10))	= 1.0

        [Space(50)]

		// Emission, Rim, etc.
       
            [HDR]_EmissionCol				("EmissionCol", color)         			= (1,1,1,1)

        

		// Outline
        
		// 描边强度
        _OutlinePower("line power",Range(0,0.2)) = 0.05
        // 描边颜色
        _LineColor("lineColor",Color)=(1,1,1,1)

        _OffsetFactor ("Offset Factor", Range(0,200)) = 0
        _OffsetUnits ("Offset Units", Range(0,200)) = 0
        

		// Other Settings
		[Space(10)]
        [Enum(UnityEngine.Rendering.CullMode)] 
        _Cull								("Cull Mode", Float) 					= 2
		_AlphaClip							("AlphaClip", Range(0, 1)) 	            = 1

        [KeywordEnum(None,mainTex_R,mainTex_G,mainTex_B,mainTex_A,UV,UV2,pbrMask_R,pbrMask_G,pbrMask_B)] _TestMode("_TestMode",Int) = 0

        [Toggle]_ShadowRamp("是否使用ramp",int) = 0

        [Space(50)]
        _reverseACESIntensity("reverseACESIntensity",Range(0,1)) = 0.5
        _DiffuseSmoothStep("漫反射平滑",Range(0,1)) = 0.1
        _DiffuseBias("半兰伯特偏移",Range(0,1)) = 0.1
        _specColor("头发高光",color) = (1,1,1,1)
        _SpecIntensity("头发强度",Range(0,1))= 0.5
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
                float3 normalVS:TEXCOORD8;
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


            CBUFFER_END
    
    ENDHLSL
    
    SubShader
    {
        LOD 100

        Pass
        {
        Tags {"Queue"="Transparent"  "RenderType"=" Transparent"  "RenderPipeline"="UniversalPipeline"  }
            Name "GF2_eyeShadow"
            Blend DstColor DstColor
            
			//Cull [_Cull]
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
                o.normalVS = normalize(TransformWorldToViewDir(o.worldNormal));
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


                half emission                 = 1 - mainTex.a;
                half metallic                 = lerp(0, _Metallic, pbrMask.r);;
                half smoothness               = lerp(0, _Smoothness, pbrMask.g);
                half occlusion                = lerp(1 - _Occlusion, 1, pbrMask.b);
                half directOcclusion          = lerp(1 - _DirectOcclusion, 1, pbrMask.b);
                
                half3 albedo = mainTex.rgb * _BaseColor.rgb;
               
                float halfLambert =  dot(worldNormal,worldLightDir) * 0.5 + 0.5;

                float2 matCapUV = i.normalVS.xy;
                matCapUV = matCapUV * 0.49 + 0.5;

                half3 matCapColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,matCapUV); 
                return half4(matCapColor,0.5);
            }
            ENDHLSL
        }   
    }
    FallBack "VertexLit"
}

