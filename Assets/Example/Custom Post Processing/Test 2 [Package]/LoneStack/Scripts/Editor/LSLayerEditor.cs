using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace LoneStack
{
    [CustomEditor(typeof(LSLayer))]
    public class LSLayerEditor : Editor
    {
        SerializedProperty prop_volumeLayers;
        SerializedProperty prop_volumeTrigger;

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            GUILayout.BeginHorizontal();
            EditorGUILayout.PropertyField(prop_volumeTrigger);
            if (GUILayout.Button("this", GUILayout.Width(40)))
                prop_volumeTrigger.objectReferenceValue = (target as LSLayer).GetComponent<Transform>();
            GUILayout.EndHorizontal();
            EditorGUILayout.PropertyField(prop_volumeLayers);
            serializedObject.ApplyModifiedProperties();

            if ((target as LSLayer).VolumeLayers == 0)
                EditorGUILayout.HelpBox("No volumes can be detected if volumeLayers is Nothing", MessageType.Warning);
        }

        private void OnEnable()
        {
            prop_volumeLayers = serializedObject.FindProperty("volumeLayers");
            prop_volumeTrigger = serializedObject.FindProperty("volumeTrigger");
        }
    }
}