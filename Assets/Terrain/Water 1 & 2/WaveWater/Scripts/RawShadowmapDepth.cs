using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class RawShadowmapDepth : MonoBehaviour
{
    RenderTexture m_ShadowmapCopy;

    CommandBuffer cb;

    void OnEnable()
    {
        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        m_ShadowmapCopy = new RenderTexture(1024, 1024, 0);
        if (cb == null)
        {
            cb = new CommandBuffer();
        }
        else
        {
            cb.Clear();
        }

        // Change shadow sampling mode for m_Light's shadowmap.
        cb.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);

        // The shadowmap values can now be sampled normally - copy it to a different render texture.
        cb.Blit(shadowmap, new RenderTargetIdentifier(m_ShadowmapCopy));

        // Execute after the shadowmap has been filled.
        GetComponent<Light>().AddCommandBuffer(LightEvent.AfterShadowMap, cb);

        // Sampling mode is restored automatically after this command buffer completes, so shadows will render normally.

        Shader.SetGlobalTexture("_MainDirectionalShadowMap", m_ShadowmapCopy);
    }
}

