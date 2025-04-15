using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    public class CustomVolumeRendererFeature : ScriptableRendererFeature
    {
        /// <summary> 要加入所有自定义后处理的Volume </summary>
        public VolumeProfile m_VolumeProfile;
        /// <summary> 用来绘制ScreenMesh的Shader </summary>
        public Shader m_BlitShader;

        // 不同插入点的render pass
        private CustomVolumeRenderPass m_AfterRendereringOpaque;
        private CustomVolumeRenderPass m_BeforeRenderingPostProcessing;
        private CustomVolumeRenderPass m_AfterRenderingPostProcessing;

        /// <summary> 所有自定义的VolumeComponent </summary>
        private List<CustomVolumeComponent> m_AllCustomVolumeComponents;
        /// <summary> 用来绘制ScreenMesh的材质 </summary>
        private Material m_BlitMaterial;

        public override void Create()
        {
            if (!m_VolumeProfile)
                return;
            if (m_BlitShader)
            {
                if (m_BlitMaterial == null || m_BlitMaterial.shader != m_BlitShader)
                    m_BlitMaterial = CoreUtils.CreateEngineMaterial(m_BlitShader);
            }
            if (!m_BlitMaterial)
                return;
            // 获取所有自定义的VolumeComponent
            m_AllCustomVolumeComponents = m_VolumeProfile.components
                    .Where(t => t.GetType().IsSubclassOf(typeof(CustomVolumeComponent)))
                    .Select(t => (CustomVolumeComponent)t)
                    .ToList();
            // 初始化不同插入点的Render Pass
            var afterOpaqueAndSkyComponents = m_AllCustomVolumeComponents
                .Where(c => c.m_InjectionPoint.value == InjectionPoint.BeforeRenderingTransparents)
                .ToList();
            m_AfterRendereringOpaque = new CustomVolumeRenderPass("Custom PostProcess After Opaque And Sky", afterOpaqueAndSkyComponents);
            m_AfterRendereringOpaque.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
            var beforePostProcessComponents = m_AllCustomVolumeComponents
                .Where(c => c.m_InjectionPoint.value == InjectionPoint.BeforeRenderingPostProcessing)
                .ToList();
            m_BeforeRenderingPostProcessing = new CustomVolumeRenderPass("Custom PostProcess Before PostProcess", beforePostProcessComponents);
            m_BeforeRenderingPostProcessing.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            var afterPostProcessComponents = m_AllCustomVolumeComponents
                .Where(c => c.m_InjectionPoint.value == InjectionPoint.AfterRenderingPostProcessing)
                .ToList();
            m_AfterRenderingPostProcessing = new CustomVolumeRenderPass("Custom PostProcess After PostProcess", afterPostProcessComponents);
            m_AfterRenderingPostProcessing.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (m_VolumeProfile && m_BlitMaterial && renderingData.cameraData.postProcessEnabled) // VolumeProfile不为空并且摄像机开启了后处理选项
            {
                // 查看每个周期中是否有激活的后处理组件，有就插入
                if (m_AfterRendereringOpaque.SetupComponents(m_BlitMaterial))
                    renderer.EnqueuePass(m_AfterRendereringOpaque);
                if (m_BeforeRenderingPostProcessing.SetupComponents(m_BlitMaterial))
                    renderer.EnqueuePass(m_BeforeRenderingPostProcessing);
                if (m_AfterRenderingPostProcessing.SetupComponents(m_BlitMaterial))
                    renderer.EnqueuePass(m_AfterRenderingPostProcessing);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing && m_AllCustomVolumeComponents != null)
            {
                foreach (var item in m_AllCustomVolumeComponents)
                    item.Dispose();
            }
            if (disposing && m_BlitMaterial) 
            {
                CoreUtils.Destroy(m_BlitMaterial);
            }
        }
    }
}
