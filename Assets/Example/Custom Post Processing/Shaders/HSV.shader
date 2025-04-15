Shader "Example/Custom Post Processing/HSV"
{
    Properties
    {
        [HideInInspector] _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Brightness ("Brightness", Range(0,1)) = 0.5
        _Saturate ("Saturate", Range(0,1)) = 0.0
        _Contranst ("Constrast", Range(-1,2)) = 0.0
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" }

        pass
        { 
            Cull Off ZWrite Off ZTest Always

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 texcoord : TEXCOORD;
            };

            v2f Vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float _Brightness;
            float _Saturate;
            float _Contranst;

            float4 Frag(v2f i) :SV_TARGET
            {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                float gray = 0.21 * tex.x + 0.72 * tex.y + 0.072 * tex.z;
                tex.xyz *= _Brightness;
                tex.xyz = lerp(float3(gray, gray, gray), tex.xyz, _Saturate);
                tex.xyz = lerp(float3(0.5, 0.5, 0.5), tex.xyz, _Contranst);
                return tex;
            }

            ENDHLSL
        }
    }
    
}   

