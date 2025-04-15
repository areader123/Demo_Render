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
        /// <summary> 命令缓冲区的标签 </summary>
        private string m_Tag;
        /// <summary> 当前结点所有自定义后处理组件 </summary>
        private List<CustomVolumeComponent> m_VolumeComponents;
        /// <summary> 被激活的组件列表 </summary>
        private List<CustomVolumeComponent> m_ActiveVolumeComponents;
        /// <summary> 用来绘制ScreenMesh的材质 </summary>
        private Material m_BlitMaterial;

        private int m_TempRT0; // 临时RT0
        private int m_TempRT1; // 临时RT1

        public CustomVolumeRenderPass(string tag, List<CustomVolumeComponent> volumeComponents)
        {
            m_Tag = tag;
            m_VolumeComponents = volumeComponents;
            m_ActiveVolumeComponents = new List<CustomVolumeComponent>();

            m_TempRT0 = Shader.PropertyToID("_TemporaryRenderTexture0");
            m_TempRT1 = Shader.PropertyToID("_TemporaryRenderTexture1");
        }

        /// <summary> 初始化后处理组件 </summary>
        /// <returns> 是否存在有效组件 </returns>
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

        // 渲染逻辑
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get(m_Tag);

            // 获取屏幕RT参数
            var source = renderingData.cameraData.renderer.cameraColorTarget; //我们经常用的是这个，但是colorAttachment
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.depthBufferBits = 0;
            // 初始化临时RT           
            cmd.GetTemporaryRT(m_TempRT0, descriptor);
            bool rt1Used = false;
            // 执行每个组件的Render方法
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
                RenderTargetIdentifier from = source, to = m_TempRT0; //第一步直接用摄像机目标
                for (int i = 0; i < m_ActiveVolumeComponents.Count; i++)
                {
                    if (i == m_ActiveVolumeComponents.Count - 1 && m_ActiveVolumeComponents[i].Iteration == 1) //最后一步直接绘制到摄像机目标上
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
                    else if (i < m_ActiveVolumeComponents.Count - 1) //最后一步之前都Swap
                    {
                        CoreUtils.Swap(ref from, ref to);
                    }
                }
                if (to != source) //最后一步可能涉及到多次Blit，此时需要把结果绘制到摄像机目标上
                {
                    cmd.SetRenderTarget(source);
                    cmd.SetGlobalTexture("_BlitTex", to);
                    cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                    cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, m_BlitMaterial);
                }
            }
            // 调用
            context.ExecuteCommandBuffer(cmd);
            // 释放
            cmd.ReleaseTemporaryRT(m_TempRT0);
            if (rt1Used)
                cmd.ReleaseTemporaryRT(m_TempRT1);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }
}