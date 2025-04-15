using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{ 
    [Serializable, VolumeComponentMenu("Custom/Blur")]
    public class Blur : CustomVolumeComponent
    {
        [Tooltip("模糊偏移量")]
        public FloatParameter blurRadius = new FloatParameter(2, true);

        public override int Iteration => base.Iteration * 2;

        protected override void SetMaterialData()
        {
            m_Material.SetFloat("_Offset", blurRadius.value);
        }

        public override void Render(CommandBuffer cmd, ref RenderingData renderingData, 
            RenderTargetIdentifier source, RenderTargetIdentifier destination)
        {
            if (m_Material)
            {
                SetMaterialData();
                RenderTargetIdentifier cameraColorTarget = renderingData.cameraData.renderer.cameraColorTarget;
                var descriptor = renderingData.cameraData.cameraTargetDescriptor;
                descriptor.msaaSamples = 1;
                descriptor.depthBufferBits = 0;
                //需要多次渲染时如果遇到source或destination为有MSAA的渲染目标时则需要创建临时RT避免ResolveAA
                if (source == cameraColorTarget) 
                {
                    int tempRT = Shader.PropertyToID("_TempRTForSource");
                    cmd.GetTemporaryRT(tempRT, descriptor);
                    cmd.Blit(source, tempRT, m_Material, 0);
                    cmd.Blit(tempRT, destination, m_Material, 1);
                    for (int i = 1; i < m_Iteration.value; i++)
                    {
                        cmd.Blit(destination, tempRT, m_Material, 0);
                        cmd.Blit(tempRT, destination, m_Material, 1);
                    }
                    cmd.ReleaseTemporaryRT(tempRT);
                }
                else if (destination == cameraColorTarget) 
                {
                    int tempRT = Shader.PropertyToID("_TempRTForDestination");
                    cmd.GetTemporaryRT(tempRT, descriptor);
                    for (int i = 0; i < m_Iteration.value - 1; i++)
                    {
                        cmd.Blit(source, tempRT, m_Material, 0);
                        cmd.Blit(tempRT, source, m_Material, 1);
                    }
                    cmd.Blit(source, tempRT, m_Material, 0);
                    cmd.Blit(tempRT, destination, m_Material, 1);
                    cmd.ReleaseTemporaryRT(tempRT);
                }
                else
                {
                    for (int i = 0; i < m_Iteration.value; i++)
                    {
                        cmd.Blit(source, destination, m_Material, 0);
                        cmd.Blit(destination, source, m_Material, 1);
                    }
                }
            }
        }
    }
}

