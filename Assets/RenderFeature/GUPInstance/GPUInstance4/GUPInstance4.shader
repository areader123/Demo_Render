Shader "Unlit/GUPInstance4"
{
    Properties
    {
       _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
    
            StructuredBuffer<float4x4> localToWorldBuffer;
            float4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

          

            v2f vert (appdata v,uint instanceID : SV_INSTANCEID)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                float4x4 localToWorldMatrix = localToWorldBuffer[instanceID];
                float4 positionWS = mul(localToWorldMatrix,v.vertex);
                // 变换到ndc空间 ?????????????????????
                positionWS /= positionWS.w;
                o.vertex = mul(UNITY_MATRIX_VP,positionWS);
                return o;
        
                
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv) *_A;
                // apply fog
                return _Color;
            }
            ENDHLSL
        }
    }
}
