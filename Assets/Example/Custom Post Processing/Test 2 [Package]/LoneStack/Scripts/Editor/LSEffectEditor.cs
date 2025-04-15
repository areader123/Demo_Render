using UnityEngine;
using UnityEditor;
using ZUI;
using System;
using System.Collections.Generic;
using System.Linq;

namespace LoneStack
{
    [CustomEditor(typeof(LSEffect), true)]
    public class LSEffectEditor : Editor
    {
        SerializedProperty settings;
        protected SerializedProperty Settings => settings;

        /// <summary>
        /// Will display an effect's settings. (only serializeFields/public properties, property attributes applied)
        /// </summary>
        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            var prop_setting = settings.Copy();
            int prop_setting_depth = prop_setting.depth;
            prop_setting.Next(true); // enter settings
            bool displaySettings = prop_setting.Next(true); // skip enabled
            while (displaySettings && prop_setting.depth > prop_setting_depth)
            {
                EditorGUILayout.PropertyField(prop_setting);
                displaySettings = prop_setting.Next(false);
            }

            serializedObject.ApplyModifiedProperties();
        }

        protected virtual void OnEnable()
        {
            if (!target)
            {
                Debug.LogWarning("Leaked effect editor (it should auto-fix, if the issue doesn't fix itself, restart the editor)");
                DestroyImmediate(this);
                return;
            }
            settings = serializedObject.FindProperty("settings");
        }
    }

    public static class AlwaysIncludeShaderEditor
    {
        public static void ScanType(Type type)
        {
            AlwaysIncludeShader[] ais_attr = (AlwaysIncludeShader[])type.GetCustomAttributes(typeof(AlwaysIncludeShader), true);
            foreach (var attr in ais_attr)
            {
                Shader shader = Shader.Find(attr.ShaderName);
                if (!shader) Debug.LogWarning("[LoneStack] " + type.Name + " has (or inherits) the AlwaysIncludeShader attribute for a shader not found \"" + attr.ShaderName + "\"");
                else AddShader(shader);
            }
        }

        public static void AddShader(Shader shader)
        {
            using (SerializedObject graphicsSettingsSObj =
                new SerializedObject(AssetDatabase.LoadAssetAtPath<UnityEngine.Rendering.GraphicsSettings>("ProjectSettings/GraphicsSettings.asset")))
            {
                SerializedProperty arrayProp = graphicsSettingsSObj.FindProperty("m_AlwaysIncludedShaders");
                bool hasShader = false;
                for (int i = 0; i < arrayProp.arraySize; ++i)
                {
                    var arrayElem = arrayProp.GetArrayElementAtIndex(i);
                    if (shader == arrayElem.objectReferenceValue)
                    {
                        hasShader = true;
                        break;
                    }
                }

                if (!hasShader)
                {
                    int arrayIndex = arrayProp.arraySize;
                    arrayProp.InsertArrayElementAtIndex(arrayIndex);
                    var arrayElem = arrayProp.GetArrayElementAtIndex(arrayIndex);
                    arrayElem.objectReferenceValue = shader;

                    graphicsSettingsSObj.ApplyModifiedProperties();

                    AssetDatabase.SaveAssets();

                    Debug.Log("[LoneStack] Added " + shader.name + " in the GraphicsSettings' always included shaders list.");
                }
            }
        }
    }

    public abstract class LSEffectListEditor : Editor
    {
        readonly GUIStyle foldStyle = new GUIStyle();

        readonly List<GUIEffectInstance> guiEffects = new List<GUIEffectInstance>();
        LSEffectPicker picker = null;

        protected virtual void OnDisable()
        {
            if (picker)
                picker.Close();
        }

        protected virtual void OnEnable()
        {
            foldStyle.fontSize = 10;
            foldStyle.alignment = TextAnchor.MiddleCenter;
            foldStyle.normal = new GUIStyleState()
            {
                textColor = new Color(.1f, .1f, .1f)
            };

            RegenerateList();
        }

        protected abstract void OnSwapEffects(int id0, int id1);
        protected abstract void OnRemoveEffect(int id);
        protected abstract void OnModifiedEffect(int id);
        protected abstract void OnAddEffect(LSEffect newEffect);

        protected static void Swap<T>(IList<T> list, int id0, int id1)
        {
            var temp = list[id0];
            list[id0] = list[id1];
            list[id1] = temp;
        }

        protected abstract IList<LSEffect> EffectList { get; }

        protected virtual void RegenerateList()
        {
            foreach (var it in guiEffects)
                it.Dispose();
            guiEffects.Clear();
            var list = EffectList;
            foreach (var it in list)
                guiEffects.Add(new GUIEffectInstance(it));
        }

        protected void DisplayEffectsList()
        {
            using (ZUILayoutBox outerBox = new ZUILayoutBox(5f, 5f, new GUIColor(.5f, .5f, .5f)))
            {
                GUILayout.Label("Effects: " + guiEffects.Count);

                int id = -1;
                foreach(GUIEffectInstance effectGUI in guiEffects)
                {
                    bool mustBreak = false;
                    id++;

                    using (ZUILayoutBox box = new ZUILayoutBox(5f, 5f, new GUIColor(.7f, .7f, .7f)))
                    {
                        GUILayout.BeginHorizontal();

                        effectGUI.displayed ^= GUILayout.Button(new GUIContent(effectGUI.displayed ? "▼" : "►", "display effect settings"), foldStyle,
                            GUILayout.Width(20), GUILayout.Height(20));

                        bool enabled = GUILayout.Toggle(effectGUI.Enabled, effectGUI.effectName);

                        using (ZUIEnableState canMoveNext = new ZUIEnableState(id < guiEffects.Count-1))
                        {
                            if (GUILayout.Button(new GUIContent("▼", "move down"), GUILayout.Width(30)))
                            {
                                Swap(guiEffects, id, id + 1);
                                OnSwapEffects(id, id + 1);
                                mustBreak = true;
                            }
                        }
                        using (ZUIEnableState canMovePrev = new ZUIEnableState(id > 0))
                        {
                            if (!mustBreak && GUILayout.Button(new GUIContent("▲", "move up"), GUILayout.Width(30)))
                            {
                                Swap(guiEffects, id, id - 1);
                                OnSwapEffects(id, id - 1);
                                mustBreak = true;
                            }
                        }

                        GUILayout.Space(5);

                        if (!mustBreak && GUILayout.Button(new GUIContent("X", "remove effect"), GUILayout.Width(30)))
                        {
                            effectGUI.Dispose();
                            guiEffects.RemoveAt(id);
                            OnRemoveEffect(id);
                            mustBreak = true;
                        }

                        GUILayout.EndHorizontal();

                        ZUIUtils.DrawLine();

                        if (!mustBreak && effectGUI.OnGUI(enabled))
                            OnModifiedEffect(id);
                    }

                    if (mustBreak) break;
                }

                if (GUILayout.Button("Add"))
                {
                    picker = LSEffectPicker.GetPicker(effectType =>
                    {
                        serializedObject.Update();

                        AlwaysIncludeShaderEditor.ScanType(effectType);

                        LSEffect newEffectInst = CreateInstance(effectType) as LSEffect;
                        guiEffects.Add(new GUIEffectInstance(newEffectInst));

                        OnAddEffect(newEffectInst);

                        serializedObject.ApplyModifiedProperties();
                    });
                    picker.fieldColor = new GUIColor(.7f, .7f, .7f);
                }
            }
        }

        class GUIEffectInstance : IDisposable
        {
            public bool displayed = false;
            public Editor editor = null;
            public string effectName = "LSUnknown";
            readonly SerializedProperty enabled;
            public bool Enabled { get => enabled.boolValue; private set => enabled.boolValue = value; }

            public GUIEffectInstance(LSEffect effect)
            {
                effectName = effect.GetType().Name;
                editor = CreateEditor(effect);
                enabled = editor.serializedObject.FindProperty("settings.enabled");
            }

            public void Dispose()
            {
                if (editor) DestroyImmediate(editor);
            }

            public bool OnGUI(bool enabled)
            {
                bool enaChange = enabled != Enabled;
                if (enaChange)
                {
                    editor.serializedObject.Update();
                    Enabled = enabled;
                    editor.serializedObject.ApplyModifiedProperties();
                }
                if (!displayed) return enaChange;
                EditorGUI.BeginChangeCheck();
                using (new ZUIEnableState(enabled))
                {
                    try
                    {
                        editor.OnInspectorGUI();
                        if (editor.serializedObject.hasModifiedProperties)
                            Debug.LogWarning("[LSVolumeEditor] >> It seems that " + editor.GetType().Name + " doesn't (fully) apply the serializedObject's modifiedProperties OnInspectorGUI.");
                    }
                    catch (ExitGUIException) { GUIUtility.ExitGUI(); }
                    catch (Exception e) { Debug.LogError(e.Message); }
                }
                return EditorGUI.EndChangeCheck() || enaChange;
            }
        }

        class LSEffectPicker : EditorWindow
        {
            struct EffectUI
            {
                public string name;
                public Type type;
            }

            class EffectCategory
            {
                public readonly EffectCategory parent;

                public readonly Dictionary<string, EffectCategory> categories = new Dictionary<string, EffectCategory>();
                public readonly List<EffectUI> effects = new List<EffectUI>();

                public EffectCategory(EffectCategory _parent) => parent = _parent;
            }

            event Action<Type> OnSelect;

            readonly EffectCategory rootCategory = new EffectCategory(null);

            EffectCategory currentCategory;

            Vector2 scrollPos = Vector2.zero;

            public static LSEffectPicker GetPicker(Action<Type> onSelect)
            {
                LSEffectPicker picker = GetWindow<LSEffectPicker>("LoneStack Effect Picker");
                picker.OnSelect = onSelect;
                return picker;
            }

            public Color fieldColor = new Color(.5f, .5f, .5f);

            private void OnGUI()
            {
                scrollPos = GUILayout.BeginScrollView(scrollPos);

                bool mustBreak = false;

                if (currentCategory.parent != null)
                {
                    using (ZUILayoutBox box = new ZUILayoutBox(1, 1, fieldColor))
                    {
                        GUILayout.BeginHorizontal();
                        if (GUILayout.Button("<", GUILayout.Width(30)))
                        {
                            mustBreak = true;
                            currentCategory = currentCategory.parent;
                        }
                        GUILayout.Label("..");
                        GUILayout.EndHorizontal();
                    }
                }

                if (!mustBreak)
                {
                    foreach (var categ_it in currentCategory.categories)
                    {
                        using (ZUILayoutBox box = new ZUILayoutBox(1, 1, fieldColor))
                        {
                            GUILayout.BeginHorizontal();
                            GUILayout.Label(categ_it.Key);
                            if (GUILayout.Button(">", GUILayout.Width(30)))
                            {
                                mustBreak = true;
                                currentCategory = categ_it.Value;
                            }
                            GUILayout.EndHorizontal();
                        }
                        if (mustBreak) break;
                    }
                }

                if (!mustBreak)
                {
                    foreach (var effect in currentCategory.effects)
                    {
                        using (ZUILayoutBox box = new ZUILayoutBox(1, 1, fieldColor))
                        {
                            GUILayout.BeginHorizontal();
                            GUILayout.Label(effect.name);
                            if (GUILayout.Button("select", GUILayout.Width(70)))
                            {
                                mustBreak = true;
                                OnSelect?.Invoke(effect.type);
                                Close();
                            }
                            GUILayout.EndHorizontal();
                        }
                        if (mustBreak) break;
                    }
                }

                GUILayout.EndScrollView();
            }

            private void OnEnable()
            {
                var baseType = typeof(LSEffect);
                currentCategory = rootCategory;
                IEnumerable<Type> effectTypes = baseType.Assembly.GetTypes()
                    .Where(t => baseType.IsAssignableFrom(t) && !t.IsAbstract && !t.IsGenericTypeDefinition);
                foreach (Type etype in effectTypes)
                {
                    var lsepath = etype.GetCustomAttributes(typeof(LSEffectPath), false);
                    if (lsepath.Length > 0)
                    {
                        string[] pathBits = (lsepath[0] as LSEffectPath).Path.Split(new char[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries);
                        EffectCategory categ = rootCategory;
                        int categories = pathBits.Length - 1;
                        for (int i = 0; i < categories; i++)
                        {
                            try { categ = categ.categories[pathBits[i]]; }
                            catch (ExitGUIException) { GUIUtility.ExitGUI(); }
                            catch (KeyNotFoundException)
                            {
                                EffectCategory newCateg = new EffectCategory(categ);
                                categ.categories.Add(pathBits[i], newCateg);
                                categ = newCateg;
                            }
                        }
                        categ.effects.Add(new EffectUI { name = pathBits[categories], type = etype });
                    }
                }
            }
        }
    }
}