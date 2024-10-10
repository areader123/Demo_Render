Shader "Unlit/GF2_Face"
{
       Properties
    {
            _min("min",Range(0,10)) = 1
            _max("max",Range(0,10)) = 1
            _delt("delt",Range(0,10)) = 0.5
            _ViewDir("viewDir",Range(0,10)) = 1 
        
            _BaseColor("BaseColor",Color) = (1,1,1,1)
            _MainTex ("BaseTex", 2D) = "white" {}
            _FaceMap("FaceMap",2D) = "white" {}
            _PBRMask("BbrMask",2D) = "white" {}
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
        _facePow("脸部偏移",Range(0,2)) = 0.55
        _noseHighLightStepValue("鼻尖高光",Range(0,1)) = 0.1
        _DiffuseSmoothStep("脸部过渡",Range(0,1)) = 0.1
        _Strength("脸部强度",Range(0,3)) = 0.5
        _NoseSpecColor("鼻尖高光颜色",Color) = (1,1,1,1)
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
                float2 uv3 : TEXCOORD8;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPoint : TEXCOORD4;

                float3 worldTangent : TEXCOORD5;
                float3 worldBiTangent : TEXCOORD6;
                float4 shadowCoord : TEXCOORD7;
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

            TEXTURE2D(_FaceMap);
            SAMPLER(sampler_FaceMap);


            CBUFFER_START(UnityPerMaterial)
            float4 _PBRMask_ST;
            float4 _MainTex_ST;
            float4 _FaceMap_ST;
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

            float _facePow;
            float _noseHighLightStepValue;
            float _DiffuseSmoothStep;
            float _Strength;
            half4 _NoseSpecColor;

            CBUFFER_END
    
    ENDHLSL
    
    SubShader
    {
        LOD 300

        Pass
        {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"  "LightMode" =  "UniversalForward"  }
            Name "GF2_Face"
            ZWrite On
			Cull [_Cull]
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

            inline half2 Pow5 (half2 x)
            {
                return x*x * x*x * x;
            }
            
            float sigmoid(float x, float center, float sharp) {
                float s;
                s = 1 / (1 + pow(100000, (-3 * sharp * (x - center))));
                return s;
            };

            float3 DisneyDiffuse(half NdotV, half NdotL, half LdotH, half roughness, half3 baseColor)
            {
                half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
                // Two schlick fresnel term
                half lightScatter = (1 + (fd90 - 1) * Pow5(1 - NdotL));
                half viewScatter = (1 + (fd90 - 1) * Pow5(1 - NdotV));
                return baseColor * (lightScatter * viewScatter);

                // 加入了粗糙度 入射光线和法线夹角 视线和法线夹角 的 因素 对反射率的影响
                // 公式为菲涅尔公式 计算的是 反射率
                // 1 为光线沿法线射入时的 反射颜色 此处为漫反射 
            }

             float D_GGX_TR(float NdotH, float roughness)
            {
                float a2 = roughness * roughness;
                float NdotH2 = NdotH * NdotH;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = UNITY_PI * denom * denom;
                denom = max(denom, 0.0000001); //防止分母为0
                return a2 / denom;
            }

            float3 F_FrenelSchlick(float HdotV, float3 F0)
            {
                return  F0 + (1 - F0) * exp2((-5.55473 * HdotV - 6.98316 ) * HdotV);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float a = (roughness + 1.0) / 2;
                float k = a * a / 4;
                float nom = NdotV;
                float denom = NdotV * (1.0 - k) + k;
                denom = max(denom, 0.0000001); //防止分母为0
                return nom / denom;
            }

            float G_GeometrySmith(float NdotV, float NdotL, float roughness)
            {
                NdotV = max(NdotV, 0.0);
                NdotL = max(NdotL, 0.0);
                float ggx1 = GeometrySchlickGGX(NdotV, roughness);
                float ggx2 = GeometrySchlickGGX(NdotL, roughness);
                return ggx1 * ggx2;
            }
            
            float3 F_fresnelSchlickIndirect(float NdotV , float3 F0 , float roughness)
            {
                float3 F = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + F * saturate(1 - roughness - F0); 
            }

            float2 EnvBRDFApprox(float Roughness, float NoV)
            {
                // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
                // Adaptation to fit our G term.
                const float4 c0 = {
                    - 1, -0.0275, -0.572, 0.022
                };
                const float4 c1 = {
                    1, 0.0425, 1.04, -0.04
                };
                float4 r = Roughness * c0 + c1;
                float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
                float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
                return AB;
            }


            
             float fresnelReflectance( float3 H, float3 V, float F0 ) {   
                        float base = 1.0 - dot( V, H );   
                        float exponential = pow( base, 5.0 );   
                        return exponential + F0 * ( 1.0 - exponential ); 
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
                o.uv3 = TRANSFORM_TEX(v.uv0,_FaceMap);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 uv0 = i.uv.xy;
                float2 uv3 = i.uv3;
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

                half shadow = MainLightRealtimeShadow(i.shadowCoord);
                
                //return half4(shadow,shadow,shadow,1);

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

                

               

                // float2 forwardWS =normalize(TransformObjectToWorld(float3(0,0,-1)).xz);
                // float2 rightDirWS = normalize(TransformObjectToWorld(float3(-1,0,0)).xz);

                // float  RdotL   =  dot(rightDirWS,worldLightDir.xz);
                // float2 FaceUV  =  saturate(RdotL) >0.00001? float2(1-uv3.x,uv3.y) : uv3;
                // float3 faceMap =SAMPLE_TEXTURE2D(_FaceMap, sampler_FaceMap, FaceUV).rgb;
                // faceMap.r = pow(abs(faceMap.r),_facePow);
                // float  WdotL   =  1-clamp(0,1,dot(forwardWS,worldLightDir.xz)*0.5+0.5);
                // float  shadow1 = WdotL<faceMap.r ? 1.0: 0.0 ;


                // float shadow3 = WdotL + _noseHighLightStepValue < faceMap.b ? 1 : 0 ;
                
                float3 forwardWS =normalize(TransformObjectToWorld(float3(0,0,1)));
                float3 rightDirWS = normalize(TransformObjectToWorld(float3(-1,0,0)));
                float3 UpDirWS = normalize(cross(rightDirWS,forwardWS));

                float3 temp = float3(dot(UpDirWS.x , worldLightDir.x),dot(UpDirWS.y , worldLightDir.y),dot(UpDirWS.z , worldLightDir.z));
                float3 temp2 = worldLightDir -  temp;




                float  RdotL   =  dot(rightDirWS,temp2);
                float2 FaceUV  =  saturate(RdotL) > 0? uv3 :float2(-uv3.x,uv3.y) ;
                float3 faceMap =SAMPLE_TEXTURE2D(_FaceMap, sampler_FaceMap, FaceUV).rgb;
                faceMap.r = faceMap.r ;
               // return faceMap.r;
                float  WdotL   =  smoothstep((1-(dot(forwardWS,temp2)*0.5+0.5)) - _DiffuseSmoothStep , (1-(dot(forwardWS,temp2)*0.5+0.5)) + _DiffuseSmoothStep,faceMap.r);
                
                float shadow3 = WdotL + _noseHighLightStepValue < faceMap.b ? 1 : 0 ;

               // return half4(WdotL,WdotL,WdotL,1);


                







               //return shadow3;
                
                //float shadowArea = sigmoid(1-shadow1,_ShadowOffset,_ShadowSmooth * 10) * _ShadowStrength;
                // ! 此处亮面为暗（0）
                //return shadowArea;
                //float shadowArea = smoothstep(1-halfLambert,1, _ShadowOffset) * _ShadowStrength;
                // 如果要用smooth shadowRamp 要用 1-shadowArea 且smooth的效果很差
                // !此处为反向插值
                //half3 shadowRamp = lerp(1,_ShadowColor,shadowArea);
                
                //#if defined(_SHADOW_RAMP_ON)
                    //shadowRamp = tex2D(_Ramp, shadowArea);
                
               // float  diffuse =  smoothstep(0,_DiffuseSmoothStep,abs(WdotL-faceMap.r))*WdotL;
               float diffuse =  WdotL * shadow3;//这个shadow是投影
                float NdotLRemap = 1 - diffuse;
            

               half3 shadowRamp = SAMPLE_TEXTURE2D(_Ramp,sampler_Ramp,float2(WdotL,_RampDirDiffY)) * _Strength;

               //return half4(shadowRamp,1);

                int mode = 1;
                if(_TestMode == mode++)
                return mainTex.r;
                if(_TestMode ==mode++)
                return mainTex.g; //阴影 Mask
                if(_TestMode ==mode++)
                return mainTex.b; //漫反射 Mask
                if(_TestMode ==mode++)
                return mainTex.a; //漫反射 Mask
                if(_TestMode ==mode++)
                return float4(uv0,0,0); //uv
                // if(_TestMode ==mode++)
                // return float4(uv1,0,0); //uv2
                //if(_TestMode ==mode++)
                //return vertexColor.xyzz; //vertexColor
                if(_TestMode ==mode++)
                return pbrMask.r; //BaseColor
                if(_TestMode ==mode++)
                return pbrMask.g; //BaseColor.a
                if(_TestMode ==mode++)
                return pbrMask.b;
                if(_TestMode ==mode++)
                return pbrMask.a;

                //Direct
                float perceptualRoughness = 1 - smoothness;
                float roughness = perceptualRoughness * perceptualRoughness;
                float roughnessSquare = max(roughness * roughness, UNITY_HALF_MIN);

                float3 F0 = lerp(0.04 , albedo,metallic);

                float NDF =  D_GGX_TR(NdotH,roughness);
                float G = G_GeometrySmith(NdotV,NdotL,roughness);
                float3 F = fresnelReflectance(H,worldViewDir,F0);

                NDF = NDF * ilmSpecMask;

                //return NDF;

                float3 ks = F;

                float3 kd = ((1 - F) * 0.5 + 0.5) * (1.0 - metallic);

                float3 nom = NDF * G * F;
                float3 denom = 4.0 * NdotV * NdotLRemap + 0.00001;
                float3 BRDFSpec =  nom/denom;

                //float3 BRDFDiff = DisneyDiffuse(NdotV,NdotL,LdotH,perceptualRoughness,albedo);
               


                float3 directDiffColor = kd * albedo;

                float3 directSpecColor = BRDFSpec * UNITY_PI;

               // return half4(albedo,1)

            //#if _SHADOW_RAMP_ON
                //ramp图 参与 pbr
                float specRange =  saturate(NDF * G / denom.x);
                half4 specRampCol = SAMPLE_TEXTURE2D(_Ramp,sampler_Ramp,float2(specRange,_RampDirSpecY));
                directSpecColor = clamp(specRampCol.rgb * 3 + BRDFSpec * UNITY_PI / F,_min,_max) * F * shadowRamp;
                //directSpecColor = smoothstep(directSpecColor,,);
                //return specRampCol;
            //#endif
                // NdotLRemap 为亮面遮罩 （亮面为1） shadowRamp 为 暗面遮罩(暗面为1)
                float3 directLightResult = (directDiffColor * (shadowRamp)  + directSpecColor * (NdotLRemap))
                                        * lightColor;

          

            // indirect 非直接光
            //漫反射
                float3 ks_indirect = F_fresnelSchlickIndirect(NdotV,F0,roughness);
                float3 kd_indirect = 1.0 - ks_indirect;
                kd_indirect *= (1-metallic);

                float3 SHColor = SampleSH(worldNormal);
               
                float3 envColor = lerp(SHColor, _SelfEnvColor.rgb , _SelfEnvColor.a);

                float3 diffuseIndirect = envColor * kd_indirect * albedo * occlusion;

            //如果存在lightmap subtract
             //half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, uv_lightmap);
                   // diffuseIndirect = DecodeLightmap(bakedColorTex) * albedo;
                   // diffuseIndirect = kd_indirect * SubtractMainLightWithRealtimeAttenuationFromLightmap(diffuseIndirect, shadowAttenuation, bakedColorTex, worldNormal);

            //镜面反射 此处使用pbr的标准
            //1.预计算cubemap 或 catmap
                //此处为反射探针
                //原文使用  GlossyEnvironmentReflection 来计算反射探针
                float3 additionalIndirSpec = 0;
                float3 reflectDirWS = reflect(-worldViewDir,worldNormal);
                roughness = roughness * (1.7 - 0.7 * roughness);
                half mip = roughness * 6;
                float4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_unity_SpecCube0,reflectDirWS,mip);
                float3 indirSpecColorRefl = DecodeHDREnvironment(rgbm,unity_SpecCube0_HDR);
            //2.数据拟合方式计算
                float2 envBRDF = EnvBRDFApprox(roughness,NdotV);

            #if defined(_INDIR_CUBEMAP_ON)
                    rgbm = SAMPLE_TEXTURECUBE_LOD(_IndirSpecCubemap,sampler_IndirSpecCubemap,reflectDirWS,mip);    
                    additionalIndirSpec = DecodeHDREnvironment(rgbm,_IndirSpecCubemap_HDR);
            #elif defined(_INDIR_MATCAP_ON)
                    float3 viewNormal = SafeNormalize(mul(UNITY_MATRIX_V , worldNormal));
                    float2 matcapUV = (viewNormal.xy * _IndirSpecMatcapTile) * 0.5 + 0.5;
                    additionalIndirSpec = SAMPLE_TEXTURE2D(_IndirSpecMatcap,sampler_IndirSpecMatcap,matcapUV);
            #endif
                
                float3 additionalIndirSpecMix = lerp(indirSpecColorRefl,additionalIndirSpec,_IndirSpecLerp);
                    



                float3 specularIndirect = additionalIndirSpecMix * (ks_indirect * envBRDF.x + envBRDF.y);

                float3 indirectLightResult  = (specularIndirect * _IndirSpecIntensity + diffuseIndirect * _IndirDiffIntensity); 

                half3 emissionResult = emission * albedo * _EmissionCol.rgb * _EmissionCol.a;
                half3 lightingResult = directLightResult + indirectLightResult + emissionResult;



                //return half4(additionalIndirSpecMix,1);
                //return half4(indirSpecColorRefl,1);
                //return half4(specularIndirect,1);
                //return half4(diffuseIndirect,1);
                //return shadow3;
                return half4((lightingResult * _Strength + shadow3 * _NoseSpecColor),1);

                //return mainTex;
                //return shadowAttenuation;
                //return metallic;
                //return half4 (F,1);
                //return half4 (kd,1);
                //return half4(BRDFDiff * kd  ,1);
                //return ilmAO;
                //return half4 (directDiffColor * shadowRamp ,1);
                //return half4 (directDiffColor ,1);
                //return half4(worldViewDir,1);
                //return half4(worldLightDir,1);
                //return half4(worldNormal,1);
                //return half4(H,1);
                //return NdotH;
                //return half4(kd,1);
               // return half4(BRDFDiff,1);
               // return half4(F0,1);
                //return half4(shadowRamp,1);
               //return shadowArea;
               //return NdotLRemap;
               //return half4(shadowRamp,1);
               //return half4(directSpecColor / shadowRamp,1);
                //return half4(directSpecColor,1);
                //return half4((directDiffColor * shadowRamp ),1);
                //return half4(directLightResult,1);
            }
            ENDHLSL

        }
    }
    FallBack "VertexLit"
}
