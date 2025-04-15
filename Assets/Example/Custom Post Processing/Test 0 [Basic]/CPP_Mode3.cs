using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    public class CPP_Mode3 : ScriptableRendererFeature //方式三:通过RendererFeature插入RenderPass，并实现和Volume系统的配合
    {
        class CustomRenderPass : ScriptableRenderPass
        {
            CPPMode3VolumeComponent volumeComponent;
            Material material;         
            RenderTargetIdentifier source;
            int tempRT = Shader.PropertyToID("_TempRT");

            public CustomRenderPass(Material material)
            {
                this.material = material;
            }

            public void Setup(in RenderTargetIdentifier source)
            {
                this.source = source;
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                // 获取后处理组件中的该组件
                var stack = VolumeManager.instance.stack;
                volumeComponent = stack.GetComponent<CPPMode3VolumeComponent>();
                if (volumeComponent == null || !volumeComponent.IsActive()) { return; }

                // 获取降采样的屏幕RT
                RenderTextureDescriptor cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                var w = cameraTextureDescriptor.width / volumeComponent.m_DownSample.value;
                var h = cameraTextureDescriptor.height / volumeComponent.m_DownSample.value;
                cmd.GetTemporaryRT(tempRT, w, h, 0);
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                // 如果摄像机关闭了后处理选项
                if (!renderingData.cameraData.postProcessEnabled) return;
                // 如果后处理组件没有或者关闭了
                if (volumeComponent == null || !volumeComponent.IsActive()) { return; }

                // 模糊
                var cmd = CommandBufferPool.Get("CPP_Mode3");                    
                material.SetFloat("_Offset", volumeComponent.m_BlurRadius.value);
                for (int i = 0; i < volumeComponent.m_Iteration.value; i++)
                {
                    cmd.Blit(source, tempRT, material, 0);
                    cmd.Blit(tempRT, source, material, 1);
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(tempRT);
            }
        }

        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

        public Material material;

        private CustomRenderPass m_ScriptablePass;

        public override void Create()
        {
            m_ScriptablePass = new CustomRenderPass(material);
            m_ScriptablePass.renderPassEvent = renderPassEvent;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (material != null) 
            {
                m_ScriptablePass.Setup(renderer.cameraColorTarget);
                renderer.EnqueuePass(m_ScriptablePass);
            }
        }
    }
}



