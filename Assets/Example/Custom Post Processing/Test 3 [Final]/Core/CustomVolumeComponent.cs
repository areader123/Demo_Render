using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    /// <summary> 后处理插入位置 </summary>
    public enum InjectionPoint
    {
        /// <summary> 透明物体渲染之前 </summary>
        BeforeRenderingTransparents,
        /// <summary> 内置后处理之前 </summary>
        BeforeRenderingPostProcessing,
        /// <summary> 内置后处理之后 </summary>
        AfterRenderingPostProcessing
    }

    /// <summary> 插入位置的参数类 </summary>
    [Serializable]
    public sealed class InjectionPointParameter : VolumeParameter<InjectionPoint>
    { 
        public InjectionPointParameter(InjectionPoint value, bool overrideState = true) : base(value, overrideState) { } 
    }

    /// <summary> Shader的参数类 </summary>
    [Serializable]
    public sealed class ShaderParameter : VolumeParameter<Shader>
    {
        public ShaderParameter(Shader shader, bool overrideState = true) : base(shader, overrideState) { }
    }

    /// <summary> 自定义Volume组件 </summary>
    public abstract class CustomVolumeComponent : VolumeComponent, IPostProcessComponent, IDisposable
    {
        // VolumeComponent中的面板属性只能是所有继承了VolumeParameter的类型
        [Tooltip("插入位置")] 
        public InjectionPointParameter m_InjectionPoint = new InjectionPointParameter(InjectionPoint.BeforeRenderingPostProcessing);
        [Tooltip("执行顺序")] 
        public IntParameter m_OrderInPass = new IntParameter(0, true); // 在同一插入位置可能会有多个后处理组件，需要确定执行顺序
        [Tooltip("着色器")] 
        public ShaderParameter m_Shader = new ShaderParameter(null);
        [Tooltip("迭代次数")]
        public ClampedIntParameter m_Iteration = new ClampedIntParameter(1, 0, 16, true);

        /// <summary> 顺便通过迭代次数控制开关(因为VolumeComponent是dll中的，我们没法通过改编辑器脚本控制面板开关的功能) </summary>
        public virtual int Iteration { get { return m_Iteration.value; } }

        /// <summary> 根据Shader创建的材质 </summary>
        protected Material m_Material;

        /// <summary> 是否能被使用(首先材质要能被创建能出来，其次通过排序的值决定) </summary>
        public virtual bool CanUse() { return m_Material && m_Iteration.value > 0; }

        /// <summary> 准备工作(在RenderPass加入队列时调用) </summary>
        public virtual void Setup()
        {
            // 初始化材质
            if (m_Shader.value)
            {
                if (m_Material == null || m_Material.shader != m_Shader.value)
                    m_Material = CoreUtils.CreateEngineMaterial(m_Shader.value);
            }
        }

        /// <summary> 执行渲染(在RenderPass中Execute时调用) </summary>
        public virtual void Render(CommandBuffer cmd, ref RenderingData renderingData, 
            RenderTargetIdentifier source, RenderTargetIdentifier destination)
        {
            if (m_Material == null)
                return;
            SetMaterialData();
            cmd.Blit(source, destination, m_Material);
        }

        /// <summary> 设置材质数据 </summary>
        protected virtual void SetMaterialData() { }

        /// <summary> 资源释放 </summary>
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary> 资源释放 </summary>
        public virtual void Dispose(bool disposing)
        {
            if (m_Material)
                CoreUtils.Destroy(m_Material);
        }

        public bool IsActive() => active && CanUse();

        public bool IsTileCompatible() => false;
    }
}