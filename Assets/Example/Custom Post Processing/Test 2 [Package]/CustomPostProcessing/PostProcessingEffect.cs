using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Example.CustomPostProcessing
{
    public abstract class PostProcessingEffect : ScriptableObject
    {
        public bool active = true;

        public Shader _shader;

        protected Material _material;

        protected virtual void OnValidate()
        {
            CreateMaterial();
            SetMaterialData();
        }

        protected void CreateMaterial() 
        {
            if (_shader == null)
            {
                _material = null;
            }
            else if (_material == null || _material.shader != _shader)
            {
                _material = new Material(_shader);
            }
        }

        protected virtual void SetMaterialData() 
        {
            
        }

        public virtual void Render(CommandBuffer cmd, ref RenderingData renderingData, PostProcessingRenderContext context) 
        {
            CreateMaterial();
            if (_material == null)
                return;
            SetMaterialData();
        }
    }
}
