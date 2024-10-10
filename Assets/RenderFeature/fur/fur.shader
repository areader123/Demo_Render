Shader "Unlit/fur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise",2D) = "white" {}
        _NormalTex("NormalMap",2D) = "Normal" {}
        _AoMap("AoMap",2D) = "white" {}
        _UVoffset ("UV偏移:XY=UV偏移;ZW=UV扰动", Vector) = (0, 0, 0.2, 0.2)
        _FUR_OFFSET("pass层数",float) = 0.5
        _NoiseUV("NoiseUV",vector) = (1,1,0,0)
        _Color("Color",Color) = (1,1,1,1)
        _FurLength("FurLength",Range(0,10)) =1
        _clip("Clip",Range(0,1)) = 0.5
        _Gravity("Gravity", Vector) = (0,-1,0)
        _GravityStrength("重力强度",Range(0,1)) = 0.1 


        [Space(30)]
        _Roughness("roughness",Range(0,1)) = 1
        _Metalic("metalic",Range(0,1)) = 1
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)

        _FabricScatterColor("FabricScatterColor",Color) = (1,1,1,1)
        _FabricScatterScale("FabricScatterScale",Range(0,1)) = 0.01
    }
    SubShader
    {
        Tags {  "RenderType"=" Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "LightMode" = "fur"}
        pass{
            Name"Fur"
           Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            //#include"UnityCG.cginc"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };
            struct Varyings{
                float3 normalWS : TEXCOORD2;
                float3 posWS : TEXCOORD1;
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;

            };
            TEXTURE2D(_AoMap);
            SAMPLER(sampler_AoMap);
            
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            SAMPLER(sampler_unity_SpecCube0);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            float4 _UVoffset;
            float _FUR_OFFSET;
            float4 _NoiseUV;
            half4 _Color;
            float _FurLength;
            float _clip;
            float3 _Gravity;
            float _GravityStrength;
            float _Roughness;
            float _Metalic;
            half4 _SpecularColor;
            half4 _FabricScatterColor;
            float _FabricScatterScale;
            CBUFFER_END


            inline half2 Pow5 (half2 x)
            {
                return x*x * x*x * x;
            }

            inline float FabricD (float NdotH, float roughness)
            {
                return 0.96 * pow(1 - NdotH, 2) + 0.057;
            }

            inline half FabricScatterFresnelLerp(half nv, half scale)
            {
                half t0 = Pow4 (1 - nv);
                half t1 = 0.4 * (1 - nv);
                return (t1 - t0) * scale + t0; 
            }

            float3 F_FrenelSchlick(float HdotV, float3 F0)
            {
                return F0 + (1 - F0) * pow(1 - HdotV, 4.0);
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

            float3 FresnelSchlickRoughness(float NdotV, float3 F0, float roughness)
            {
                float3 oneMinusRoughness = 1.0 - roughness;
                return F0 + (max(oneMinusRoughness, F0) - F0) * pow(1.0 - NdotV, 5.0);
            }

            inline half PerceptualRoughnessToMipmapLevel(half perceptualRoughness, int maxMipLevel)
            {
                perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
                return perceptualRoughness * maxMipLevel;
            }
            inline half PerceptualRoughnessToMipmapLevel(half perceptualRoughness)
            {
                return PerceptualRoughnessToMipmapLevel(perceptualRoughness, UNITY_SPECCUBE_LOD_STEPS);
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
            




            Varyings vert(Attributes v){
                Varyings o;
                //顶点法线外扩
                float3 aNormal = (v.normalOS.xyz);
                aNormal.xyz += _FUR_OFFSET;
                //float3 n = aNormal * _FUR_OFFSET * _FUR_OFFSET;
                float3 n = aNormal*_FUR_OFFSET;
                float3 Gravity = TransformObjectToWorldDir(float3(0,-1,0));
                float3 direction = Gravity * _GravityStrength + n*(1-_GravityStrength);
                n = normalize(lerp(n, direction , _FUR_OFFSET));
                v.positionOS.xyz += n * _FurLength * _FUR_OFFSET;
                //uv偏移
                float2 uvOffset =_UVoffset.xy * _FUR_OFFSET;
                uvOffset *= 0.1;
                float2 uv1 = TRANSFORM_TEX(v.texcoord.xy,_MainTex)+ uvOffset*(float2(1,1)/_NoiseUV.xy);
                float2 uv2 = TRANSFORM_TEX(v.texcoord.xy,_MainTex) * _NoiseUV.xy + uvOffset;
                o.uv = float4(uv1,uv2);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.posWS = mul(unity_ObjectToWorld,v.positionOS);
                o.pos = TransformObjectToHClip(v.positionOS);
                return o;
            }

            half4 frag(Varyings i):SV_Target{
                half4 Color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                half3 NoiseTex = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv.zw).xyz;
                float AoMap = SAMPLE_TEXTURE2D(_AoMap,sampler_AoMap,i.uv.xy).r;

    
                
                 float3 V = normalize(GetWorldSpaceViewDir(i.posWS));
                Light light = GetMainLight();
                
                float3 L = normalize(light.direction);
                float3 H = (L + V);
                float3 N = normalize(i.normalWS);
                float NdotV = max(dot(N,V),0);
                float NdotH = max(dot(N,H),0);
                float NdotL = max(dot(N,L),0); 
                float HdotV = max(dot(H, V), 0);
                float LdotH = max(dot(L, H), 0);
                float perceptualRoughness = RoughnessToPerceptualRoughness(_Roughness);

                float3 F0 = lerp(0.04, Color, _Metalic);

                float F = F_FrenelSchlick(HdotV,F0);    
                float D =FabricD(NdotH,_Roughness);
                float G = G_GeometrySmith(NdotV,NdotL,_Roughness);

                float3 DGF = D * G * F;
                float denominator = 4.0 * NdotL * NdotV + 0.00001;
                float3 specularBRDF = DGF / denominator * _SpecularColor;
                
                float3 diffuseBRDF = DisneyDiffuse(NdotV, NdotL, LdotH, perceptualRoughness,Color) * NdotL;


                float3 ks = F;
                float3 kd = 1.0 - ks;
                kd *= (1 - _Metalic);
                float3 directLight = (diffuseBRDF * kd + specularBRDF) * NdotL * light.color;

                float3 oneMinusRoughness = 1.0 - _Roughness;
                float3 ks_indirect = F0 + (max(oneMinusRoughness, F0) - F0) * pow(1.0 - NdotV, 5.0);
                float3 kd_indirect = 1.0 - ks_indirect;
                kd_indirect *= (1 - _Metalic);

                 float3 diffuseIndirect = 0;
                 float3 irradianceSH = SampleSH(N);
                 diffuseIndirect = kd_indirect * irradianceSH * Color;

                float3 R = reflect(-V, N);


                float mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
                float3 prefilteredColor = 0;


                half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_unity_SpecCube0 ,R, mip);
                    //unity_SpecCube0_HDR储存的是 最近的ReflectionProbe
                prefilteredColor = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);

                 float2 envBRDF = EnvBRDFApprox(_Roughness, NdotV);


                float3 specularIndirect = prefilteredColor * (ks_indirect * envBRDF.x + envBRDF.y);

                float3 indirectLight = (diffuseIndirect + specularIndirect);


                Color.xyz = directLight + indirectLight
                + _FabricScatterColor * (NdotL * 0.5 + 0.5) * FabricScatterFresnelLerp(NdotV,_FabricScatterScale);



                half Alpha = NoiseTex.r;
                Color.xyz = lerp(Color.xyz,_Color.xyz,_FUR_OFFSET);
                Color.xyz = lerp(_Color.xyz,Color.xyz,AoMap);
                Alpha = step(_FUR_OFFSET,Alpha);
                Alpha = step(_FUR_OFFSET * _FUR_OFFSET , Alpha);
                Color.a = 1- _FUR_OFFSET;
                Color.a *= Alpha;
                clip(Alpha-0.01);
               // Color.a = step(Noise,_FUR_OFFSET);
                //return Alpha;
                return Color;
                //return half4(1,1,1,1);
            }

            ENDHLSL

        }

      
    }
}
