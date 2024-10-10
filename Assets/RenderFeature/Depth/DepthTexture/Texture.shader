Shader "Unlit/Texture"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }
        ZWrite On

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
    

            sampler2D _CameraDepthTexture;
            struct appdata
            {
                float4 vertex : POSITION;
                 float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

          

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.texcoord;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;        
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                float depth = Linear01Depth(tex2D(_CameraDepthTexture,screenPos).r,_ZBufferParams);
                return  depth;
            }
            ENDHLSL
        }
    }
}
