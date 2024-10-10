Shader "Unlit/Outline 1"
{
    Properties
    { 
		// 描边强度
        _OutlinePower("line power",Range(0,0.2)) = 0.05
        // 描边颜色
        _LineColor("lineColor",Color)=(1,1,1,1)


        [Space(50)]
        _Outline1("outline1",Range(0,1)) = 0.02
       
         _Factor1("Factor1",Range(0,1)) = 0.5
        
         _MainColor("Color" , Color) = (1,1,1,1)

    }
    HLSLINCLUDE

    #pragma vertex vert
     #pragma fragment frag
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
           





    CBUFFER_START(UnityPerMaterial)
             //描边强度
    float _OutlinePower;
            //描边颜色
    float4 _LineColor;


    float _Outline1;
    float _Factor1;
           
    half4 _MainColor;

    CBUFFER_END

    ENDHLSL
    SubShader
    {
        LOD 100

       pass{
            Name"Outline2"
            Tags{  "Queue"="Transparent" "RenderType"="Transparent" " RenderPipeline" = "UniversalPipeline" "LightMode"="outline2"}
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
      
            Offset [_OffsetFactor], [_OffsetUnits]

            HLSLPROGRAM
            struct a2v{
                float3 vertex : POSITION;
                float3 normal :NORMAL;
            };

            
            struct v2f
            {    
                float4 pos : SV_POSITION;
                float3 lightDir : TEXCOORD;
                float3 viewDir : TEXCOORD1;
                float3 normal : NORMAL;
            };
           

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip( v.vertex);
                float3 dir2 = v.normal;
                float3 dir = normalize(v.vertex.xyz);
                dir = lerp(dir,dir2,_Factor1);
                dir = mul((float3x3)UNITY_MATRIX_IT_MV , dir);
                float2 offset = mul((float2x2)UNITY_MATRIX_P,dir.xy);
                offset = normalize(offset);
                o.pos.xy += offset * o.pos.z *_Outline1;
                
                
                o.normal = v.normal;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {   
                
              
                half4 col =  _MainColor;
                return col ;
            }
        





            // v2f vert (a2v v)
            // {
            //     v2f o;
            //     // //顶点沿着法线方向扩张
            //     // #ifdef _USE_SMOOTH_NORMAL_ON
            //     //     // 使用平滑的法线计算
            //     //     v.vertex.xyz += normalize(v.tangent.xyz) * _OutlinePower;
            //     // #else
            //     //     // 使用自带的法线计算
            //     //     v.vertex.xyz += normalize(v.normal) * _OutlinePower * 0.7;
            //     // #endif
            //     // o.pos = TransformObjectToHClip(v.vertex);

            //     // 如果需要使描边线不随Camera距离变大而跟着变小，就需要变换到ndc空间
            //     float3 normalDir =  normalize(v.normal.xyz);
            //     float4 pos = TransformObjectToHClip(v.vertex);
            //     float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, normalDir);
            //     float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间
            //     pos.xy += _OutlinePower * ndcNormal.xy;
            //     o.vertex = pos;
            //     return o;
            // }
            // half4 frag (v2f i) : SV_Target
            // {
            //     return _LineColor;
            // }
            ENDHLSL
        }
    }
}
