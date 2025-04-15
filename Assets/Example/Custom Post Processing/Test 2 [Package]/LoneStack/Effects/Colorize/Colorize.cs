using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LoneStack;

[System.Serializable]
public class ColorizeSettings : LSEffectSettings
{
    [ColorUsage(false, true)]
    public Color tint = new Color(.2f, .8f, .5f);
    [Range(0f, 5f)]
    public float contrast = .5f;
}

[LSEffectPath("Builtin/Colorize")]
[AlwaysIncludeShader("Hidden/Colorize")]
public class Colorize : LSEffect<ColorizeSettings>
{
    public override float Blend { set => mat.SetFloat(_Blend, value); }

    Material mat;

    static readonly int _Tint = Shader.PropertyToID("_Tint");
    static readonly int _Contrast = Shader.PropertyToID("_Contrast");

    protected override void Awake()
    {
        mat = new Material(Shader.Find("Hidden/Colorize"));
    }

    public override void EnqueueToBuffer(CommandBuffer cmdBuffer, LSContext context, ref RenderingData renderingData)
    {
        mat.SetColor(_Tint, settings.tint);
        mat.SetFloat(_Contrast, settings.contrast);
        cmdBuffer.Blit(context.source, context.destination, mat, 0);
    }
}
