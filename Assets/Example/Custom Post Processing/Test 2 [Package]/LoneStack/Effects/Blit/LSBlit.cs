using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LoneStack;

[System.Serializable]
public class LSBlitSettings : LSEffectSettings
{
    public Material material = null;
}

[LSEffectPath("Builtin/LSBlit")]
public class LSBlit : LSEffect<LSBlitSettings>
{
    public override float Blend { set { if (settings.material) settings.material.SetFloat(_Blend, value); } }

    protected override void Awake()
    {
    }

    public override void EnqueueToBuffer(CommandBuffer cmdBuffer, LSContext context, ref RenderingData renderingData)
    {
        if (settings.material)
            cmdBuffer.Blit(context.source, context.destination, settings.material, -1);
        else
            cmdBuffer.Blit(context.source, context.destination);
    }
}
