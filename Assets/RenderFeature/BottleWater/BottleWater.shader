Shader "Unlit/BottleWater"
{
    Properties
    {
               _Color ("Color", Color) = (1,1,1,1)
        _TopColor("Top Color", Color) = (1,1,1,1)
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FluidHeight("Fluid Height", Range(-0.5, 0.5)) = 0
        _Threshold("Threshold", Range(0, 1)) = 0.1
        _DepthMaxDistance("Foam Distance", Range(0,2)) = 1


        [HideInInspector]_WobbleX("MaxHeightInX", Float) = 0
        [HideInInspector]_WobbleZ("MaxHeightInZ", Float) = 0

        _LiquidRimColor ("Liquid Rim Color", Color) = (1,1,1,1)
        _LiquidRimPower ("Liquid Rim Power", Range(0,50)) = 0
        _LiquidRimScale ("Liquid Rim Scale", Range(0,1)) = 1

        [Header(Bottle)]

        _BottleColor ("Bottle Color", Color) = (0.5,0.5,0.5,1)
        _BottleThickness ("Bottle Thickness", Range(0,1)) = 0.1
        
        _BottleRimColor ("Bottle Rim Color", Color) = (1,1,1,1)
        _BottleRimPower ("Bottle Rim Power", Range(0,10)) = 0.0
        _BottleRimIntensity ("Bottle Rim Intensity", Range(0.0,3.0)) = 1.0
        
        _BottleSpecular ("Bottle Specular Color", Color) = (1,1,1,1)
        _BottleGloss ("BottleGloss", Range(0,1) ) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline"="UniversalPipeline"  }
        LOD 100
          pass
        {
             Tags {"LightMode" =  "UniversalForward"  "RenderType"=" Transparent"  "Queue"="Transparent + 1"}
             Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
           struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL; 
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir : COLOR;
                float3 normal : COLOR2;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 viewDirWorld : TEXCOORD3;
            };
            
            float4 _BottleColor, _BottleRimColor,_BottleSpecular;
            float _BottleThickness, _BottleRim, _BottleRimPower, _BottleRimIntensity;
            float _BottleGloss,_SpecularThreshold,_SpecularSmoothness;
            
            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz += _BottleThickness * v.normal;
                o.vertex = TransformObjectToHClip(v.vertex);
                float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
                o.viewDir = normalize(objSpaceCameraPos - v.vertex.xyz);
                o.normal = v.normal;
                
                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.viewDirWorld = (_WorldSpaceCameraPos.xyz - posWorld.xyz);
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                return o;
            }
            
            // 计算色阶
            float calculateRamp(float threshold,float value, float smoothness){
                threshold = saturate(1-threshold);
                half minValue = saturate(threshold - smoothness);
                half maxValue = saturate(threshold + smoothness);
                return smoothstep(minValue,maxValue,value);
            }

            float4 frag (v2f i, float facing : VFACE) : SV_Target
            {
                Light light = GetMainLight();
                // specular
                float3 N = normalize(i.normalDir);
                float3 V = normalize(i.viewDir);
                float specularPow = exp2 ((1 - _BottleGloss) * 10.0 + 1.0);
                
                float3 H = normalize (normalize(light.direction) + i.viewDirWorld);
                float NdotH = max(0,dot(N, H));
                float NdotV = max(0,dot(N, V));

                float specularCol = pow(NdotH,specularPow)*_BottleSpecular;
                // 阈值判断
                // float specularRamp = calculateRamp(_SpecularThreshold,specular,_SpecularSmoothness);
                // fixed4 specularCol = specularRamp*_BottleSpecular;

                // rim
                float fresnel = 1 - pow(NdotV, _BottleRimPower);
                float4 rim = _BottleRimColor * smoothstep(0.5, 1.0, fresnel) * _BottleRimIntensity;
                rim.rgb = rim.a > 0.25 ? _BottleColor.rgb : rim.rgb;//rim.a 越小说明越边缘

                //_BottleColor.a == 0 中间部分为透明

                float4 finalCol = rim + _BottleColor + specularCol;
                return finalCol;
            }
            ENDHLSL
        }
        Pass
        {   
            Tags { "RenderType"=" Transparent"  "Queue"="Transparent" "RenderPipeline"="UniversalForward "}
             Blend SrcAlpha OneMinusSrcAlpha
             Cull Back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;	
                float3 normal : TEXCOORD0;
                float3 posWS : TEXCOORD2;
                float3 localPos : TEXCOORD3;
                float4 screenPos : TEXCOORD1;
            };
            half4 _Color;
            half4 _TopColor;
            half4 _FoamColor;
            half _FluidHeight;
            half _Threshold;
            float _WobbleX;
            float _WobbleZ;

            float _LiquidRimPower;
            float _LiquidRimScale;
            half4 _LiquidRimColor;

            sampler2D _CameraDepthTexture;
            half _DepthMaxDistance;
          

            v2f vert (appdata v)
            {
                v2f o;
                float rate = sqrt((0.5 * 0.5 - _FluidHeight * _FluidHeight) / (v.vertex.x * v.vertex.x + v.vertex.z * v.vertex.z));
                float verterDis = min(rate,1);

                //得到水面
                float vertexHeight = step(_FluidHeight,v.vertex.y);
                v.vertex.y = vertexHeight * _FluidHeight + (1 - vertexHeight) * v.vertex.y;
                v.normal = vertexHeight * float3(0,1,0) + (1 - vertexHeight) * v.normal;
                o.pos = TransformObjectToHClip(v.vertex);
               

                //以下未知
                verterDis = lerp(1,verterDis,vertexHeight);
                v.vertex.xz *= verterDis;
                float isRate = (rate - 1 < _Threshold && rate - 1 > 0);
                isRate *= vertexHeight;
                rate = lerp(1,rate,isRate);
                v.vertex.xz *= rate;

                //以下为c#传入 构建x和z 两个旋转矩阵
                float X,Z;
                X = atan(_WobbleX/2);
                Z = atan(_WobbleZ/2);
                float3x3 rotMatX,rotMatZ;
                rotMatX[0] = float3(1, 0, 0);
                rotMatX[1] = float3(0, cos(X), sin(X));
                rotMatX[2] = float3(0, -sin(X), cos(X));
                rotMatZ[0] = float3(cos(Z), sin(Z), 0);
                rotMatZ[1] = float3(-sin(Z), cos(Z), 0);
                rotMatZ[2] = float3(0, 0, 1);

                v.vertex.xyz = mul(rotMatX,mul(rotMatZ,v.vertex.xyz));
                o.pos = TransformObjectToHClip(v.vertex);
                o.localPos = v.vertex;
                o.normal = v.normal;
                o.screenPos = ComputeScreenPos(o.pos);
                o.posWS = TransformObjectToWorld(v.vertex);


                return o;
        
                
            }

            float4 frag (v2f i) : SV_Target
            {   float2 screenUV = i.screenPos.xy / i.screenPos.w;
                half depth01 = tex2D(_CameraDepthTexture,screenUV).r;
                float depthLinear = LinearEyeDepth(depth01,_ZBufferParams);
                float depthDifference = depthLinear - i.screenPos.w;
                //泡沫 浅水 深水
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 topColor = lerp(_FoamColor,_TopColor,waterDepthDifference01);
                

                float3 N = normalize(i.normal);
                float3 viewDir = GetObjectSpaceNormalizeViewDir(i.localPos);
                float NdotV = max(0,dot(N,viewDir));

                float fresnel = _LiquidRimScale + (1 - _LiquidRimScale) * pow((1 - NdotV),_LiquidRimPower);
                // 添加一个_LiquidRimScale 让水体主体有个稍微深一点的颜色
                half4 color = lerp(_Color,_LiquidRimColor,fresnel);
                topColor = lerp(topColor,_LiquidRimColor,fresnel);

                color.a += fresnel;//渐变透明

                float isTop = i.normal.y > 0.99;

                return lerp(color,topColor,isTop);
            }
            ENDHLSL
        }
      
    }
}
