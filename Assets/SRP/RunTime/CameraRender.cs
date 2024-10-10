using UnityEditor.PackageManager.UI;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRender{
    private const string bufferName = "Render Camera";
    private static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    private CommandBuffer buffer = new CommandBuffer{
        name = bufferName
    };
    private ScriptableRenderContext context;
    private Camera  camera;
    private CullingResults  cullingResults;

    public void Render (ScriptableRenderContext context,Camera camera) {
        this.context =  context;
        this.camera = camera;

        PrepareBuffer();
        // 绘制UI可能会绘制多余几何体 所以在剔除前进行
        PrepareForSceneWindow();

        if (!Cull())
            return;
        
        Setup();
        DrawVisibleGeometry();
        DrawUnsupportedShaders();
        DrawGizmos();
        Submit();
    }

    bool Cull(){
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p)) {
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }

    void Setup(){
        context.SetupCameraProperties(camera);
        CameraClearFlags flags = camera.clearFlags;
        buffer.ClearRenderTarget(
            flags <= CameraClearFlags.Depth,
            flags == CameraClearFlags.Color,
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear
        );
        buffer.BeginSample(SampleName);
         ExecuteBuffer();


    }

    void ExecuteBuffer(){
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void Submit(){
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }

    void DrawVisibleGeometry(){
        //不透明
        var sortingSetting = new SortingSettings(camera){
            criteria  = SortingCriteria.CommonOpaque
        };//不透明绘制规则
        var drawingSetting =  new DrawingSettings(unlitShaderTagId,sortingSetting);
        var filteringSetting = new  FilteringSettings(RenderQueueRange.opaque);

        context.DrawRenderers(cullingResults,ref drawingSetting,ref filteringSetting);
        
        // 天空盒
        context.DrawSkybox(camera);

        //绘制透明
        sortingSetting.criteria = SortingCriteria.CommonTransparent;
        drawingSetting.sortingSettings = sortingSetting;
        filteringSetting.renderQueueRange = RenderQueueRange.transparent;

        context.DrawRenderers(cullingResults, ref drawingSetting, ref filteringSetting);
    }
}
