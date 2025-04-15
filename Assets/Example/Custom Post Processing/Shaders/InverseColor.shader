Shader "Example/Custom Post Processing/InverseColor"
{
    Properties
    {
        [HideInInspector] _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" }

        pass
        { 
            Cull Off ZWrite Off ZTest Always

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            struct a2v
            {
                float4 positionOS:POSITION;
                float2 texcoord:TEXCOORD;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float2 texcoord:TEXCOORD;
            };

            v2f Vert(a2v i)
            {
                v2f o;
                o.positionCS =TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 Frag(v2f i) :SV_TARGET
            {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.texcoord);
                return 1 - tex;
            }

            ENDHLSL
        }
    }
    
}   

