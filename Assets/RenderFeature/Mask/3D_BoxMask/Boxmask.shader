Shader "Unlit/Boxmask"
{
    Properties
    {
        _MaskCenter ("Box Mask Center", Vector) = (0, 0, 0, 1)
        _MaskSize ("Box Mask Size", Vector) = (1, 1, 1, 1)
        _Falloff ("Falloff", Range(0, 1)) = 0.1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

            float3 _MaskCenter;
            float3 _MaskSize;
            float _Falloff;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.positionWS = TransformObjectToWorld(v.vertex);
                return o;
        
                
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv) *_A;   
                float mask = distance(max(abs(i.positionWS - _MaskCenter) - (0.5 * _MaskSize),0),0) / _Falloff;
                // apply fog
                return mask;
            }
            ENDHLSL
        }
    }
}
