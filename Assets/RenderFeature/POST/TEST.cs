using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TEST : ScriptableRendererFeature
{

    
    public Material material = null;
    public float a = 0.1f;

    public RenderPassEvent  renderPassEvent = RenderPassEvent.AfterRenderingTransparents;

    public Shader thresholdShader;
    
    
    private ThresholdRenderPass m_ScriptablePass;
    
    class ThresholdRenderPass : ScriptableRenderPass
    {
        public Material material;
        public float a;
        public Voloum mvc;
        // This method is called before executing the render pass.
        // It can be used to configure render targ to the active camera render target.
        // You should never call CommandBuffer.Setets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will renderRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            RenderTextureDescriptor Rd = new RenderTextureDescriptor(Camera.main.pixelWidth,Camera.main.pixelHeight,RenderTextureFormat.Default,0); 
            RenderTexture tex = new RenderTexture(Rd);//新建RT

            RenderTargetIdentifier cameraColorTexture = renderingData.cameraData.renderer.cameraColorTarget;

            
            var stack = VolumeManager.instance.stack;
            mvc = stack.GetComponent<Voloum>();
          
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.name = "test pass";//这里可以在FrameDebugger里看到我们pass的名字
            
            //material.SetColor("_Color",mvc.cp.value);
            
            cmd.Blit(cameraColorTexture, tex,material);//对相机里的画面进行一些操作
            cmd.Blit(tex, cameraColorTexture);//将结果写回相机
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }


    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new ThresholdRenderPass();
        this.name = "Threshold";

        m_ScriptablePass.material = material;
        m_ScriptablePass.renderPassEvent = renderPassEvent;
        m_ScriptablePass.a = a;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


