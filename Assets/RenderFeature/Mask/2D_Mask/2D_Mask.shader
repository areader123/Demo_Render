Shader "Unlit/2D_Mask"
{
    Properties
    {
        _MaskCenter ("Mask Center", Vector) = (0, 0, 0, 1)
        _Intensity ("Intensity", Range(0, 10)) = 3 // 控制实际的边界
        _Roundness ("Roundness", Range(0, 10)) = 1  //控制边界的形状
        _Smoothness ("Smoothness", Range(0, 5)) = 0.2   //控制边界的虚化
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
    
            float3 _MaskCenter;
            float _Roundness;
            float _Intensity;
            float _Smoothness;
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

          

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
        
                
            }

            float4 frag (v2f i) : SV_Target
            {
                // float mask = UniversalMask2D(i.uv, _MaskCenter, _Intensity, _Roundness, _Smoothness);
                float2 d = abs(i.uv - _MaskCenter.xy) * _Intensity;
                d = pow(saturate(d),_Roundness);
                float distance = length(d);
                float vfactor = pow(saturate(1 - distance * distance),_Smoothness);
                //1- 的目的是将中间变成白色 中间白周围黑 
                //否则为中间黑周围白
                return vfactor;
            }
            ENDHLSL
        }
    }
}
