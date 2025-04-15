using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    public class CPP_Mode2 : ScriptableRendererFeature //��ʽ��:ͨ��RendererFeature����RenderPass
    {
        class CustomRenderPass : ScriptableRenderPass
        {
            private Material m_Material;
            RenderTargetIdentifier m_Source;
            //int m_TempID = Shader.PropertyToID("_Temp");
            ProfilingSampler m_ProfilingSampler = new ProfilingSampler("CustomPostProcessing/Mode2");

            public CustomRenderPass(Material material) 
            {
                m_Material = material;
            }

            public void Setup(RenderTargetIdentifier source)
            {
                m_Source = source;
            }

            //public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            //{
            //    var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            //    descriptor.msaaSamples = 1;
            //    descriptor.depthBufferBits = 0;
            //    cmd.GetTemporaryRT(m_TempID, descriptor); //����ر�MSAA
            //}

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get("CPP_Mode2");
                //��ProfilingScope�Ϳ�����FrameDebug�Ͽ��������������Ⱦ
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    //Blit(cmd, m_Source, m_TempID, m_Material);
                    //Blit(cmd, m_TempID, m_Source);
                    //URP��ò������ͬһRTͬʱ��Ϊsource��destination�Ĳ���
                    Blit(cmd, m_Source, m_Source, m_Material);
                }
                //ִ��
                context.ExecuteCommandBuffer(cmd);
                //����
                CommandBufferPool.Release(cmd);
            }

            //public override void OnCameraCleanup(CommandBuffer cmd)
            //{
            //    cmd.ReleaseTemporaryRT(m_TempID);
            //}
        }

        public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Material m_Material;
        private CustomRenderPass m_ScriptablePass;

        // �ڴ��������н��г�ʼ��
        public override void Create()
        {
            if (m_Material) 
            {
                m_ScriptablePass = new CustomRenderPass(m_Material);
                m_ScriptablePass.renderPassEvent = m_RenderPassEvent;
            }
        }

        // ���ò����RenderPass
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game)
            {
                if (m_Material)
                {
                    m_ScriptablePass.Setup(renderer.cameraColorTarget);
                    renderer.EnqueuePass(m_ScriptablePass);
                }
            }
        }
    }
}



