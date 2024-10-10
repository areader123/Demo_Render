using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace LcLgame
{
    [ExecuteAlways]
public abstract class RendererFeatureBase : MonoBehaviour
{
    public abstract void Create();
    public abstract void AddRenderPasses(ScriptableRenderer renderer);
    public virtual void Dispose()
    {
    }

    public virtual bool RenderPreView()
    {
        return false;
    }
    //以下两个自动函数将renderfeature加入到渲染管线的事件中
    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += BeginCameraRendering;
        Create();
    }
    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= BeginCameraRendering;
        Dispose();
    }
    //将pass加入renderer
    private void BeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        CameraType cameraType = camera.cameraType;
        if (!RenderPreView() && cameraType == CameraType.Preview)
        {
            return;
        }
        ScriptableRenderer renderer = camera.GetUniversalAdditionalCameraData().scriptableRenderer;
        AddRenderPasses(renderer);
    }

    //清理
    private void OnValidate()
    {
        Dispose();
        Create();
    }
}

}
