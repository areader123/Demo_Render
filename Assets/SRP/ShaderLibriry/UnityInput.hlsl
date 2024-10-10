#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED


// 声明用于SRP Batcher的ConstantBuffer 名称和结构体成员顺序必须是Batcher规定
CBUFFER_START(UnityPerDraw)
    float4x4 unity_ObjectToWorld;
    float4x4 unity_WorldToObject;
    float4 unity_LODFade;
    real4 unity_WorldTransformParams; // 根据目标平台决定是float4 or half4
CBUFFER_END

//声明想从CPU 获取的数据
float4x4 unity_MatrixVP;//VP矩阵
float4x4 unity_MatrixV;//V矩阵
float4x4 glstate_matrix_projection;

#endif