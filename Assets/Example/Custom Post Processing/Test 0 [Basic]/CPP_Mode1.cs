using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    [ExecuteInEditMode]
    public class CPP_Mode1 : MonoBehaviour //��ʽһ:ͨ��RenderPipelineManager���¼�����RenderPass
    {
        public Material m_Material;

        private CustomRenderPass m_RenderPass;

        private void OnEnable()
        {
            if (m_Material)
            {
                if (m_RenderPass == null)
                    m_RenderPass = new CustomRenderPass(m_Material);
                // Subscribe the OnBeginCamera method to the beginCameraRendering event.
                RenderPipelineManager.beginCameraRendering += OnBeginCamera; //beginCameraRendering�Ĳ���λ���ǲ�͸��������Ⱦ֮��
            }
        }

        private void OnDisable()
        {
            if (m_Material)
                RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
        }

        private void OnBeginCamera(ScriptableRenderContext context, Camera cam)
        {
            // Use the EnqueuePass method to inject a custom render pass
            cam.GetUniversalAdditionalCameraData().scriptableRenderer.EnqueuePass(m_RenderPass);
        }

        class CustomRenderPass : ScriptableRenderPass
        {
            private Material m_Material;
            private int m_TempID = Shader.PropertyToID("_Temp");
            ProfilingSampler m_ProfilingSampler = new ProfilingSampler("CustomPostProcessing/Mode1");

            public CustomRenderPass(Material material)
            {
                m_Material = material;
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                cmd.GetTemporaryRT(m_TempID, renderingData.cameraData.cameraTargetDescriptor); //���ﲻ�ر�MSAA
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get("CPP_Mode1");
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    RenderTargetIdentifier cameraTargetHandle = renderingData.cameraData.renderer.cameraColorTarget;
                    Blit(cmd, cameraTargetHandle, m_TempID, m_Material);
                    Blit(cmd, m_TempID, cameraTargetHandle);
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(m_TempID);
            }
        }
    }
}

