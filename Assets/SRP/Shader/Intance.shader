Shader "Unlit/Intance"
{
    Properties
    {
        _BaseColor ("Color", Color) = (0,0,0,1)
    }
    SubShader
    {
           // HLSLINCLUDE
            //#pragma multi_compile_instancing
          
           
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ConstantBuffer的名称必须是Unity SRP Batcher规定的名称
           // CBUFFER_START(UnityPerMaterial)
           // float4 _BaseColor;
           // CBUFFER_END


        // 为了支持GPU Instancing，使用以下方式声明一个cbuffer数组

        //  UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        //      UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)
        //  UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)


        // //顶点输入结构体
        // struct Attributes{
        //     float3 posOS : POSITION;
        //     UNITY_VERTEX_INPUT_INSTANCE_ID//cbuffer数组下标instanceID
        // };

        // struct Varing{
        //     float4 posCS : SV_POSITION;
        //     UNITY_VERTEX_INPUT_INSTANCE_ID///cbuffer数组下标instanceID
        // };

        //ENDHLSL


        pass{
            Tags { "RenderType" = " Opaque" " RenderPipeline" = "UniversalPipeline" }
        HLSLPROGRAM
            //#include "Assets/SRP/ShaderLibriry/Common.hlsl"
            #pragma multi_compile_instancing
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #include "Assets/SRP/Shader/UnlitPass.hlsl"
            // Varing UnlitPassVertex(Attributes input){
            //     Varing output;
            //     UNITY_SETUP_INSTANCE_ID(input);
            //     UNITY_TRANSFER_INSTANCE_ID(input,output);
                
            //     //output.posCS = TransformObjectToHClip(input.posOS);


            //     float3 posWS = TransformObjectToWorld(input.posOS);
            //     output.posCS = TransformWorldToHClip(posWS);
            //     return output;
            // }

            // float4 UnlitPassFragment(Varing input) : SV_Target { 
            //     UNITY_SETUP_INSTANCE_ID(input);
            //     // half4(0,0,0,1);
            // return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
            // //return half4(0,0,0,1);
            // }

        ENDHLSL
       }
    }
}
