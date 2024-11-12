using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LcLgame;
using UnityEditor.ShaderGraph;


public class Water_Line : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material blitMaterial = null;
        //public int blitMaterialPassIndex = -1;
        //目标RenderTexture 
        public RenderTexture renderTexture = null;

    }
    public Settings settings = new Settings();
    private CustomPass blitPass;

    public override void Create()
    {
        blitPass = new CustomPass(name, settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.blitMaterial == null)
        {
            Debug.LogWarningFormat("丢失blit材质");
            return;
        }
        blitPass.renderPassEvent = settings.renderPassEvent;
        //blitPass.Setup(renderer.cameraDepthTarget);
        renderer.EnqueuePass(blitPass);
    }

    public class CustomPass : ScriptableRenderPass
{
    private Water_Line.Settings settings;
    string m_ProfilerTag;
    RenderTargetIdentifier source;

    static int downDepthTaxtureID = Shader.PropertyToID("_DownDepthTaxture");

    public CustomPass(string tag, Water_Line.Settings settings)
    {
        m_ProfilerTag = tag;
        this.settings = settings;
    }

    public void Setup(RenderTargetIdentifier src)
    {
        source = src;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer command = CommandBufferPool.Get(m_ProfilerTag);
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(renderingData.cameraData.camera.projectionMatrix,false);
        var vMatrix = projMatrix;
        var pMatrix =  renderingData.cameraData.camera.worldToCameraMatrix;
        settings.blitMaterial.SetMatrix("_InvP",pMatrix.inverse);
        settings.blitMaterial.SetMatrix("_InvV",vMatrix.inverse);
        command.Blit(source, settings.renderTexture, settings.blitMaterial);
        command.SetGlobalTexture(downDepthTaxtureID,settings.renderTexture);
        context.ExecuteCommandBuffer(command);
        CommandBufferPool.Release(command);
    }
}


}


