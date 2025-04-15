Shader "Hidden/VolumetricLighting"
{
	Properties
	{
		[HideInInspector]
		_MainTex ("source", 2D) = "white"
	}

	// Stuff that is common for all of your shader passes
	HLSLINCLUDE

	// includes
	// - "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	// - struct ls_appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; }
	// - struct ls_v2f { float4 vertex : SV_POSITION; float2 uv : TEXCOORD0; }
	// - ls_v2f vert (ls_appdata)
	#include "../LoneStack.cginc"

	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

	sampler2D _MainTex;
	float _Blend;

	float random(float2 st) {
		return frac(sin(dot(st.xy,
			float2(12.9898, 78.233))) *
			43758.5453123);
	}

	ENDHLSL

	Subshader
	{

		Cull Off ZWrite Off ZTest Always

		Pass // 0 - First pass
		{
			Blend One One

			HLSLPROGRAM

			#pragma vertex ls_vert
			#pragma fragment frag

			float4 _Intens;
			
			int _StepCount;
			float _Distance;

			float3 _CamPos;
			float3 _CamFwd;
			float3 _CamUp;
			float3 _CamRight;

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			half4 frag(ls_v2f i) : SV_Target
			{
				float lum = 0;
				
				float camDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.xy), _ZBufferParams);
				float3 disp = normalize(_CamFwd + _CamUp * (i.uv.y * 2 - 1) + _CamRight * (i.uv.x * 2 - 1));
				float stepSize = 1.0 / (float)_StepCount;
				float sampleDepth = random(i.uv + _Time.xx * .01) * stepSize * _Distance;

				ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
				half4 shadowParams = GetMainLightShadowParams();

				[unroll(100)]
				for (int s = 0; s < _StepCount; s++)
				{
					float4 wpos = float4(_CamPos + disp * sampleDepth, 1);
					int cascadeIndex = ComputeCascadeIndex(wpos.xyz);

					if (sampleDepth >= camDepth) break;

					float4 lightPos = mul(_MainLightWorldToShadow[cascadeIndex], wpos);
					
					lum += stepSize * _Intens[min(3, cascadeIndex)] * lerp(
						SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), lightPos, shadowSamplingData, shadowParams, false),
						1,
						float(cascadeIndex >= 4 || lightPos.z < 0));

					sampleDepth += stepSize * _Distance;
				}

				return _MainLightColor * lum * _Blend;
			}

			ENDHLSL
		}
	}
}