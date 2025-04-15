using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    public class CustomVolumeRenderPass : ScriptableRenderPass
    {
        /// <summary> ��������ı�ǩ </summary>
        private string m_Tag;
        /// <summary> ��ǰ��������Զ��������� </summary>
        private List<CustomVolumeComponent> m_VolumeComponents;
        /// <summary> �����������б� </summary>
        private List<CustomVolumeComponent> m_ActiveVolumeComponents;
        /// <summary> ��������ScreenMesh�Ĳ��� </summary>
        private Material m_BlitMaterial;

        private int m_TempRT0; // ��ʱRT0
        private int m_TempRT1; // ��ʱRT1

        public CustomVolumeRenderPass(string tag, List<CustomVolumeComponent> volumeComponents)
        {
            m_Tag = tag;
            m_VolumeComponents = volumeComponents;
            m_ActiveVolumeComponents = new List<CustomVolumeComponent>();

            m_TempRT0 = Shader.PropertyToID("_TemporaryRenderTexture0");
            m_TempRT1 = Shader.PropertyToID("_TemporaryRenderTexture1");
        }

        /// <summary> ��ʼ��������� </summary>
        /// <returns> �Ƿ������Ч��� </returns>
        public bool SetupComponents(Material blitMaterial)
        {
            m_BlitMaterial = blitMaterial;
            m_ActiveVolumeComponents.Clear();
            for (int i = 0; i < m_VolumeComponents.Count; i++)
            {
                m_VolumeComponents[i].Setup();
                if (m_VolumeComponents[i].CanUse()) 
                    m_ActiveVolumeComponents.Add(m_VolumeComponents[i]);
            }
            m_ActiveVolumeComponents.Sort((a, b) => { return a.m_OrderInPass.value.CompareTo(b.m_OrderInPass.value); });
            return m_ActiveVolumeComponents.Count != 0;
        }

        // ��Ⱦ�߼�
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get(m_Tag);

            // ��ȡ��ĻRT����
            var source = renderingData.cameraData.renderer.cameraColorTarget; //���Ǿ����õ������������colorAttachment
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.depthBufferBits = 0;
            // ��ʼ����ʱRT           
            cmd.GetTemporaryRT(m_TempRT0, descriptor);
            bool rt1Used = false;
            // ִ��ÿ�������Render����
            if (m_ActiveVolumeComponents.Count == 1)
            {
                RenderTargetIdentifier from = source, to = m_TempRT0;
                m_ActiveVolumeComponents[0].Render(cmd, ref renderingData, from, to);
                if (to != source) 
                {
                    //Blit(cmd, to, source);
                    cmd.SetRenderTarget(source);
                    cmd.SetGlobalTexture("_BlitTex", to);
                    cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                    cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, m_BlitMaterial);
                }
            } 
            else if (m_ActiveVolumeComponents.Count == 2) 
            {
                m_ActiveVolumeComponents[0].Render(cmd, ref renderingData, source, m_TempRT0);
                m_ActiveVolumeComponents[1].Render(cmd, ref renderingData, m_TempRT0, source);
            }
            else
            {
                cmd.GetTemporaryRT(m_TempRT1, descriptor);
                rt1Used = true;
                RenderTargetIdentifier from = source, to = m_TempRT0; //��һ��ֱ���������Ŀ��
                for (int i = 0; i < m_ActiveVolumeComponents.Count; i++)
                {
                    if (i == m_ActiveVolumeComponents.Count - 1 && m_ActiveVolumeComponents[i].Iteration == 1) //���һ��ֱ�ӻ��Ƶ������Ŀ����
                    {
                        from = to;
                        to = source;
                    }
                    CustomVolumeComponent component = m_ActiveVolumeComponents[i];
                    component.Render(cmd, ref renderingData, from, to);
                    if (from == source)
                    {
                        from = m_TempRT0;
                        to = m_TempRT1;
                    }
                    else if (i < m_ActiveVolumeComponents.Count - 1) //���һ��֮ǰ��Swap
                    {
                        CoreUtils.Swap(ref from, ref to);
                    }
                }
                if (to != source) //���һ�������漰�����Blit����ʱ��Ҫ�ѽ�����Ƶ������Ŀ����
                {
                    cmd.SetRenderTarget(source);
                    cmd.SetGlobalTexture("_BlitTex", to);
                    cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                    cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, m_BlitMaterial);
                }
            }
            // ����
            context.ExecuteCommandBuffer(cmd);
            // �ͷ�
            cmd.ReleaseTemporaryRT(m_TempRT0);
            if (rt1Used)
                cmd.ReleaseTemporaryRT(m_TempRT1);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }
}