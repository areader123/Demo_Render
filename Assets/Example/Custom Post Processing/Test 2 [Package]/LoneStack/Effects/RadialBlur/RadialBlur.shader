Shader "Hidden/RadialBlur"
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

			HLSLPROGRAM

			#pragma vertex ls_vert
			#pragma fragment frag

			float _Step;
			float _Rndm;
			float _Noise;
			float _Intens;
			float _Offset;
			float _Shape;

			half4 frag(ls_v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				float2 disp = i.uv - .5;
				float f = dot(disp, disp) * _Step * (1 - random(i.uv + _Rndm.xx) * _Noise);
				disp /= 1 + f * _Intens * _Blend;
				return lerp(col, tex2D(_MainTex, .5 + disp), clamp((pow(abs(f), _Shape) - _Offset) * 2, 0, 1));
			}

			ENDHLSL
		}
	}
}