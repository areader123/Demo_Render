using UnityEngine;
using UnityEditor;
using LoneStack;
using ZUI;

//[CustomEditor(typeof(LSBlit), true)]
public class LSBlitEditor : LSEffectEditor
{
    SerializedProperty prop_material;

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        
        EditorGUILayout.PropertyField(prop_material);

        if (!prop_material.objectReferenceValue)
            EditorGUILayout.HelpBox("There will be no effect if no material is attached.", MessageType.Warning);

        serializedObject.ApplyModifiedProperties();
    }

    protected override void OnEnable()
    {
        base.OnEnable();
        if (!this) return;
        prop_material = Settings.FindPropertyRelative("material");
    }
}
