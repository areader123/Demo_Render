using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using LoneStack;

[System.Serializable]
public class VolumetricLightingSettings : LSEffectSettings
{
    [Range(0f, 2f), Tooltip("Brightness multiplier")] public float intensity = .5f;
    [Range(1, 100), Tooltip("Effect quality, at the cost of performance")] public int stepsCount = 50;
    [Min(1f), Tooltip("Radius of the effect around the camera")] public float distance = 5f;
    [Tooltip("Brightness multiplier per shadow cascade")] public Vector4 cascadeIntensity = new Vector4(.5f, .2f, .1f, .05f);
}

[LSEffectPath("Builtin/VolumetricLighting")]
[AlwaysIncludeShader("Hidden/VolumetricLighting")]
public class VolumetricLighting : LSEffect<VolumetricLightingSettings>
{
    public override float Blend { set => mat.SetFloat(_Blend, value * settings.intensity); }

    Material mat;

    static readonly int _CamPos = Shader.PropertyToID("_CamPos");
    static readonly int _CamFwd = Shader.PropertyToID("_CamFwd");
    static readonly int _CamUp = Shader.PropertyToID("_CamUp");
    static readonly int _CamRight = Shader.PropertyToID("_CamRight");

    static readonly int _Intens = Shader.PropertyToID("_Intens");
    static readonly int _StepCount = Shader.PropertyToID("_StepCount");
    static readonly int _Distance = Shader.PropertyToID("_Distance");

    protected override void Awake()
    {
        mat = new Material(Shader.Find("Hidden/VolumetricLighting"));
    }

    public override void EnqueueToBuffer(CommandBuffer cmdBuffer, LSContext context, ref RenderingData renderingData)
    {
        renderingData.cameraData.requiresDepthTexture = true;

        cmdBuffer.Blit(context.source, context.destination);

        mat.SetVector(_CamPos, renderingData.cameraData.camera.transform.position);
        float wRatio = renderingData.cameraData.camera.scaledPixelWidth / (float)renderingData.cameraData.camera.scaledPixelHeight;
        float fovScale = Mathf.Tan(Mathf.Deg2Rad * renderingData.cameraData.camera.fieldOfView * .5f);
        mat.SetVector(_CamFwd, renderingData.cameraData.camera.transform.forward);
        mat.SetVector(_CamUp, renderingData.cameraData.camera.transform.up * fovScale);
        mat.SetVector(_CamRight, renderingData.cameraData.camera.transform.right * wRatio * fovScale);

        mat.SetVector(_Intens, settings.cascadeIntensity);
        mat.SetInt(_StepCount, settings.stepsCount);
        mat.SetFloat(_Distance, settings.distance);

        cmdBuffer.Blit(context.source, context.destination, mat, 0);
    }
}
