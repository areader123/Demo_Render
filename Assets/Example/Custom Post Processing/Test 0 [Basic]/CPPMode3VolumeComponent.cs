using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{ 
    [VolumeComponentMenu("Custom/CPP_Mode3")]
    public class CPPMode3VolumeComponent : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("模糊降采样")]
        public ClampedIntParameter m_DownSample = new ClampedIntParameter(2, 1, 16);

        [Tooltip("模糊次数")]
        public ClampedIntParameter m_Iteration = new ClampedIntParameter(2, 0, 16);

        [Tooltip("模糊偏移量")]
        public FloatParameter m_BlurRadius = new FloatParameter(2);

        public bool IsActive() => m_Iteration.value > 0;

        public bool IsTileCompatible() => false;
    }
}

