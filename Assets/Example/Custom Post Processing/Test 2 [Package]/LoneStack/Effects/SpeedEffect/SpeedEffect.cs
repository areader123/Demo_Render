using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LoneStack;

[System.Serializable]
public class SpeedEffectSettings : LSEffectSettings
{
    [Header("Global")]
    public float speed = 8f;
    public float distortion = 1f;

    [Header("Stripes")]
    [Range(0f, 1f)]
    public float stripesIntensity = 1f;
    [ColorUsage(true, true)]
    public Color stripesColor = Color.white;
    public int stripesFrequency = 1;
    [Range(.1f, 15f)]
    public float stripesShape = 8f;
    [Range(-.25f, .25f)]
    public float stripesOffset = .08f;

    [Header("Fire")]
    [Range(0f, 1f)]
    public float fireIntensity = 1f;
    [ColorUsage(true, true)]
    public Color fireColor0 = new Color(.9f, .2f, 0);
    [ColorUsage(true, true)]
    public Color fireColor1 = new Color(.9f, .7f, 0);
    public int fireFrequency = 1;
    [Range(-.25f, .25f)]
    public float fireOffset = .05f;
}

[LSEffectPath("Builtin/SpeedEffect")]
[AlwaysIncludeShader("Hidden/SpeedEffect")]
public class SpeedEffect : LSEffect<SpeedEffectSettings>
{
    public override float Blend { set => mat.SetFloat(_Blend, value); }

    Material mat;

    static readonly int _Speed = Shader.PropertyToID("_Speed");
    static readonly int _Distortion = Shader.PropertyToID("_Distortion");

    static readonly int _StripesIntens = Shader.PropertyToID("_StripesIntens");
    static readonly int _StripesFreq = Shader.PropertyToID("_StripesFreq");
    static readonly int _StripesOffset = Shader.PropertyToID("_StripesOffset");
    static readonly int _StripesShape = Shader.PropertyToID("_StripesShape");
    static readonly int _StripesColor = Shader.PropertyToID("_StripesColor");

    static readonly int _FireIntens = Shader.PropertyToID("_FireIntens");
    static readonly int _FireFreq = Shader.PropertyToID("_FireFreq");
    static readonly int _FireOffset = Shader.PropertyToID("_FireOffset");
    static readonly int _FireColor0 = Shader.PropertyToID("_FireColor0");
    static readonly int _FireColor1 = Shader.PropertyToID("_FireColor1");

    protected override void Awake()
    {
        mat = new Material(Shader.Find("Hidden/SpeedEffect"));
    }

    public override void EnqueueToBuffer(CommandBuffer cmdBuffer, LSContext context, ref RenderingData renderingData)
    {
        mat.SetFloat(_Speed, settings.speed);
        mat.SetFloat(_Distortion, settings.distortion);

        mat.SetFloat(_StripesIntens, settings.stripesIntensity);
        mat.SetFloat(_StripesFreq, settings.stripesFrequency * 2f);
        mat.SetFloat(_StripesOffset, settings.stripesOffset);
        mat.SetFloat(_StripesShape, settings.stripesShape);
        mat.SetColor(_StripesColor, settings.stripesColor);

        mat.SetFloat(_FireIntens, settings.fireIntensity);
        mat.SetFloat(_FireFreq, settings.fireFrequency * 2f);
        mat.SetFloat(_FireOffset, settings.fireOffset);
        mat.SetColor(_FireColor0, settings.fireColor0);
        mat.SetColor(_FireColor1, settings.fireColor1);

        cmdBuffer.Blit(context.source, context.destination, mat, 0);
    }
}
