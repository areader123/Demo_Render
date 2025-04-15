using UnityEngine;
using UnityEditor;
using LoneStack;
using ZUI;

[CustomEditor(typeof(Colorize), true)]
public class ColorizeEditor : LSEffectEditor
{
    SerializedProperty prop_tint;
    SerializedProperty prop_power;

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        using(ZUILayoutBox box = new ZUILayoutBox(2, 5, new GUIColor(.5f, .5f, .5f)))
        {
            EditorGUILayout.PropertyField(prop_tint);
        }
        using (ZUILayoutBox box = new ZUILayoutBox(2, 5, new GUIColor(.5f, .5f, .5f)))
        {
            GUILayout.BeginVertical();
            EditorGUILayout.PropertyField(prop_power);
            GUILayout.EndVertical();
        }
        serializedObject.ApplyModifiedProperties();
    }

    protected override void OnEnable()
    {
        base.OnEnable();
        prop_tint = Settings.FindPropertyRelative("tint");
        prop_power = Settings.FindPropertyRelative("contrast");
    }
}
