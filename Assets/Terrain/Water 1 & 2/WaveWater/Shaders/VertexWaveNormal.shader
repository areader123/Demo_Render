Shader "LSQ/Terrain/Water/VertexWaveNormal"
{
    Properties
    {
        [Header(Depth Gradient)]
        _DepthShallowColor("Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthDeepColor("Deep Color", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Maximum Distance", Float) = 1
        _EyeMaxDistance ("Eye Max Distance", float) = 100

        [Header(Foam)]
        _FoamColor("Color", Color) = (1,1,1,1)
        _FoamMaxDistance("Maximum Distance", Float) = 0.2
        _WaveTex("WaveTex", 2D) = "white"{}

        [Header(Vertex Waves #1)]
        _Wave1Direction ("Direction", Range(0, 1)) = 0
        _Wave1Amplitude ("Amplitude", float) = 1
        _Wave1Wavelength ("Wavelength", float) = 1
        _Wave1Speed ("Speed", float) = 1

        [Header(Vertex Waves #2)]
        _Wave2Direction ("Direction", Range(0, 1)) = 0
        _Wave2Amplitude ("Amplitude", float) = 1
        _Wave2Wavelength ("Wavelength", float) = 1
        _Wave2Speed ("Speed", float) = 1

        [Header(Light)]
        _Specular("Specular", Color) = (1,1,1,1)
        _BumpMap ("Normal Map", 2D) = "bump"{}
        _BumpScale ("Normal Scale", Float) = 1.0
        _Gloss("Gloss", Range(8, 256)) = 20
        _NormalDistortionScale("Normal Distortion Scale", Range(0, 1)) = 0.27

        [Header(Shadow Mapping)]
        _MaxShadowDistance("Maximum Sample Distance", float) = 50.0
        _ShadowColor ("Color", Color) = (0.5, 0.5, 0.5, 1.0)

        [Header(Distortion)]
        _SurfaceDistortion("Surface Distortion", 2D) = "black"{}

        [Header(Caustics)]
        _CausticsColor("Color", Color) = (1,1,1,1)
        _CausticsTex ("Texture", 2D) = "black"{}
        _CausticsScale ("Scale", float) = 1.0
        _CausticsDistortionScale ("Distortion Scale", Range(0.0, 1.0)) = 0.5

        [Header(Refract And Reflect)]
        _FresnelPower ("Fresnel Power", float) = 3
        _FresnelDensity ("Fresnel Density", float) = 3
        _ReflectPower("Reflect Power", float) = 2
        _ReflectDensity("Reflect Density", float) = 2
        _RefractDistortionNoise ("Refract Distortion Noise", 2D) = "black"{}
        _RefractDistortionScale ("Refract Distortion Scale", Range(0.0, 1.0)) = 0.1
        _RefractDensity("Refract Density", float) = 2

        [Header(Under Water)]
        _SunSpecularPower ("Power", float) = 80
        _SunSpecularDensity ("Specular", float) = 0.5
        _SunSpecularDistortionScale ("Distortion Scale", Range(0.0, 0.2)) = 0.01
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        //        GrabPass 
        //        { 
        //            "_Refraction" 
        //        }

        Pass
        {


            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 grabUV : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float2 uvCaustics : TEXCOORD4;
                float2 uvNormal : TEXCOORD5;
                float2 uvDistortion : TEXCOORD6;
                float2 uvRefractDistortion : TEXCOORD7;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _CameraOpaqueTexture;
            //  sampler2D _Refraction;

            //Depth Gradient
            float4 _DepthShallowColor;
            float4 _DepthDeepColor;
            float _DepthMaxDistance;
            float _EyeMaxDistance;

            //Foam
            float3 _FoamColor;
            float _FoamMaxDistance;
            sampler2D _WaveTex;

            //Light
            fixed3 _Specular;
            float _Gloss;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            //Shadows.            
            sampler2D _MainDirectionalShadowMap;
            float _MaxShadowDistance;
            float3 _ShadowColor;

            //Distortion
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float _NormalDistortionScale;

            //Refract & Reflection
            float _FresnelPower;
            float _FresnelDensity;
            float _ReflectPower;
            float _ReflectDensity;
            sampler2D _RefractDistortionNoise;
            float4 _RefractDistortionNoise_ST;
            float _RefractDensity;
            float _RefractDistortionScale;

            //Under Water
            float _SunSpecularPower;
            float _SunSpecularDensity;
            float _SunSpecularDistortionScale;

            //Caustics
            fixed3 _CausticsColor;
            sampler2D _CausticsTex;
            float4 _CausticsTex_ST;
            float _CausticsScale;
            float _CausticsDistortionScale;

            // Wave 1.
            float _Wave1Direction;
            float _Wave1Amplitude;
            float _Wave1Wavelength;
            float _Wave1Speed;

            // Wave 2.
            float _Wave2Direction;
            float _Wave2Amplitude;
            float _Wave2Wavelength;
            float _Wave2Speed;

            float SimpleWave(float2 position, float2 direction, float wavelength, float amplitude, float speed)
            {
                float x = UNITY_PI * dot(position, direction) / wavelength;
                float phase = speed * _Time.y;
                return amplitude * pow(sin(x + phase), 3);
                //return amplitude * (1 - abs(sin(x + phase)));
            }

            float GetWaveHeight(float2 worldPos)
            {
                float2 dir1 = float2(cos(UNITY_PI * _Wave1Direction), sin(UNITY_PI * _Wave1Direction));
                float2 dir2 = float2(cos(UNITY_PI * _Wave2Direction), sin(UNITY_PI * _Wave2Direction));
                float wave1 = SimpleWave(worldPos, dir1, _Wave1Wavelength, _Wave1Amplitude, _Wave1Speed);
                float wave2 = SimpleWave(worldPos, dir2, _Wave2Wavelength, _Wave2Amplitude, _Wave2Speed);
                return wave1 + wave2;
            }

            //法3：使用法线贴图时仅需要TBN矩阵即可
            float3x3 GetWaveTBN(float2 worldPos, float d)
            {
                float waveHeight = GetWaveHeight(worldPos);
                float waveHeightDX = GetWaveHeight(worldPos - float2(d, 0));
                float waveHeightDZ = GetWaveHeight(worldPos - float2(0, d));

                float3 tangent = normalize(float3(0, waveHeight - waveHeightDZ, d));
                float3 binormal = normalize(float3(d, waveHeight - waveHeightDX, 0));

                float3 normal = normalize(cross(tangent, binormal));
                return transpose(float3x3(tangent, binormal, normal));
            }

            // Returns the shadow-space coordinate for the given world-space position.
            float4 GetShadowCoordinate(float3 positionWS, float4 weights)
            {
                // Calculate the shadow coordinates for each cascade.
                float4 sc0 = mul(unity_WorldToShadow[0], float4(positionWS, 1));
                float4 sc1 = mul(unity_WorldToShadow[1], float4(positionWS, 1));
                float4 sc2 = mul(unity_WorldToShadow[2], float4(positionWS, 1));
                float4 sc3 = mul(unity_WorldToShadow[3], float4(positionWS, 1));

                // Get the final shadow coordinate by multiplying by the weights.
                return sc0 * weights.x + sc1 * weights.y + sc2 * weights.z + sc3 * weights.w;
            }

            float GetLightVisibility(sampler2D shadowMap, float3 positionWS, float maxDistance)
            {
                // Calculate the weights for each shadow cascade.
                float distFromCam = length(positionWS - _WorldSpaceCameraPos.xyz);

                // If we are beyond the edge of the shadow map, return 1.0 (no shadow).
                if (distFromCam > maxDistance)
                {
                    return 1.0;
                }

                // Otherwise, calculate the weights...
                float4 near = float4(distFromCam >= _LightSplitsNear);
                float4 far = float4(distFromCam < _LightSplitsFar);
                float4 cascadeWeights = near * far;

                // ...and the shadow coordinate.
                float4 shadowCoord = GetShadowCoordinate(positionWS, cascadeWeights);
                //shadowCoord /= shadowCoord.w;

                // Then sample the shadow map and return whether the point is in shadow or not.
                return tex2Dproj(shadowMap, shadowCoord) < shadowCoord.z / shadowCoord.w;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.uvCaustics = v.uv * _CausticsTex_ST.xy + _CausticsTex_ST.zw * _Time.y;
                o.uv = v.uv;
                o.uvNormal = v.uv * _BumpMap_ST.xy + _BumpMap_ST.zw * _Time.y;
                o.uvDistortion = v.uv * _SurfaceDistortion_ST.xy + _SurfaceDistortion_ST.zw * _Time.y;
                o.uvRefractDistortion = v.uv * _RefractDistortionNoise_ST.xy + _RefractDistortionNoise_ST.zw * _Time.y;

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float height = GetWaveHeight(o.worldPos.xz);
                o.worldPos.y += height;
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1));
                o.screenPos = ComputeScreenPos(o.vertex);
                o.grabUV = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i, float face : VFACE) : SV_Target
            {
                float2 distortNoise = tex2D(_SurfaceDistortion, i.uvDistortion).xy * 2 - 1;
                float depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                float dis01 = saturate(length(i.worldPos - _WorldSpaceCameraPos) / _EyeMaxDistance);

                //depth color gradient
                float depth = LinearEyeDepth(depth01);
                float depthOffset = depth - LinearEyeDepth(i.vertex.z); //i.screenPos.w
                float depthOffset01 = saturate(depthOffset / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthShallowColor, _DepthDeepColor, depthOffset01);

                //foam color
                float foamOffset01 = 1 - saturate(depthOffset / _FoamMaxDistance);
                float3 foamColor = foamOffset01 * _FoamColor.rgb;

                //Normal
                float2 normalUV = i.uvNormal + distortNoise * _NormalDistortionScale;
                float3x3 tangentToWorld = GetWaveTBN(i.worldPos.xz, 0.01);
                float3 normalTS = UnpackNormal(tex2D(_BumpMap, normalUV));
                normalTS.xy *= _BumpScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
                float3 normalWS = mul(tangentToWorld, normalize(normalTS));

                //Light
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(normalWS, lightDir));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normalWS, halfDir)), _Gloss);
                fixed3 lightColor = ambient + diffuse + specular;

                //Shadow
                float shadowMask = GetLightVisibility(_MainDirectionalShadowMap, i.worldPos, _MaxShadowDistance);
                float3 lightAndShadowColor = lerp(_ShadowColor, lightColor, shadowMask);

                //Caustics
                float2 causticsUV = i.uvCaustics + distortNoise * _CausticsDistortionScale;
                float3 causticsColor = tex2D(_CausticsTex, causticsUV) * _CausticsScale * _CausticsColor;

                //Reflect
                float3 reflectDir = reflect(viewDir, normalWS);
                float3 reflectColor = saturate(
                    pow(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir), _ReflectPower) * _ReflectDensity);
                //Refract
                float2 refractDistortion = tex2D(_RefractDistortionNoise, i.uvRefractDistortion).rg;
                //return fixed4(refractDistortion, 0, 1);
                i.grabUV.xy += refractDistortion * _RefractDistortionScale;
                fixed4 refractTex = tex2Dproj(_CameraOpaqueTexture, i.grabUV);
                fixed3 refractColor = refractTex.rgb * waterColor;
                //fresnel
                float fresnelMask = saturate(pow(1 - max(0, dot(viewDir, normalWS)), _FresnelPower) * _FresnelDensity);
                fixed3 fresnelColor = lerp(reflectColor * fresnelMask * dis01, refractColor * (1 - fresnelMask),
                    _RefractDensity);

                //Under Water
                float3 distortViewDir = viewDir + float3(distortNoise.x, 0, distortNoise.y) *
                    _SunSpecularDistortionScale;
                float underSpecular = pow(max(0, dot(-distortViewDir, _WorldSpaceLightPos0.xyz)), _SunSpecularPower) *
                    _SunSpecularDensity;
                fixed3 underSpecularColor = _LightColor0.rgb * underSpecular;
               
                //Final
                if (face > 0)
                {
                    return fixed4(waterColor.rgb * lightAndShadowColor + foamColor + causticsColor + fresnelColor, 1);
                }
                else
                {
                    return fixed4(waterColor.rgb * lightColor + foamColor + causticsColor + underSpecularColor, 1);
                }
            }
            ENDCG
        }
    }
}