Shader "Unlit/Rain"
{
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline"="UniversalPipeline" }
        Cull Front ZWrite Off ZTest Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

            

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 color : COLOR;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float3 color : COLOR;
            };


            CBUFFER_START(UnityPerMaterial)
                float4 _RainColor;
                float2 _RainIntensity;

                float4 _FarTillingSpeed;
                float4 _FarDepthSmooth;
                float4 _NearTillingSpeed;
                float4 _NearDepthSmooth;

                float4x4 _DepthCameraMatrixVP;
            CBUFFER_END

            TEXTURE2D(_SourceTex);
            SAMPLER(sampler_SourceTex);

            TEXTURE2D(_RainTexture);
            SAMPLER(sampler_RainTexture);

            TEXTURE2D(_SceneHeightTex);
            SAMPLER(sampler_SceneHeightTex);

            inline half SmoothValue(half threshold, half smoothness, half value)
            {
                half minValue = saturate(threshold - smoothness);
                half maxValue = saturate(threshold + smoothness);
                return smoothstep(minValue, maxValue, value);
            }

            inline float DecodeFloatRGBA(float4 enc)
            {
                float4 kDecodeDot = float4(1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0);
                return dot(enc, kDecodeDot);
            }
            float3 ComputeWorldPosition(float2 screen_UV, float eyeDepth)//屏幕空间 和 深度 重建世界空间
            {
                //NDC
                float4 ndcPos = float4(screen_UV * 2 - 1 ,0,1);//xy为screenPos.xy/screenPos.w , z待定, w为1
                //裁剪空间
                float4 clipPos = mul(unity_CameraInvProjection,ndcPos);
                clipPos = float4(((clipPos.xyz / clipPos.w) * float3(1,1,-1)),1.0);//透视除法
                clipPos.z = eyeDepth;
                return mul(unity_CameraToWorld,clipPos);
            }
            float CalculateHeightVisibility(float4 heightCameraPos)
            {
                float3 uvw = 0;
                heightCameraPos.xyz = heightCameraPos.xyz / heightCameraPos.w;//透视除法 转换为NDC空间
                uvw.xy = heightCameraPos.xy * 0.5 + 0.5;//-1，1 到 0，1 相当于sceenUV

                #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                    uvw.z = heightCameraPos.z * 0.5 + 0.5; //[-1, 1]-->[0, 1]
                #elif defined(UNITY_REVERSED_Z)
                    uvw.z = 1 - heightCameraPos.z;

                #endif
                float4 height = SAMPLE_TEXTURE2D(_SceneHeightTex, sampler_SceneHeightTex, uvw.xy);
                float sceneHeight = DecodeFloatRGBA(height);
                float visibilityY = step(uvw.z,sceneHeight);//主相机的像素深度 与 点所对应的深度图 比较 
                return visibilityY;
            }

            float CalculateRainVisibility(float2 screen_UV, float eyeDepth, float sceneViewDepth)
            {
                float sceneEyeDepth = LinearEyeDepth(sceneViewDepth,_ZBufferParams);
                //主摄像机水平遮挡
                float visibilityH = step(eyeDepth,sceneEyeDepth);

                float3 rainPositionWS = ComputeWorldPosition(screen_UV,eyeDepth);
                float4 heightCameraPos = mul(_DepthCameraMatrixVP,float4(rainPositionWS,1.0));
                //高度遮挡
                float visibilityV = CalculateHeightVisibility(heightCameraPos);
                return visibilityH * visibilityV;
            }

            v2f vert (a2v input)
            {
                v2f output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
                output.positionCS = vertexInput.positionCS;

                output.screenPos = ComputeScreenPos(output.positionCS);
                //赋值
                float2 farTilling = _FarTillingSpeed.xy;
                float2 farSpeed = _FarTillingSpeed.zw;

                float2 nearTilling = _NearTillingSpeed.xy;
                float2 nearSpeed = _NearTillingSpeed.zw;
                // tilling offset UV动画
                output.uv.xy = input.uv * nearTilling + nearSpeed * _Time.x;
                output.uv.zw = input.uv * farTilling + farSpeed * _Time.x;

                output.color = input.color;
                return output;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 screen_UV = i.screenPos.xy / i.screenPos.w;
                float2 nearDepthBaseRange = _NearDepthSmooth.xy;//存的是 base和range 但深度最后只有一个
                float2 farDepthBaseRange = _FarDepthSmooth.xy;

                //计算遮挡
                float sceneViewDepth = SampleSceneDepth(screen_UV);

                float2 nearRain = SAMPLE_TEXTURE2D(_RainTexture,sampler_RainTexture,i.uv.xy).xz;
                float nearRainDepth = nearRain.y * nearDepthBaseRange.y + nearDepthBaseRange.x;
                float nearRainLayer = CalculateRainVisibility(screen_UV, nearRainDepth, sceneViewDepth);


                //如果只有一层rain也可以实现下雨 但一旦存在rain被遮挡 则就完全无雨 两层的效果更好
                // #if defined(_DOUBLE_RAIN) 
                float2 farRain = SAMPLE_TEXTURE2D(_RainTexture, sampler_RainTexture, i.uv.zw).yz;
                float farRainDepth = farRain.y * farDepthBaseRange.y + farDepthBaseRange.x;
                float farRainLayer = CalculateRainVisibility(screen_UV, farRainDepth, sceneViewDepth);
                // #endif
                //混合颜色 
                half3 color = _RainColor;
                nearRain.x = SmoothValue(_NearDepthSmooth.z,_NearDepthSmooth.w,nearRain.x);//此处为一个遮罩 让遮罩更加平滑


                half rainAlpha = 0;
                rainAlpha += nearRain.x * nearRainLayer * _RainIntensity.r;

                rainAlpha += farRain.x * farRainLayer * _RainIntensity.g;

                rainAlpha = rainAlpha * _RainColor.a* i.color.r;//顶点色 
                return half4(color,rainAlpha);
            }
            ENDHLSL
        }
    }
}
