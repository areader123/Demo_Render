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
        [Tooltip("ģ��������")]
        public ClampedIntParameter m_DownSample = new ClampedIntParameter(2, 1, 16);

        [Tooltip("ģ������")]
        public ClampedIntParameter m_Iteration = new ClampedIntParameter(2, 0, 16);

        [Tooltip("ģ��ƫ����")]
        public FloatParameter m_BlurRadius = new FloatParameter(2);

        public bool IsActive() => m_Iteration.value > 0;

        public bool IsTileCompatible() => false;
    }
}

