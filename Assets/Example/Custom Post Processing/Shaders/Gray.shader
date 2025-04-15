Shader "Example/Custom Post Processing/Gray"
{
    Properties
    {
        [HideInInspector]_MainTex("Source", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHS = TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;
                return output;
            }

            TEXTURE2D_X(_MainTex);
            SAMPLER(sampler_LinearClamp);
            
            float4 Frag(Varyings i) : SV_Target
            {
                float4 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp,i.uv);
                return (color.r + color.g + color.b) * 0.333;
            }
            ENDHLSL
        }
    }
}
