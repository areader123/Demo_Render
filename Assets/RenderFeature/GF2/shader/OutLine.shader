// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/NewUnlitShader"
{
    Properties
    {
       _Outline1("outline1",Range(0,0.1)) = 0.02
        _Outline2("outline2",Range(0,0.1)) = 0.02
         _Factor1("Factor1",Range(0,1)) = 0.5
         _Factor2("Factor2",Range(0,1)) = 0.5
         _MainColor("Color" , Color) = (1,1,1,1)
    }
    SubShader
    {
     
        LOD 100

        Pass
        {
             Tags{"LightMode" = "ForwardBase"}
            // Blend DstColor Zero
            Cull Front 
            ZWrite On 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
     
            struct v2f
            {    
                float4 pos : SV_POSITION;
                float3 lightDir : TEXCOORD;
                float3 viewDir : TEXCOORD1;
                float3 normal : NORMAL;
            };
            float _Outline1;
            float _Factor1;
            float _LightColor0;
            fixed4 _MainColor;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);
                float3 dir2 = v.normal;
                float3 dir = normalize(v.vertex.xyz);
                dir = lerp(dir,dir2,_Factor1);
                dir = mul((float3x3)UNITY_MATRIX_IT_MV , dir);
                float2 offset = TransformViewToProjection(dir.xy);
                offset = normalize(offset);
                o.pos.xy += offset * o.pos.z *_Outline1;
                o.lightDir = ObjSpaceLightDir(v.vertex);
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float3 n = normalize(i.normal);
                float diff = max(0,dot(n,i.lightDir));
                diff = (diff + 1) /2;
                diff = smoothstep(0,1,diff);
                fixed4 col = diff * _LightColor0 * _MainColor;
                return col ;
            }
            ENDCG
        }

        //  Pass
        // {
        //      Tags{"LightMode" = "Always"}
        //    Cull Back  
        //    ZWrite On   
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "UnityCG.cginc"
     
        //     struct v2f
        //     {    
        //         float4 pos : SV_POSITION;
        //     };
        //     float _Outline1;
        //     float _Factor1;

        //     v2f vert (appdata_full v)
        //     {
        //         v2f o;
        //         o.pos = UnityObjectToClipPos( v.vertex);
        //         float3 dir2 = v.normal;
        //         float3 dir = normalize(v.vertex.xyz);
        //         dir = lerp(dir,dir2,_Factor1);
        //         dir = mul((float3x3)UNITY_MATRIX_IT_MV , dir);
        //         float2 offset = TransformViewToProjection(dir.xy);
        //         offset = normalize(offset);
        //         o.pos.xy += offset * o.pos.z *_Outline1;
        //         return o;
        //     }

        //     fixed4 frag (v2f i) :COLOR
        //     {
        //         return (1,1,1,1) ;
        //     }
        //     ENDCG
        // }

        // Pass
        // {
        //      Tags{"LightMode" = "Always"}
        //    Cull Front 
        //    ZWrite Off  
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "UnityCG.cginc"
     
        //     struct v2f
        //     {    
        //         float4 pos : SV_POSITION;
        //     };
        //     float _Outline2;
        //     float _Factor2;

        //     v2f vert (appdata_full v)
        //     {
        //         v2f o;
        //         o.pos = UnityObjectToClipPos( v.vertex);
        //         float3 dir2 = v.normal;
        //         float3 dir = normalize(v.vertex.xyz);
        //         dir = lerp(dir,dir2,_Factor2);
        //         dir = mul((float3x3)UNITY_MATRIX_IT_MV , dir);
        //         float2 offset = TransformViewToProjection(dir.xy);
        //         offset = normalize(offset);
        //         o.pos.xy += offset * o.pos.z *_Outline2;
        //         return o;
        //     }

        //     fixed4 frag (v2f i) :COLOR
        //     {
        //         return (0,0,0,1) ;
        //     }
        //     ENDCG
        // }

        

        }

        // pass
        // {
        //     Tags{"LightMode" = "Always"}
        //  //   Cull Front 
        //  //   ZWrite On 
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag 
        //     #include "UnityCG.cginc"
        //     float4 _LightColor0;
        //     struct v2f
        //     {
        //         float4 pos : SV_POSITION;
        //         float3 lightDir : TEXCOORD;
        //         float3 viewDir : TEXCOORD1;
        //         float3 normal : NORMAL;
        //     };

        //     v2f vert (appdata_full v)
        //     {
        //         v2f o ;
        //         o.pos = UnityObjectToClipPos(v.vertex);
        //         o.lightDir = ObjSpaceLightDir(v.vertex);
        //         o.viewDir = ObjSpaceViewDir(v.vertex);
        //         o.normal = v.normal;
        //         return o ;
        //     }

        //     fixed4 frag(v2f i) : COLOR
        //     {
        //         float Nort =saturate(dot(i.lightDir , i.normal));
        //         float4 diff = Nort * _LightColor0;
        //         return diff;
        //     }
        //     ENDCG
        // }
        FallBack "Diffuse"
    }
    

