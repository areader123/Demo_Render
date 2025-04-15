Shader "LSQ/Terrain/Water/VertexWaveLowPoly"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20 

        _WaveFrequency("Wave Frequency", float) = 3
        _WaveHeight("Wave Height", float) = 3
        _WaveSpeed("Wave Speed", vector) = (2,0,2,0)
        _WaveWidth("Wave Width", float) = 3
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
            #include "LSQ/Noise/SNoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            float _WaveFrequency;
            float _WaveWidth;
            float _WaveHeight;
            float3 _WaveSpeed;

            float GetWave(float pos, float speed)
            {
                float sinOffset = _WaveHeight * pow((sin(pos * _WaveFrequency + _Time.y * speed) + 1) * 0.5, _WaveWidth);
                float cosOffset = _WaveHeight * 0.5 * pow((cos(pos * _WaveFrequency * 0.5 + _Time.y * speed) + 1) * 0.5, _WaveWidth);
                return sinOffset + cosOffset;
            }

            v2f vert (appdata v)
            {
                v2f o;
                float height = GetWave(v.vertex.x, _WaveSpeed.x) + snoise(float3(v.vertex.x, 0, v.vertex.z)) * 0.1;
                v.vertex.y += height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //∑®1: π”√LowPoly
                float3 dpdx = ddx(i.worldPos);
                float3 dpdy = ddy(i.worldPos);
                float3 normal = normalize(cross(dpdy, dpdx));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(normal, lightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normal, halfDir)), _Gloss);

                fixed3 light = ambient + diffuse + specular;
                fixed brightness = Luminance(light);

                return fixed4(_Color.rgb * light, _Color.a);
            }
            ENDCG
        }
    }
}
