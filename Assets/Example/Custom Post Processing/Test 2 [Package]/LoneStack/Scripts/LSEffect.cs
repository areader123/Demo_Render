using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace LoneStack
{
    [Serializable]
    public abstract class LSEffectSettings 
    {
        public bool enabled = true;
    }

    [Serializable]
    public class LoneStackEffectBlueprint
    {
        public string type;
        public string serializedSettings;

        public LSEffect Instantiate()
        {
            var newEffect = ScriptableObject.CreateInstance(Type.GetType(type)) as LSEffect;
            newEffect.DeserializeSettings(serializedSettings);
            return newEffect;
        }
    }

    [AttributeUsage(AttributeTargets.Class, AllowMultiple = true, Inherited = true)]
    public class AlwaysIncludeShader : Attribute
    {
        public string ShaderName { get; set; }

        public AlwaysIncludeShader(string shaderName) => ShaderName = shaderName;
    }

    public abstract class LSEffect : ScriptableObject
    {
        protected static readonly int _Blend = Shader.PropertyToID("_Blend");

        public abstract bool Enabled { get; set; }

        public abstract float Blend { set; }
        public abstract void DeserializeSettings(string settingsData);
        public abstract string SerializeSettings();
        public abstract void EnqueueToBuffer(CommandBuffer buffer, LSContext context, ref RenderingData renderingData);

        public virtual void Update() { }
    }

    public abstract class LSEffect<SETTINGS> : LSEffect where SETTINGS : LSEffectSettings, new()
    {
        public SETTINGS settings = new SETTINGS();

        public override bool Enabled { get => settings.enabled; set => settings.enabled = value; }

        protected abstract void Awake();

        public override void DeserializeSettings(string settingsData) => settings = JsonUtility.FromJson<SETTINGS>(settingsData);
        public override string SerializeSettings() => JsonUtility.ToJson(settings);
    }

    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false, Inherited = false)]
    public class LSEffectPath : Attribute
    {
        public string Path { get; private set; }

        public LSEffectPath(string path) { Path = path; }
    }
}