#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "UnityInput.hlsl"


// 将顶点从模型空间转到世界空间
 float3 TransformObjectToWorld (float3 posOS) {
    return mul(unity_ObjectToWorld, float4(posOS, 1.0)).xyz;
 }

// 将顶点从世界空间到齐次裁剪空间
float4 TransformWorldToHClip(float3 posWS) {
    return mul(unity_MatrixVP, float4(posWS, 1.0));
}

// 使用Unity提供的包的hlsl文件以更有效的方式代替上述函数
// 将包中的hlsl对于矩阵的变量名改为和新版Unity标准一样

 #define UNITY_MATRIX_I_M unity_WorldToObject
  #define UNITY_MATRIX_M unity_ObjectToWorld
  #define UNITY_MATRIX_V unity_MatrixV
  #define UNITY_MATRIX_VP unity_MatrixVP
  #define UNITY_MATRIX_P glstate_matrix_projection


 #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"// 需要在SpaceTransforms之前include
//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

#endif