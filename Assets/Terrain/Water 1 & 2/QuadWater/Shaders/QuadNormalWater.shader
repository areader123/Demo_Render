Shader "LSQ/Terrain/Water/QuadNormalWater"
{
    Properties
    {
		_DepthShallowColor("Depth Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
		_DepthDeepColor("Depth Deep Color", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _BumpMap ("Bump Map", 2D) = "bump"{}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}	
		_SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}

        Pass
        {
            Tags 
            { 
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uvNormal : TEXCOORD0;
                float2 uvDistortion : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 viewDir : TEXCOORD4;
            };

            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            sampler2D _SurfaceDistortion;
			float4 _SurfaceDistortion_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uvNormal = v.uv * _BumpMap_ST.xy + _BumpMap_ST.zw * _Time.y;
                o.uvDistortion = v.uv * _SurfaceDistortion_ST.xy + _SurfaceDistortion_ST.zw * _Time.y;
                float3 biTangent = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                float3x3 tangentSpaceMatrix = float3x3(v.tangent.xyz, biTangent, v.normal);
                o.lightDir = mul(tangentSpaceMatrix, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(tangentSpaceMatrix, ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            sampler2D _CameraDepthTexture;

            float4 _DepthShallowColor;
			float4 _DepthDeepColor;
            float _DepthMaxDistance;

            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            float _SurfaceDistortionAmount;

            fixed4 frag (v2f i) : SV_Target
            {
                float4 depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));

                //depth color gradient
				float depth = LinearEyeDepth(depth01);
                float depthOffset = depth - LinearEyeDepth(i.vertex.z);//i.screenPos.w
                float depthOffset01 = saturate(depthOffset / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthShallowColor, _DepthDeepColor, depthOffset01);

                //light
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                float2 distortSample = (tex2D(_SurfaceDistortion, i.uvDistortion).xy * 2 - 1) * _SurfaceDistortionAmount;
				float2 normalUV = float2(i.uvNormal.x + distortSample.x, i.uvNormal.y + distortSample.y);
                fixed4 packedNormal = tex2D(_BumpMap, normalUV);
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                fixed3 albedo = waterColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, waterColor.a);
            }
            ENDCG
        }
    }
}
