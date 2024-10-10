Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        _Wind ("Wind(x,y,z,str)", Vector) = (1, 0, 0, 10)
        _NoiseMap ("WaveNoiseMap", 2D) = "white" { }
        [PowerSlider(3.0)]_WindNoiseStrength ("WindNoiseStr", Range(0, 20)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        Pass
        {
            name "grass"
            ZWrite On
            ZTest On
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
           #pragma multi_compile_instancing

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                        struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 worldPosition : TEXCOORD2;
               float4 shadowCoord : TEXCOORD3;
            };

            struct GrassInfo
            {
                float4x4 localToWorld;
                float4 texParams;
            };
            StructuredBuffer<GrassInfo> _GrassInfoBuffer;


            float2 _GrassQuadSize;
            float4x4 _TerrianLocalToWorld;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Cutoff;
            float3 _Color;

            float4 _Wind;
            float _WindNoiseStrength;
            sampler2D _NoiseMap;

            // 交互对象坐标和范围（w）
            float4 _PlayerPos;
            // 下压强度
            float _PushStrength;

            float4 _LightColor0;
            
            ///计算被风影响后的世界坐标
            ///positionWS - 施加风力前的世界坐标
            ///grassUpWS - 草的生长方向，单位向量，世界坐标系
            ///windDir - 是风的方向，单位向量，世界坐标系
            ///windStrength - 风力强度,范围0-1
            ///vertexLocalHeight - 顶点在草面片空间中的高度
            /// 
            /// 
            float3 applyWind(float3 positionWS, float3 grassUpWS, float3 windDir, float windStrength, float vertexLocalHeight)
            {
                //根据风力，计算草弯曲角度，从0到90度
                float rad = radians(-windStrength);
                //得到wind与grassUpWS的正交向量
                windDir = windDir - dot(windDir, grassUpWS);

                float x, y;  //弯曲后,x为单位球在wind方向计量，y为grassUp方向计量
                sincos(rad, x, y);

                //offset表示grassUpWS这个位置的顶点，在风力作用下，会偏移到windedPos位置
                float3 windedPos = x * windDir + y * grassUpWS;

                vertexLocalHeight += 0.5 * _GrassQuadSize.y;
                //加上世界偏移
                return positionWS + (windedPos - grassUpWS) * vertexLocalHeight;
            }
            v2f vert (appdata v,uint instanceID : SV_INSTANCEID)
            {
                v2f o;
                float2 uv = v.uv;
                float4 positionOS = v.vertex;
                float3 normalOS = v.normal;
                positionOS.xy = positionOS.xy * _GrassQuadSize;

                GrassInfo grassInfo = _GrassInfoBuffer[instanceID];
                uv = uv * grassInfo.texParams.xy + grassInfo.texParams.zw;

                float4 positionWS = mul(grassInfo.localToWorld,positionOS);
                positionWS /= positionWS.w;//?
                //风
                float3 grassUpDir = float3(0,1,0);
                float3 windDir = normalize(_Wind.xyz);
                //风的强度
                float windStrength = _Wind.w;
                float localVertexHeight = positionOS.y;
                grassUpDir = mul(grassInfo.localToWorld, float4(grassUpDir,0)).xyz;


                //随机噪声
                float time = _Time.y;
                float2 noiseUV = (positionWS.xz - time)/30;
                float noiseValue = tex2Dlod(_NoiseMap,float4(noiseUV,0,0)).r;
                //sin函数随机摆动 变化的是noiseValue windStrength越大 sin变化越快
                noiseValue = sin(noiseValue * windStrength);
                //将扰动再加到风力上,_WindNoiseStrength为扰动幅度，通过材质球配置
                windStrength += noiseValue * _WindNoiseStrength;

                //与玩家交互
                float3 offsetDir = normalize(_PlayerPos.xyz - positionWS.xyz);
                float dis = distance(positionWS.xyz,_PlayerPos.xyz);
                float radius = _PlayerPos.w;
                //下压 将 下压 添加到 风
                float isPushRange = smoothstep(dis,dis + 0.8,radius);
                windDir.xz = offsetDir.xz * isPushRange + windDir.xz * (1 - isPushRange);
                windStrength += _PushStrength * isPushRange;

                positionWS.xyz =  positionWS.xyz = applyWind(positionWS.xyz, grassUpDir, windDir, windStrength, localVertexHeight);
                
                //输出到片段着色器
                o.uv = uv;
                o.worldPosition = positionWS;
                // o.worldNormal = isPushRange;
                o.worldNormal = mul(grassInfo.localToWorld, float4(normalOS, 0)).xyz;
                o.pos = mul(UNITY_MATRIX_VP, positionWS);
                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 worldPos = i.worldPosition;
               // return half4(worldPos,1);
                half4 color = tex2D(_MainTex, i.uv);
                clip(color.a - _Cutoff);
                Light light = GetMainLight();
            
                //计算光照和阴影，光照采用Lembert Diffuse.
                //fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 lightDir = light.direction;
                half3 lightColor = light.color;
                float3 worldNormal = normalize(i.worldNormal);
                // 半兰伯特光照模型
                half3 halfLambert = dot(worldNormal, lightDir) * 0.5 + 0.5;
                half3 diffuse = max(halfLambert, 0.5);

                // 阴影
                 //UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                color.rgb *= _Color;
                half3 finalColor = color * diffuse ;
                return half4(finalColor,1);
                return color;
            }
            ENDHLSL
        }
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
