Shader "LSQ/Terrain/Water/QuadFoamWater"
{
    Properties
    {
		_DepthShallowColor("Depth Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
		_DepthDeepColor("Depth Deep Color", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.2

		_SurfaceNoise("Surface Noise", 2D) = "white" {}
		_SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)
		_SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
		_SurfaceDistortion("Surface Distortion", 2D) = "white" {}	
		_SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 noiseUV : TEXCOORD0;
                float2 distortUV : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            sampler2D _SurfaceNoise;
			float4 _SurfaceNoise_ST;
			sampler2D _SurfaceDistortion;
			float4 _SurfaceDistortion_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            sampler2D _CameraDepthTexture;

            float4 _DepthShallowColor;
			float4 _DepthDeepColor;
            float _DepthMaxDistance;

			float4 _FoamColor;
            float _FoamMaxDistance;

            float2 _SurfaceNoiseScroll;
            float _SurfaceNoiseCutoff;
			float _SurfaceDistortionAmount;

            float aaStep(float compValue, float gradient)
			{
			    float change = fwidth(gradient);
			    //base the range of the inverse lerp on the change over two pixels
			    float lowerEdge = compValue - change;
			    float upperEdge = compValue + change;
			    //do the inverse interpolation
			    float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
			    stepped = saturate(stepped);
			    //smoothstep version here would be `smoothstep(lowerEdge, upperEdge, gradient)`
			    return stepped;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                float4 depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));

                //depth color gradient
				float depth = LinearEyeDepth(depth01);
                float depthOffset = depth - LinearEyeDepth(i.vertex.z);//i.screenPos.w
                float depthOffset01 = saturate(depthOffset / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthShallowColor, _DepthDeepColor, depthOffset01);

                //foam color
                float foamOffset01 = saturate(depthOffset / _FoamMaxDistance);

                //surface Foam Noise
                float surfaceNoiseCutoff = foamOffset01 * _SurfaceNoiseCutoff;
				float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;
				float2 noiseUV = float2((i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, 
				                        (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);
				float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;
                //float surfaceNoise = step(surfaceNoiseCutoff, surfaceNoiseSample);
				float surfaceNoise = smoothstep(surfaceNoiseCutoff, surfaceNoiseCutoff + 0.1, surfaceNoiseSample);
                //float surfaceNoise = aaStep(surfaceNoiseCutoff, surfaceNoiseSample);

                return lerp(waterColor, _FoamColor, surfaceNoise);
            }
            ENDCG
        }
    }
}
