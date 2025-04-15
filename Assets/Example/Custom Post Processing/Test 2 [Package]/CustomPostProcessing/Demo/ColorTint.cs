using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    [CreateAssetMenu(menuName = "CustomPostProcessing/ColorTint")]
    public class ColorTint : PostProcessingEffect
    {
        [SerializeField]
        private Color _color;

        protected override void SetMaterialData()
        {
            if (_material)
                _material.SetColor("_TintColor", _color);
        }

        public override void Render(CommandBuffer cmd, ref RenderingData renderingData, PostProcessingRenderContext context)
        {
            base.Render(cmd, ref renderingData, context);

            context.BlitAndSwap(cmd, _material);
        }
    }
}
