Shader "Sea/Depth_Water"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

           
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
              float4 screenPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            float4x4 _InvV;
            float4x4 _InvP;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                //screenPos =i.uv;    
                float depth = (tex2D(_CameraDepthTexture,screenPos));
                float4 NDC = float4((screenPos * 2 -1),depth,1.0);
                float4 positionWorldSpace = mul(_InvV,NDC);
                positionWorldSpace = mul(_InvP,positionWorldSpace);
                return float4(positionWorldSpace.yyy,1);//输出rt为世界空间的y坐标
            }
            ENDHLSL
        }
    }
}
