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
        /// <summary> Ҫ���������Զ�������Volume </summary>
        public VolumeProfile m_VolumeProfile;
        /// <summary> ��������ScreenMesh��Shader </summary>
        public Shader m_BlitShader;

        // ��ͬ������render pass
        private CustomVolumeRenderPass m_AfterRendereringOpaque;
        private CustomVolumeRenderPass m_BeforeRenderingPostProcessing;
        private CustomVolumeRenderPass m_AfterRenderingPostProcessing;

        /// <summary> �����Զ����VolumeComponent </summary>
        private List<CustomVolumeComponent> m_AllCustomVolumeComponents;
        /// <summary> ��������ScreenMesh�Ĳ��� </summary>
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
            // ��ȡ�����Զ����VolumeComponent
            m_AllCustomVolumeComponents = m_VolumeProfile.components
                    .Where(t => t.GetType().IsSubclassOf(typeof(CustomVolumeComponent)))
                    .Select(t => (CustomVolumeComponent)t)
                    .ToList();
            // ��ʼ����ͬ������Render Pass
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
            if (m_VolumeProfile && m_BlitMaterial && renderingData.cameraData.postProcessEnabled) // VolumeProfile��Ϊ�ղ�������������˺���ѡ��
            {
                // �鿴ÿ���������Ƿ��м���ĺ���������оͲ���
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
