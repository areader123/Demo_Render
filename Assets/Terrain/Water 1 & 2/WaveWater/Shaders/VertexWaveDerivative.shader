Shader "LSQ/Terrain/Water/VertexWaveDerivative"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20 

        _WaveFrequency("Wave Frequency", float) = 3
        _WaveHeight("Wave Height", float) = 3
        _WaveSpeed("Wave Speed", vector) = (2,0,2,0)
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
            "RenderType" = "Transparent" 
        }
        Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

        Pass
        {
            Tags
            {
                "LightMode" = "Always" 
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : NORMAL;
            };

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            float _WaveFrequency;
            float _WaveHeight;
            float3 _WaveSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                float changeCenter = (v.vertex.x + _Time.y * _WaveSpeed.x) * _WaveFrequency;
                float height = _WaveHeight * sin(changeCenter);
                v.vertex.y += height;

                //法2：利用导数求变化率得方向
                float3 tangent = normalize(float3(1, cos(changeCenter), 0));
                float3 normal = float3(tangent.y, tangent.x, 0);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(i.normal, lightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(i.normal, halfDir)), _Gloss);

                fixed3 light = ambient + diffuse + specular;
                fixed brightness = Luminance(light);

                return fixed4(_Color.rgb * light, _Color.a);
            }
            ENDCG
        }
    }
}
