using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using ZUI;

namespace LoneStack
{
    [CustomEditor(typeof(LSVolume))]
    public class LSVolumeEditor : LSEffectListEditor
    {
        static readonly List<LSVolume> volumesBuffer = new List<LSVolume>();
        
        LSVolume m_volume;

        SerializedProperty prop_profile;
        SerializedProperty prop_order;
        SerializedProperty prop_isGlobal;
        SerializedProperty prop_blend;
        SerializedProperty prop_blendDistance;

        SerializedProperty prop_visibleInSceneView;
        SerializedProperty prop_isGlobalInSceneView;

        SerializedProperty prop_changesToEffects;

        static bool gizmo_enabled = false;
        static float gizmo_opacity = .5f;

        protected readonly GUIStyle titleStyle = new GUIStyle();

        protected override IList<LSEffect> EffectList => m_volume.Effects;

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            using(ZUILayoutBox box = new ZUILayoutBox(5f, 5f, new GUIColor(.8f, .9f, .6f)))
            {
                GUILayout.Label("General", titleStyle);
                EditorGUILayout.PropertyField(prop_profile);
                EditorGUILayout.PropertyField(prop_order);
                EditorGUILayout.PropertyField(prop_blend);
                EditorGUILayout.PropertyField(prop_isGlobal);
                using (ZUIEnableState canMoveNext = new ZUIEnableState(!prop_isGlobal.boolValue))
                {
                    EditorGUILayout.PropertyField(prop_blendDistance);
                }
            }

            using (ZUILayoutBox box = new ZUILayoutBox(5f, 5f, new GUIColor(.6f, .8f, .9f)))
            {
                GUILayout.BeginHorizontal();
                GUILayout.Label("Active effects", titleStyle);
                bool wasGUIEnabled = GUI.enabled;
                GUI.enabled = m_volume.Profile;
                using (ZUIEnableState canApply = new ZUIEnableState(prop_profile.objectReferenceValue && (prop_changesToEffects.boolValue || EditorApplication.isPlaying)))
                {
                    using (new ZUIColorState(GUI.enabled ? Color.yellow*1.2f : GUI.color))
                    {
                        if (GUILayout.Button(new GUIContent("Apply to profile", "Write active effects over profile's effects"), GUILayout.Width(100)))
                        {
                            SerializedObject seriProfile = new SerializedObject(m_volume.Profile);
                            LSProfileEditor.ApplyEffects(seriProfile, m_volume.Effects);
                            seriProfile.ApplyModifiedProperties();
                            prop_changesToEffects.boolValue = false;
                        }
                    }
                }
                GUI.enabled = wasGUIEnabled;
                if (GUILayout.Button(new GUIContent("Reset", "Set profile efefcts as active effects"), GUILayout.Width(50)))
                {
                    m_volume.ResetEffectList();
                    RegenerateList();
                }
                GUILayout.EndHorizontal();
                DisplayEffectsList();
            }
            using (ZUILayoutBox box = new ZUILayoutBox(5f, 5f, GUI.color * new GUIColor(.6f, .55f, .6f)))
            {
                GUILayout.Label("Debugging", titleStyle);
                EditorGUI.BeginChangeCheck();
                EditorGUILayout.PropertyField(prop_visibleInSceneView);
                using (ZUIEnableState wouldBeGlobal = new ZUIEnableState(!prop_isGlobal.boolValue))
                {
                    EditorGUILayout.PropertyField(prop_isGlobalInSceneView);
                }
                gizmo_enabled = EditorGUILayout.Toggle("Enable Gizmo", gizmo_enabled);
                using(new ZUIEnableState(gizmo_enabled))
                {
                    gizmo_opacity = EditorGUILayout.Slider("Gizmo opacity", gizmo_opacity, 0f, 1f);
                }

                ZUIUtils.DrawLine();

                GUILayout.Label("For all active volumes", titleStyle);
                GUILayout.BeginHorizontal();
                GUILayout.Label("Scene view visibility:");
                if (GUILayout.Button("On"))
                {
                    LSVolume.SelectVolumes(v => true, volumesBuffer);
                    foreach (var volume in volumesBuffer)
                    {
                        SerializedObject seriVol = new SerializedObject(volume);
                        seriVol.Update();
                        seriVol.FindProperty("visibleInSceneView").boolValue = true;
                        seriVol.ApplyModifiedProperties();
                    }
                }
                if (GUILayout.Button("Off"))
                {
                    LSVolume.SelectVolumes(v => true, volumesBuffer);
                    foreach (var volume in volumesBuffer)
                    {
                        SerializedObject seriVol = new SerializedObject(volume);
                        seriVol.Update();
                        seriVol.FindProperty("visibleInSceneView").boolValue = false;
                        seriVol.ApplyModifiedProperties();
                    }
                }
                GUILayout.EndHorizontal();
                if (GUILayout.Button("Apply all volumes"))
                {
                    LSVolume.SelectVolumes(v => true, volumesBuffer);
                    foreach (var volume in volumesBuffer)
                    {
                        SerializedObject seriVol = new SerializedObject(volume);
                        SerializedProperty seriVolChanges = seriVol.FindProperty("changesToEffects");
                        if (!seriVolChanges.boolValue) continue;

                        SerializedObject seriProfile = new SerializedObject(volume.Profile);
                        LSProfileEditor.ApplyEffects(seriProfile, volume.Effects);
                        seriProfile.ApplyModifiedProperties();

                        seriVol.FindProperty("changesToEffects").boolValue = false;
                        seriVol.ApplyModifiedProperties();
                    }
                    serializedObject.Update();
                }
                if(GUILayout.Button("Reset all volumes"))
                {
                    LSVolume.SelectVolumes(v => v != m_volume, volumesBuffer);
                    foreach (var volume in volumesBuffer) 
                        volume.ResetEffectList();
                    m_volume.ResetEffectList();
                    RegenerateList();
                }
                if (EditorGUI.EndChangeCheck())
                    SceneView.RepaintAll();
            }

