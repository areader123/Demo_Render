Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _ColorTint ("Color Tint", Color) = (1,1,1,1)
        _AlbedoTex ("Albedo Tex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100


    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        half4 _ColorTint;
        float4 _AlbedoTex_ST;
        CBUFFER_END

        TEXTURE2D(_AlbedoTex);
        SAMPLER(sampler_AlbedoTex);        
        
        struct VSInput
        {
            float3 positionL : POSITION;
            float3 normalL : NORMAL;
            float2 uv : TEXCOORD0;
        };
        struct PSInput
        {
            float4 positionH : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normalW : TEXCOORD1;
        };
    ENDHLSL
    
        Pass
        {
         Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex VS
            #pragma fragment PS

            PSInput VS(VSInput vsInput)
            {
                PSInput vsOutput;

                vsOutput.positionH = TransformObjectToHClip(vsInput.positionL);
                vsOutput.normalW = TransformObjectToWorldNormal(vsInput.normalL, true);
                vsOutput.uv = TRANSFORM_TEX(vsInput.uv, _AlbedoTex);

                return vsOutput;
            }

            half4 PS(PSInput psInput) : SV_TARGET
            {
                half4 texDiff = SAMPLE_TEXTURE2D(_AlbedoTex, sampler_AlbedoTex, psInput.uv) * _ColorTint;

                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                half3 lightDir = normalize(mainLight.direction);
                
                float NoL = saturate(dot(lightDir, psInput.normalW) * 0.5 + 0.5);

                return half4(texDiff.rgb * NoL * lightColor, texDiff.a);
            }
            
            ENDHLSL
        }
    }
}
