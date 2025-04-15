using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    /// <summary> �������λ�� </summary>
    public enum InjectionPoint
    {
        /// <summary> ͸��������Ⱦ֮ǰ </summary>
        BeforeRenderingTransparents,
        /// <summary> ���ú���֮ǰ </summary>
        BeforeRenderingPostProcessing,
        /// <summary> ���ú���֮�� </summary>
        AfterRenderingPostProcessing
    }

    /// <summary> ����λ�õĲ����� </summary>
    [Serializable]
    public sealed class InjectionPointParameter : VolumeParameter<InjectionPoint>
    { 
        public InjectionPointParameter(InjectionPoint value, bool overrideState = true) : base(value, overrideState) { } 
    }

    /// <summary> Shader�Ĳ����� </summary>
    [Serializable]
    public sealed class ShaderParameter : VolumeParameter<Shader>
    {
        public ShaderParameter(Shader shader, bool overrideState = true) : base(shader, overrideState) { }
    }

    /// <summary> �Զ���Volume��� </summary>
    public abstract class CustomVolumeComponent : VolumeComponent, IPostProcessComponent, IDisposable
    {
        // VolumeComponent�е��������ֻ�������м̳���VolumeParameter������
        [Tooltip("����λ��")] 
        public InjectionPointParameter m_InjectionPoint = new InjectionPointParameter(InjectionPoint.BeforeRenderingPostProcessing);
        [Tooltip("ִ��˳��")] 
        public IntParameter m_OrderInPass = new IntParameter(0, true); // ��ͬһ����λ�ÿ��ܻ��ж�������������Ҫȷ��ִ��˳��
        [Tooltip("��ɫ��")] 
        public ShaderParameter m_Shader = new ShaderParameter(null);
        [Tooltip("��������")]
        public ClampedIntParameter m_Iteration = new ClampedIntParameter(1, 0, 16, true);

        /// <summary> ˳��ͨ�������������ƿ���(��ΪVolumeComponent��dll�еģ�����û��ͨ���ı༭���ű�������忪�صĹ���) </summary>
        public virtual int Iteration { get { return m_Iteration.value; } }

        /// <summary> ����Shader�����Ĳ��� </summary>
        protected Material m_Material;

        /// <summary> �Ƿ��ܱ�ʹ��(���Ȳ���Ҫ�ܱ������ܳ��������ͨ�������ֵ����) </summary>
        public virtual bool CanUse() { return m_Material && m_Iteration.value > 0; }

        /// <summary> ׼������(��RenderPass�������ʱ����) </summary>
        public virtual void Setup()
        {
            // ��ʼ������
            if (m_Shader.value)
            {
                if (m_Material == null || m_Material.shader != m_Shader.value)
                    m_Material = CoreUtils.CreateEngineMaterial(m_Shader.value);
            }
        }

        /// <summary> ִ����Ⱦ(��RenderPass��Executeʱ����) </summary>
        public virtual void Render(CommandBuffer cmd, ref RenderingData renderingData, 
            RenderTargetIdentifier source, RenderTargetIdentifier destination)
        {
            if (m_Material == null)
                return;
            SetMaterialData();
            cmd.Blit(source, destination, m_Material);
        }

        /// <summary> ���ò������� </summary>
        protected virtual void SetMaterialData() { }

        /// <summary> ��Դ�ͷ� </summary>
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary> ��Դ�ͷ� </summary>
        public virtual void Dispose(bool disposing)
        {
            if (m_Material)
                CoreUtils.Destroy(m_Material);
        }

        public bool IsActive() => active && CanUse();

        public bool IsTileCompatible() => false;
    }
}