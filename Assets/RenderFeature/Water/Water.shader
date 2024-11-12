Shader "Sea/Water"
{
    Properties
    {
        [HDR]_ShallowColor("Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
        [HDR]_DeepColor("Deep Color", Color) = (0.086, 0.407, 1, 0.749)
        
        _RingTex ("Ring Map", 2D) = "white" {}
        _NormalTex ("Normal Map", 2D) = "bump" {}
        _NormalScale("_NormalScale",float) = 1
        _Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
        _Distortion ("Distortion", Range(0, 100)) = 10
        _DepthMaxDistance("Depth Max Distance", Range(0,100)) = 1
        _FresnelPower ("Fresnel Power", Range(0, 100)) = 0
        _RingPower("Ring Power", Range( -10 , 10)) = 0

        // [Header("波形")]
        _Wave1Direction("_Wave1Direction",float) = 1
        _Wave1Wavelength(" _Wave1Wavelength",float) = 1
        _Wave1Amplitude("_Wave1Amplitude",float) = 1
        _Wave1Speed("_Wave1Speed",float) = 1
        _Wave2Direction("_Wave2Direction",float) = 1
        _Wave2Wavelength("_Wave2Wavelength",float) = 1
        _Wave2Amplitude("_Wave2Amplitude",float) = 1
        _Wave2Speed("_Wave2Speed",float) = 1

        
        _specPow("_specPow",float) = 1
        [HDR]_specColor("_specColor",Color)=(1,1,1,1)
        
        _specIntensity("_specIntensity",float) = 1
        _SSSDistortion("_SSSDistortion",float) = 1
        _SSSPower("_SSSPower",float) = 1
        _SSSScale(" _SSSScale",float) = 1
        [HDR]_SSSColor("_SSSColor",Color) = (0,0,0,1)
        
        _WaveControl("_WaveControl",float) = 0.5
        _NoiseScale("_NoiseScale",float) = 1
        _EdgeFoamNoise("_EdgeFoamNoise",2D) = "white" {}
        _EdgeFoamDepth("_EdgeFoamDepth",float) = 0
        _EdgeSpeed("_EdgeSpeed",float) = 0
        _EdgeAmount(" _EdgeAmount",float) = 0
        _EdgeFoamColor("_EdgeFoamColor",Color) = (1,1,1,1)
        
        _SurfaceDistortion(" _SurfaceDistortion",2D) = "white" {}
        _SurfaceDistortionAmount("_SurfaceDistortionAmount",float) = 1

        _FoamDirection("_FoamDirection",vector) = (0,0,0,0)
        _FoamNoiseMap("_FoamNoiseMap",2D) = "White"{}
        _FoamNoiseScale("_FoamNoiseScale",float) = 1
        [HDR]_FoamColor("_FoamColor",Color) = (1,1,1,1)

        _CausticsMap("_CausticsMap",2D) = "white" {}
        _CausticsNoiseMap("_CausticsNoiseMap",2D)= "white" {}
        _CausticsScale("_CausticsScale",float) = 1
        _CausticsSpeed(" _CausticsSpeed",float)=1
        _CausticsStrength("_CausticsStrength",float) = 1
        _CausticsRamp("_CausticsRamp",2D) = "white" {}
        _CausticsParallaxScale("_CausticsParallaxScale",float) = 0.5

        [HDR]_FarColor("_FarColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ZWrite On
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
             #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "Assets/RenderFeature/ShaderLibs/Node.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; 
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPosition : TEXCOORD5;
                float4 screenPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;  
                float4 TtoW1 : TEXCOORD3;  
                float4 TtoW2 : TEXCOORD4; 
            };
            sampler2D _RingTex;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            samplerCUBE _Cubemap;
            half _WaveXSpeed;
            half _WaveYSpeed;
            float _Distortion;
            float _FresnelPower;
            float _RingPower;
            sampler2D _CameraOpaqueTexture;
            float4 _CameraOpaqueTexture_TexelSize;

            half4 _ShallowColor;
            half4 _DeepColor;
            sampler2D _CameraDepthTexture;
            half _DepthMaxDistance;

            float _Wave1Direction;
            float _Wave1Wavelength;
            float _Wave1Amplitude;
            float _Wave1Speed;
            float _Wave2Direction;
            float _Wave2Wavelength;
            float _Wave2Amplitude;
            float _Wave2Speed;

            float _SSSDistortion;
            float _SSSPower;
            float _SSSScale;
            half4 _SSSColor;
            
            float _specIntensity;
            float _specPow;

            float _WaveControl;
            float _NoiseScale;
            float _EdgeFoamDepth;
            float _EdgeSpeed;
            float _EdgeAmount;
            half4 _EdgeFoamColor;
            sampler2D _EdgeFoamNoise;

            float _SurfaceDistortionAmount;
            sampler2D   _SurfaceDistortion;
            float4 _FoamDirection;

            sampler2D _FoamNoiseMap;
            float _FoamNoiseScale;
            half4 _FoamColor;

            sampler2D _CausticsMap;
            sampler2D _CausticsNoiseMap;
            float _CausticsScale;
            float _CausticsStrength;
            float  _CausticsSpeed;
            sampler2D _CausticsRamp;
            float _CausticsParallaxScale;

            half4 _FarColor;
            float _NormalScale;

            //sampler2D unity_SpecCube0;
            SAMPLER(sampler_unity_SpecCube0);

            float rand(float2 p){
                return frac(sin(dot(p ,float2(12.9898,78.233))) * 43758.5453);
            }

            float SimpleWave(float2 position, float2 direction, float wavelength, float amplitude, float speed)
            {
                float x = PI * dot(position, direction) / wavelength;
                float phase = speed * _Time.y;
                return amplitude * sin(x + phase);
                return amplitude * (1 - abs(sin(x + phase)));
            }

            float GetWaveHeight(float2 worldPosition)
            {
                float2 dir1 = float2(cos(PI * _Wave1Direction), sin(PI * _Wave1Direction));
                float2 dir2 = float2(cos(PI * _Wave2Direction), sin(PI * _Wave2Direction));
                float wave1 = SimpleWave(worldPosition, dir1, _Wave1Wavelength, _Wave1Amplitude, _Wave1Speed);
                float wave2 = SimpleWave(worldPosition, dir2, _Wave2Wavelength, _Wave2Amplitude, _Wave2Speed);
                return wave1 + wave2;
            }
            // Approximates the normal of the wave at the given world position. The d
            // parameter controls the "sharpness" of the normal.
            float3x3 GetWaveTBN(float2 worldPosition, float d)
            {
                float waveHeight = GetWaveHeight(worldPosition);
                float waveHeightDX = GetWaveHeight(worldPosition - float2(d, 0));
                float waveHeightDZ = GetWaveHeight(worldPosition - float2(0, d));
                
                // Calculate the partial derivatives in the Z and X directions, which
                // are the tangent and binormal vectors respectively.
                float3 tangent = normalize(float3(0, waveHeight - waveHeightDZ, d));
                float3 binormal = normalize(float3(d, waveHeight - waveHeightDX, 0));

                // Cross the results to get the normal vector, and return the TBN matrix.
                // Note that the TBN matrix is orthogonal, i.e. TBN^-1 = TBN^T.
                // We exploit this fact to speed up the inversion process.
                float3 normal = normalize(cross(binormal, tangent));
                return transpose(float3x3(tangent, binormal, normal));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _NormalTex);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
                worldPos.y += GetWaveHeight(worldPos.xz);
                o.worldPosition = worldPos; 

                o.pos = TransformWorldToHClip(worldPos);
                o.screenPos = ComputeScreenPos(o.pos);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);  
                float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);  
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                return o;
            }



            


            half4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy/i.screenPos.w;


                
                //屏幕深度
                half existingDepth01 = tex2D(_CameraDepthTexture, screenPos).r;
                half existingDepthLinear = LinearEyeDepth(existingDepth01,_ZBufferParams);
                half depthDifference = (existingDepthLinear - i.screenPos.w);
                //return existingDepthLinear - i.screenPos.w;

                // 深水和潜水颜色做插值
                half waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                //return waterDepthDifference01;
                float4 waterColor = lerp(_ShallowColor, _DeepColor, waterDepthDifference01);
                //return waterColor;

                float3 worldPos = i.worldPosition;
                float3 viewDir = normalize(GetWorldSpaceViewDir(worldPos));
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float2 speed = _Time.y * float2(_WaveXSpeed,_WaveYSpeed);

                //切线空间中得到法线
                float3 bump1 = UnpackNormal(tex2D(_NormalTex, i.uv.xy + speed)).rgb;
                float3 bump2 = UnpackNormal(tex2D(_NormalTex, i.uv.xy - speed)).rgb;
                float3 bump = BlendNormal(bump1 ,bump2) * _NormalScale;
                //return float4(bump,1);
                
                //计算切线空间中的偏移量 //避免失真？
                float2 offset = bump.xy * _Distortion * _CameraOpaqueTexture_TexelSize.xy ;
                i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
                float3 refrCol = tex2D(_CameraOpaqueTexture,i.screenPos.xy/i.screenPos.w).rgb * waterColor;

                //将法线转换为世界空间
                float3x3 tbn = GetWaveTBN(worldPos.xz, 0.1);
                bump = normalize(mul(tbn,bump));
               // bump = mul(float3x3(i.TtoW0.xyz,i.TtoW1.xyz,i.TtoW2.xyz),bump);
                //return float4(bump,1);
                
                //次表面散射
                float3 backLitDir = bump * _SSSDistortion + (_MainLightPosition.xyz - float3(0,i.worldPosition.y, 0));
                float backSSS = saturate(dot(viewDir, -backLitDir));
                float3 sssColor = _SSSColor * pow(backSSS, _SSSPower) * _SSSScale;


                sssColor =  SubsurfaceScattering(viewDir,lightDir,bump,_SSSDistortion,_SSSPower,_SSSScale) *_SSSColor;
                //return half4(sssColor,1);

                //泡沫
                float2 noiseUV = float2(i.uv.x + _Time.y * 0.03 , i.uv.y+ _Time.y * 0.03);
                float2 distortSample = (tex2D(_SurfaceDistortion,i.uv)* 2 - 1) * _SurfaceDistortionAmount;
                float2  samplerUV =  noiseUV + float2(distortSample.x,distortSample.y);
                half distortNoise = tex2D(_EdgeFoamNoise, worldPos.xz / _NoiseScale + samplerUV).r;
                float edgeFoamMask = smoothstep(0, _EdgeFoamDepth, waterDepthDifference01);
                edgeFoamMask = saturate(0.5+sin(( _Time.y * _EdgeSpeed) * PI * _EdgeAmount)) *(1-edgeFoamMask);
                float edgeFoam = smoothstep((1-edgeFoamMask)-0.05,(1-edgeFoamMask) + 0.05,distortNoise);
                float4 edgeFoamColor = lerp(0, _EdgeFoamColor, edgeFoam);
                //浪尖泡沫
                half foamNoise = tex2D(_FoamNoiseMap,worldPos.xz / _FoamNoiseScale + samplerUV).r;
                float foam = saturate(dot(float3(_FoamDirection.x, 0, _FoamDirection.y), bump)) * smoothstep(_FoamDirection.z, _FoamDirection.w, worldPos.y);
                foam *= foamNoise;
                half4 WavefoamColor = foam * _FoamColor;
                //foam仅为遮罩
                //此处可以有浪尖tex
               // return distortNoise;
                //return edgeFoam;
               //return saturate(0.5+sin(( _Time.y * _EdgeSpeed) * PI * _EdgeAmount));
               // return  WavefoamColor;

                //焦散
                float3 viewDirTS = TransformWorldToTangent(viewDir,tbn);
                float2 parallaxOffset = ParallaxOffset1Step(1-waterDepthDifference01, _CausticsParallaxScale, viewDirTS);


                float flowSpeed = _Time.x *  _CausticsSpeed;
                float speed1 = frac(flowSpeed);
                float speed2 = frac(flowSpeed +0.5);

                float4 flow = tex2D(_CausticsNoiseMap,i.uv);
                float2 flow_uv = -(flow.xy * 2 -1);

                float2 flow_uv1 = flow_uv * speed1 * _CausticsStrength;
                float2 flow_uv2 = flow_uv * speed2 * _CausticsStrength;

                flow_uv1 += ((i.uv + parallaxOffset) / _CausticsScale);
                flow_uv2 += ((i.uv + parallaxOffset) / _CausticsScale);

                half4 causticsColor1 = tex2D(_CausticsMap,flow_uv1);
                half4 causticsColor2 = tex2D(_CausticsMap,flow_uv2);

                float lerpValue = abs(speed1 * 2 -1);
                half4 causticsColor = lerp(causticsColor1,causticsColor2,lerpValue);

                //return causticsColor;
                //causticsColor = tex2D(_CausticsRamp,float2(causticsColor.r,0.5));
                //return causticsColor;


                // 波纹法线
                float4 ringColor = tex2D(_RingTex, screenPos);
                float3 ringNormal = UnpackNormal(ringColor).rgb;
                ringNormal = mul(float3x3(i.TtoW0.xyz,i.TtoW1.xyz,i.TtoW2.xyz),ringNormal);
                ringNormal = normalize(ringNormal) * ringColor.a * _RingPower;
                
                float3 normal = normalize(bump+ringNormal);

                float3 reflDir = reflect(-viewDir,normal);
                //reflDir = reflect(-viewDir,float3(0,0,1));
                float3 reflCol =  SAMPLE_TEXTURECUBE(unity_SpecCube0 ,sampler_unity_SpecCube0, float3(reflDir)).rgb ;
                //   return float4(reflCol,1);
                half fresnel = pow(1 - saturate(dot(viewDir,float3(0,1,0))),_FresnelPower);
                //return fresnel;

                //距离颜色


                float3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);

                finalColor = lerp(finalColor,_FarColor,fresnel);

                float3 spec = pow(max(dot(bump,viewDir),0),_specPow) * _specIntensity;
                //return half4(spec,1);
                finalColor += spec;
                finalColor += sssColor;
                finalColor += edgeFoamColor;
                finalColor +=  WavefoamColor;
                finalColor += causticsColor;
                //return foam;
                return float4(finalColor,1);
            }   
            ENDHLSL
        }


        Pass {
            Name "DepthOnly"
        
            Tags {
                "LightMode" = "DepthOnly"
            }
        
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
        
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            ENDHLSL
        }
    }
}
