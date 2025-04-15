Shader "Hidden/SpeedEffect"
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
	#include "noiseSimplex.cginc"

	sampler2D _MainTex;
	float _Blend;

	#define pi2 6.28318530718

	ENDHLSL

	Subshader
	{

		Cull Off ZWrite Off ZTest Always
		
		Pass // 0 - First pass
		{

			HLSLPROGRAM

			#pragma vertex ls_vert
			#pragma fragment frag

			float _Speed;
			float4 _StripesColor;
			float _StripesIntens;
			float _StripesShape;
			float _StripesOffset;
			float4 _FireColor0;
			float4 _FireColor1;
			float _FireIntens;
			float _FireFreq;
			float _FireOffset;
			float _Distortion;

			half4 frag(ls_v2f i) : SV_Target
			{
				float2 disp = i.uv - .5;
				float2 uv = float2(atan2(disp.y, disp.x), length(disp) * 2);
				float n0 = snoise(float3(sin(uv.x * 2 * _FireFreq), cos(uv.x * 2 * _FireFreq), uv.y - _Time[1] * _Speed)) * .5 + .5;
				float n1 = snoise(float3(sin(uv.x * 4 * _FireFreq), cos(uv.x * 4 * _FireFreq), (uv.y + n0 * .5) * 2 - _Time[1] * (_Speed + 2))) * .5 + .5;
				float d = dot(disp, disp);
				float f = max(0, d - _StripesOffset) * pow(abs(snoise(float3(sin(uv.x * 2), cos(uv.x * 2), _Time[1] * _Speed * .5)) * .5 + .5), _StripesShape) * 2;
				uv = .5 + disp / (1 + _Blend * (f * _StripesIntens + n0 * n1 * max(0, d - _FireOffset) * _FireIntens) * _Distortion);
				float finalFireIntens = pow(_FireIntens, 2) * 2 * max(0, d - _FireOffset) * _Blend;
				return lerp(tex2D(_MainTex, uv), _StripesColor, f * _StripesIntens * _Blend) * (1 - finalFireIntens) +
					finalFireIntens * 1.2 * lerp(_FireColor0, _FireColor1, pow(n0 * n1,2));
			}

			ENDHLSL
		}
	}
}