using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LoneStack;

[System.Serializable]
public class RadialBlurSettings : LSEffectSettings
{
    [Range(0f, 2f)]
    public float intensity = .5f;
    [Range(1, 10)]
    public int iterations = 4;
    [Range(0f, 1f)]
    public float noise = .5f;
    [Range(-1f, 1f)]
    public float offset = .1f;
    [Range(.1f, 3f)]
    public float shape = .5f;
}

[LSEffectPath("Builtin/RadialBlur")]
[AlwaysIncludeShader("Hidden/RadialBlur")]
public class RadialBlur : LSEffect<RadialBlurSettings>
{
    public override float Blend { set => mat.SetFloat(_Blend, value); }

    Material mat;

    static readonly int _Rndm = Shader.PropertyToID("_Rndm");
    static readonly int _Intens = Shader.PropertyToID("_Intens");
    static readonly int _Noise = Shader.PropertyToID("_Noise");
    static readonly int _Offset = Shader.PropertyToID("_Offset");
    static readonly int _Shape = Shader.PropertyToID("_Shape");
    static readonly int _Step = Shader.PropertyToID("_Step");

    protected override void Awake()
    {
        mat = new Material(Shader.Find("Hidden/RadialBlur"));
    }

    public override void EnqueueToBuffer(CommandBuffer cmdBuffer, LSContext context, ref RenderingData renderingData)
    {
        mat.SetFloat(_Rndm, Random.value);
        mat.SetFloat(_Intens, settings.intensity);
        mat.SetFloat(_Noise, settings.noise);
        mat.SetFloat(_Offset, settings.offset);
        mat.SetFloat(_Shape, settings.shape);
        for (int i = 0; i < settings.iterations; i++)
        {
            if (i > 0) context.SwapSrcDst();
            mat.SetFloat(_Step, (i + 1) / (float)settings.iterations);
            cmdBuffer.Blit(context.source, context.destination, mat, 0);
        }
    }
}
