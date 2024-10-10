Shader "Unlit/FlowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FlowMap ("Flow Map", 2D) = "white" { }
        _Tilling ("Tilling", Range(0, 10)) = 1
        _Speed ("Speed", Range(0, 100)) = 10
        _Strength ("Strength", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            sampler2D _FlowMap;
            float4 _FlowMap_ST;
            sampler2D _MainTex;
              float4 _MainTex_ST;
            float _Speed;
            float _Strength;
            float _Tilling;
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

         
          

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
           
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {   
                float speed = _Time.x * _Speed;
                float speed1 = frac(speed);
                float speed2 = frac(speed + 0.5);//造成异步
                 
                float4 noise = tex2D(_FlowMap,i.uv);
                float2 flow_uv = -(noise.xy * 2 - 1);//利用flowmap.xy 去替代uv 采样 mainmap

                float2 flow_uv1 = flow_uv * speed1 * _Strength;
                float2 flow_uv2 = flow_uv * speed2 * _Strength;

                flow_uv1 += i.uv * _Tilling;//让uv可以影响flowmap
                flow_uv2 += i.uv * _Tilling;


                float4 color1 = tex2D(_MainTex,flow_uv1);
                float4 color2 = tex2D(_MainTex,flow_uv2);

                float lerpvalue = abs(speed1 *2 - 1);//函数图像为过原点的 折线 使扰动图像连续
                float4 final =  lerp(color1,color2,lerpvalue);

                return final;
            }
            ENDHLSL
        }
    }
}
