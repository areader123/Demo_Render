using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Outline : ScriptableRendererFeature
{
    
    public class SurfaceRenderSetting
    {
        //含有所需SpriteRenderer的prefab
        public SpriteRenderer RendererPrefab;
        private SpriteRenderer _rendererInstance;
        public SpriteRenderer RendererInstance
        {
            get
            {
                if (!_rendererInstance)
                {
                    if (RendererPrefab)
                    {
                        _rendererInstance = Object.Instantiate(RendererPrefab);
                    }
                }
                return _rendererInstance;
            }
        }
        //旋转偏移
        private Vector3 _rotationOffset = Vector3.right * 90;
        //渲染的Transform
        public Vector3 Position =  new Vector3(-16,-3,-23);
        public Quaternion Rotation = new Quaternion(90,0,0,0);
        public Vector3 Size = new Vector3(1,0,0);
        public void SetDataFromTransform(Transform transform)
        {
            Position = transform.position;
            Rotation = transform.rotation;
            Quaternion quaternion = Quaternion.Euler(_rotationOffset);
            //Rotation *= Quaternion.Inverse(Rotation) * quaternion * this.Rotation;
            Rotation *= quaternion;
            var scale = transform.lossyScale;
            Size = scale;
            Size.y = 0;
        }
    }

   
    class SurfaceOutlineRenderPass : ScriptableRenderPass
    {
        private SurfaceRenderSetting m_setting;
        private string name;
        public SurfaceOutlineRenderPass(SurfaceRenderSetting surfaceRenderSetting,RenderPassEvent renderPassEvent,string name)
        {
            this.m_setting = surfaceRenderSetting;
            this.renderPassEvent = renderPassEvent;
            this.name = name;
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
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
            if(!m_setting.RendererPrefab || Application.isPlaying) return;
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.name = name;
            var trans = m_setting.RendererInstance.transform;
            //得到原物体的scale
            trans.position = m_setting.Position;
            trans.rotation = m_setting.Rotation;

            //
            m_setting.RendererInstance.size = new Vector2(m_setting.Size.x,m_setting.Size.y);
            cmd.DrawRenderer(m_setting.RendererInstance,m_setting.RendererInstance.sharedMaterial);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
            

        
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }

    }
     public SurfaceRenderSetting surfaceRenderSetting;
    public RenderPassEvent firstEvnet = RenderPassEvent.AfterRenderingOpaques;
    public RenderPassEvent secondEvnet = RenderPassEvent.AfterRenderingSkybox;

    //外部决定是否渲染
    private bool shouldRender = false;


    List<SurfaceOutlineRenderPass> m_ScriptablePasses =new List<SurfaceOutlineRenderPass>(2);

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePasses.Clear();        
        var firstPass = new SurfaceOutlineRenderPass(surfaceRenderSetting,firstEvnet,"FirstName");
       m_ScriptablePasses.Add(firstPass);

       var secondPass = new SurfaceOutlineRenderPass(surfaceRenderSetting,secondEvnet,"SecondPass");
        m_ScriptablePasses.Add(secondPass);


        // Configures where the render pass should be injected.
        
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(m_ScriptablePasses == null || !shouldRender)
            return;
            foreach(var pass in m_ScriptablePasses) {
            renderer.EnqueuePass(pass);
            }
    }
}


