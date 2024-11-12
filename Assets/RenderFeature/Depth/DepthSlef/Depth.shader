Shader "Sea/Depth"
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
    

            

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float viewSpaceDepth : TEXCOORD1;
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.viewSpaceDepth = -mul(UNITY_MATRIX_MV,v.vertex).z;
                return o;
        
                
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv) *_A;
                float depthEye = i.viewSpaceDepth * _ProjectionParams.w;
                // apply fog
                return depthEye;
            }
            ENDHLSL
        }
    }
}
