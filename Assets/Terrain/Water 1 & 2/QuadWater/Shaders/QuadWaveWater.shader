Shader "LSQ/Terrain/Water/QuadWaveWater"
{
    Properties
    {
		_DepthShallowColor("Depth Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
		_DepthDeepColor("Depth Deep Color", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _WaveTexture("Wave Texture", 2D) = "white"{}
        _WaveColor("Wave Color", Color) = (1,1,1,1)
        _WaveMaxDistance("Wave Maximum Distance", Float) = 0.2
        _WaveCutOff("Wave Cut Off", Range(0,1)) = 0.5
        _WaveStrength("Wave Strength", Float) = 0.2
        _WaveCount("Wave Count", Float) = 3
        _WaveSpeed("Wave Speed", Float) = 3
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.texcoord;
                return o;
            }

            sampler2D _CameraDepthTexture;

            float4 _DepthShallowColor;
			float4 _DepthDeepColor;
            float _DepthMaxDistance;

            sampler2D _WaveTexture;
			float4 _WaveColor;
            float _WaveMaxDistance;
            float _WaveCutOff;
            float _WaveStrength;
            float _WaveCount;
            float _WaveSpeed;

            fixed4 frag (v2f i) : SV_Target
            {
                float4 depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));

                //depth color gradient
				float depth = LinearEyeDepth(depth01);
                float depthOffset = depth - LinearEyeDepth(i.vertex.z);//i.screenPos.w
                float depthOffset01 = saturate(depthOffset / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthShallowColor, _DepthDeepColor, depthOffset01);

                //wave color
                float waveOffset01 = 1 - saturate(depthOffset / _WaveMaxDistance);
                float2 uv = float2(i.uv.x, (waveOffset01 + _WaveSpeed * _Time.y) * _WaveCount);
                float wave = tex2D(_WaveTexture, uv).r * waveOffset01 * _WaveStrength;
                wave = step(_WaveCutOff, wave);

                return lerp(waterColor, _WaveColor, waveOffset01 + wave);
            }
            ENDCG
        }
    }
}