            serializedObject.ApplyModifiedProperties();
        }

        [DrawGizmo(GizmoType.InSelectionHierarchy | GizmoType.NonSelected)]
        static void DrawHandles(LSVolume volume, GizmoType gizmoType)
        {
            if (!gizmo_enabled || volume.ManagedColliders == null) return;
            foreach(Collider c in volume.ManagedColliders)
            {
                Gizmos.matrix = c.transform.localToWorldMatrix;
                Gizmos.color = new GUIColor(.2f, .8f, .9f, gizmo_opacity);
                if(c is BoxCollider box)
                {
                    Gizmos.DrawCube(box.center, box.size);
                }
                else if (c is SphereCollider sphere)
                {
                    Gizmos.DrawSphere(sphere.center, sphere.radius);
                }
                else if (c is MeshCollider meshCollider)
                {
                    Gizmos.DrawMesh(meshCollider.sharedMesh);
                }
                //no gizmo for capsule collider
            }
        }

        protected override void OnEnable()
        {
            m_volume = target as LSVolume;

            prop_profile = serializedObject.FindProperty("profile");
            prop_order = serializedObject.FindProperty("order");
            prop_isGlobal = serializedObject.FindProperty("isGlobal");
            prop_blend = serializedObject.FindProperty("blend");
            prop_blendDistance = serializedObject.FindProperty("blendDistance");
            
            prop_visibleInSceneView = serializedObject.FindProperty("visibleInSceneView");
            prop_isGlobalInSceneView = serializedObject.FindProperty("isGlobalInSceneView");

            prop_changesToEffects = serializedObject.FindProperty("changesToEffects");

            titleStyle.fontStyle = FontStyle.Bold;

            base.OnEnable();
        }

        protected override void OnSwapEffects(int id0, int id1)
        {
            Swap(EffectList, id0, id1);
            prop_changesToEffects.boolValue = true;
        }

        protected override void OnRemoveEffect(int id)
        {
            EffectList.RemoveAt(id);
            prop_changesToEffects.boolValue = true;
        }

        protected override void OnModifiedEffect(int id)
        {
            prop_changesToEffects.boolValue = true;
        }

        protected override void OnAddEffect(LSEffect newEffect)
        {
            m_volume.Effects.Add(newEffect);
            prop_changesToEffects.boolValue = true;
        }
    }
}