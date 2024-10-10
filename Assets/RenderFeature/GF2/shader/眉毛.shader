Shader "Unlit/眉毛"
{
    Properties
    {   
        [Header(SteancilRef)]
        _SteancilRef("SteancilRef", int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("StencilComp", int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("StencilOp", int) = 0
         _Alpha("_Alpha",Range(0,1))=0.5
        _MainTex("_MainTex",2D) = "white"{}
    }
    SubShader
    {
        LOD 100

        Pass
        {   
            Name"GF_眉毛"
            Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode"="GF_眉毛"}
            Stencil
                {
                     Ref 2
                     ReadMask 255
                     WriteMask 255
                     Comp Always
                     Pass Replace

                }


            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END




            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

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
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                // apply fog
              
                return col;
            }
            ENDHLSL
        }
    }
}
