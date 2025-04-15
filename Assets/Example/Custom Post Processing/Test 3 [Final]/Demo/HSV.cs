using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    [Serializable, VolumeComponentMenu("Custom/HSV")]
    public class HSV : CustomVolumeComponent
    {
        public ClampedFloatParameter m_Brightness = new ClampedFloatParameter(0.5f, 0, 1, true);

        public ClampedFloatParameter m_Saturate = new ClampedFloatParameter(0.5f, 0, 1, true);

        public ClampedFloatParameter m_Contranst = new ClampedFloatParameter(0.5f, 0, 1, true);

        protected override void SetMaterialData()
        {
            m_Material.SetFloat("_Brightness", m_Brightness.value);
            m_Material.SetFloat("_Saturate", m_Saturate.value);
            m_Material.SetFloat("_Contranst", m_Contranst.value);
        }
    }
}
