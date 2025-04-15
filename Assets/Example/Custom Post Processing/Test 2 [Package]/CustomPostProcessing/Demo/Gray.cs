using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    [CreateAssetMenu(menuName = "CustomPostProcessing/Gray")]
    public class Gray : PostProcessingEffect
    {
        public override void Render(CommandBuffer cmd, ref RenderingData renderingData, PostProcessingRenderContext context)
        {
            base.Render(cmd, ref renderingData, context);

            context.BlitAndSwap(cmd, _material);
        }
    }
}
