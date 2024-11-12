Shader "Sea/UnderWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
             
                float4 vertex : SV_POSITION;
            };
            float _Size;
            float4 _CameraCorner[4];
            sampler2D _CameraDepthTexture;
            sampler2D _DownDepthTaxture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
               float4 worldSpacePosition =lerp(lerp(_CameraCorner[0],_CameraCorner[1],i.uv.x).lerp(_CameraCorner[2],_CameraCorner[3],i.uv.x),i.uv.y);
                float2 worldUV = float2(worldSpacePosition.x,worldSpacePosition.z);
                float4 waterWorldHeight = tex2D(_DownDepthTaxture,worldUV/(_Size * 2));
                float underWater = step(worldSpacePosition.y,waterWorldHeight.y);
                return underWater;
            }
            ENDHLSL
        }
    }
}
