Shader "Unlit/SceneHeightMap"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
               
            };

            struct v2f
            {
                float2 depth : TEXCOORD0;
                
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                 o.depth = o.vertex.zw;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                 float depth = i.depth.x / i.depth.y;//透视矫正
                #if defined(UNITY_REVERSED_Z)
                    depth = 1 - depth;
                #endif
                return EncodeFloatRGBA(depth);
            }
            ENDCG
        }
    }
}
