#ifndef CUSTOM_UNITY_PASS_INCLUDED
#define CUSTOM_UNITY_PASS_INCLUDED


#include "Assets/SRP/ShaderLibriry/Common.hlsl"

// 声明想从CPU（Property）中获取的数据，Property用_开头

// 声明ConstantBuffer 使用宏支持不同平台


// ConstantBuffer的名称必须是Unity SRP Batcher规定的名称
//CBUFFER_START(UnityPerMaterial)
 //   float4 _BaseColor;
//CBUFFER_END


// 为了支持GPU Instancing，使用以下方式声明一个cbuffer数组

 UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)
 UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)



//顶点输入结构体
struct Attributes{
    float3 posOS : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID//cbuffer数组下标instanceID
};

struct Varing{
    float4 posCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID///cbuffer数组下标instanceID
};

Varing UnlitPassVertex(Attributes input){
    Varing output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    float3 posWS = TransformObjectToWorld(input.posOS);
    output.posCS = TransformWorldToHClip(posWS);
    //output.posCS = TransformObjectToHClip(input.posOS);
    return output;
}

float4 UnlitPassFragment(Varing input) : SV_Target { 
    UNITY_SETUP_INSTANCE_ID(input);
    // half4(0,0,0,1);
  return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor);
  //return half4(_BaseColor,1);
}
#endif