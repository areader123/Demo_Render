Shader "Hidden/Colorize"
{
	Properties
	{
		[HideInInspector]
		_MainTex ("source", 2D) = "white"
	}

	HLSLINCLUDE

	// includes
	// - struct ls_appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; }
	// - struct ls_v2f { float4 vertex : SV_POSITION; float2 uv : TEXCOORD0; }
	// - ls_v2f vert (ls_appdata)
	#include "../LoneStack.cginc"

	sampler2D _MainTex;
	float _Blend;
	half4 _Tint;
	float _Contrast;

	ENDHLSL

	Subshader
	{

		Cull Off ZWrite Off ZTest Always
		
		Pass // 0 - First pass
		{

			HLSLPROGRAM

			#pragma vertex ls_vert
			#pragma fragment frag

			half4 frag(ls_v2f i) : SV_Target
			{
				half4 col = tex2D(_MainTex, i.uv);
				half3 col1 = abs(col.rgb * _Tint.rgb);
				col1 = min(col1, pow(col1, 1 + _Contrast));
				col.rgb = lerp(col.rgb, col1, _Blend);
				return col;
			}

			ENDHLSL
		}
	}
}