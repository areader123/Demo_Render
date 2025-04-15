using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using ZUI;
using System.Linq;

namespace LoneStack
{
    [CustomEditor(typeof(LSProfile))]
    public class LSProfileEditor : LSEffectListEditor
    {
        SerializedList prop_blueprints;
        readonly List<LSEffect> inst_effects = new List<LSEffect>();
        protected override IList<LSEffect> EffectList => inst_effects;

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            DisplayEffectsList();

            serializedObject.ApplyModifiedProperties();
        }

        protected override void OnEnable()
        {
            prop_blueprints = new SerializedList(serializedObject.FindProperty("blueprints"));

            base.OnEnable();
        }

        public static void ApplyEffects(SerializedObject profile, IList<LSEffect> effects)
        {
            SerializedList seriBP = profile.FindProperty("blueprints");

            seriBP.Clear();
            foreach (LSEffect effect in effects)
            {
                Type effectType = effect.GetType();

                AlwaysIncludeShaderEditor.ScanType(effectType);

                var newSeriEffect = seriBP.InsertBack();
                newSeriEffect.FindPropertyRelative("type").stringValue = effectType.Name;
                newSeriEffect.FindPropertyRelative("serializedSettings").stringValue = effect.SerializeSettings();
            }
        }

        protected override void OnSwapEffects(int id0, int id1)
        {
            Swap(inst_effects, id0, id1);
            prop_blueprints.MoveElement(id0, id1);
        }

        protected override void OnRemoveEffect(int id)
        {
            inst_effects.RemoveAt(id);
            prop_blueprints.RemoveAt(id);
        }

        protected override void OnModifiedEffect(int id)
        {
            prop_blueprints[id].FindPropertyRelative("serializedSettings").stringValue = inst_effects[id].SerializeSettings();
        }

        protected override void OnAddEffect(LSEffect newEffect)
        {
            var newBP = prop_blueprints.InsertBack();
            inst_effects.Add(newEffect);
            newBP.FindPropertyRelative("type").stringValue = newEffect.GetType().Name;
            newBP.FindPropertyRelative("serializedSettings").stringValue = newEffect.SerializeSettings();
        }

        protected override void RegenerateList()
        {
            foreach (var effectInst in inst_effects)
                if (effectInst) DestroyImmediate(effectInst);
            inst_effects.Clear();
            foreach (var bp in prop_blueprints)
            {
                var effect = CreateInstance(bp.property.FindPropertyRelative("type").stringValue) as LSEffect;
                effect.DeserializeSettings(bp.property.FindPropertyRelative("serializedSettings").stringValue);
                inst_effects.Add(effect);
            }
            base.RegenerateList();
        }
    }
}