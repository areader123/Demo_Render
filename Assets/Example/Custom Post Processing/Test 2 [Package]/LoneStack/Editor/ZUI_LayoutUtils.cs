using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

namespace ZUI
{
    public struct GUIColor
    {
        Color color;
        public GUIColor(float r, float g, float b, float a = 1f) => color = ZUIUtils.GUIColor(r, g, b, a);
        public GUIColor(Color inColor) => color = ZUIUtils.GUIColor(inColor);

        public static implicit operator Color(GUIColor gcolor) => gcolor.color;
    }

    public class ZUIUtils
    {
        public static float GUIColorContraster = 1f - .8f * GUI.skin.label.normal.textColor.r;
        public static Color GUIColor(Color inColor) => GUI.color * inColor * new Color(GUIColorContraster, GUIColorContraster, GUIColorContraster);
        public static Color GUIColor(float r, float g, float b, float a = 1f) => GUIColor(new Color(r, g, b, a));

        public static GUIStyle whiteStyle = new GUIStyle() { normal = new GUIStyleState() { background = Texture2D.whiteTexture } };

        public static void DrawLine(float thickness = 3f)
        {
            Color guiCol = GUI.color;
            GUI.color = guiCol * .9f;
            GUILayout.Box("", new GUILayoutOption[]
            {
            GUILayout.ExpandWidth(true),
            GUILayout.Height(thickness)
            });
            GUI.color = guiCol;
        }

        public static void DrawLine(Color color, float thickness = 3f)
        {
            Color guiCol = GUI.color;
            GUI.color = color;
            GUILayout.Box("", new GUILayoutOption[]
            {
            GUILayout.ExpandWidth(true),
            GUILayout.Height(thickness)
            });
            GUI.color = guiCol;
        }

        public static IEnumerable<GameObject> FindPrefabAssets()
            => AssetDatabase.FindAssets("t:PreFab").Select(guid => AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guid)));
        public static IEnumerable<GameObject> FindPrefabAssets(Func<GameObject, bool> selector) => FindPrefabAssets().Where(selector);

    }

    public struct Iterator<T> 
    { 
        public readonly int id; 
        public readonly T property;

        public Iterator(int id, T property)
        {
            this.id = id;
            this.property = property;
        }
    }

    public class SerializedList : IEnumerable<Iterator<SerializedProperty>>
    {
        public delegate O Selector<in I, out O>(I obj);

        SerializedProperty property;

        public int Size => ArraySize(property.Copy());

        public SerializedProperty this[int id] => property.GetArrayElementAtIndex(id);

        public SerializedList(SerializedProperty _property)
        {
            if (_property == null) throw new ArgumentNullException("Can't create SerializedList, the property is null");
            if (!_property.isArray) throw new ArgumentException("Can't create SerializedList, the property " + _property.name + " isn't an array");
            property = _property;
        }
        public static implicit operator SerializedList(SerializedProperty property) => new SerializedList(property);

        public void MoveElement(int from, int to) => property.MoveArrayElement(from, to);

        public void RemoveAt(int id)
        {
            SerializedProperty sp = this[id];
            if(sp.propertyType == SerializedPropertyType.ObjectReference ||
                sp.propertyType == SerializedPropertyType.ExposedReference ||
                sp.propertyType == SerializedPropertyType.ManagedReference) 
                sp.objectReferenceValue = null;
            property.DeleteArrayElementAtIndex(id);
        }
        public SerializedProperty Insert(int id)
        {
            property.InsertArrayElementAtIndex(id);
            return this[id];
        }
        public SerializedProperty InsertBack() => Insert(Size);
        public void Clear() => property.ClearArray();

        public List<T> ToList<T>() where T : UnityEngine.Object
        {
            SerializedProperty sp = property.Copy();
            List<T> outList = new List<T>(ArraySize(sp));
            for(int i = 0; i < outList.Capacity; i++)
            {
                sp.Next(false);
                outList.Add((T)sp.objectReferenceValue);
            }
            return outList;
        }

        public List<T> ToList<T>(Selector<SerializedProperty, T> selector)
        {
            SerializedProperty sp = property.Copy();
            List<T> outList = new List<T>(ArraySize(sp));
            for (int i = 0; i < outList.Capacity; i++)
            {
                sp.Next(false);
                outList.Add(selector(sp));
            }
            return outList;
        }

        int ArraySize(SerializedProperty sp)
        {
            sp.Next(true); // skip generic
            sp.Next(true); // adv to array size
            return sp.intValue;
        }

        public IEnumerator<Iterator<SerializedProperty>> GetEnumerator()
        {
            SerializedProperty sp = property.Copy();

            int arraySize = ArraySize(sp);

            for (int i = 0; i < arraySize; i++)
            {
                sp.Next(false); // adv to first/next element
                yield return new Iterator<SerializedProperty>(i, sp.Copy());
            }
        }

        IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
    }

    public class ZUILayoutArea : IDisposable
    {
        float rightIndent = 0;
        float downIndent = 0;

        public ZUILayoutArea(float left, float right, float up, float down, GUIStyle style, Color? color = null, params GUILayoutOption[] options)
        {
            color = color ?? GUI.color;
            rightIndent = right;
            downIndent = down;
            GUILayout.BeginVertical();
            GUILayout.Space(up);
            GUILayout.BeginHorizontal();
            GUILayout.Space(left);
            Color c = GUI.color;
            GUI.color = color.Value;
            GUILayout.BeginVertical(style, options);
            GUI.color = c;
        }
        public ZUILayoutArea(float left, float right, GUIStyle style, Color? color = null, params GUILayoutOption[] options)
        {
            color = color ?? GUI.color;
            rightIndent = right;
            GUILayout.BeginVertical();
            GUILayout.BeginHorizontal();
            GUILayout.Space(left);
            Color c = GUI.color;
            GUI.color = color.Value;
            GUILayout.BeginVertical(style, options);
            GUI.color = c;
        }
        public ZUILayoutArea(float left, float right, float up, float down, params GUILayoutOption[] options)
        {
            rightIndent = right;
            downIndent = down;
            GUILayout.BeginVertical();
            GUILayout.Space(up);
            GUILayout.BeginHorizontal();
            GUILayout.Space(left);
            GUILayout.BeginVertical(options);
        }
        public ZUILayoutArea(float left, float right, params GUILayoutOption[] options)
        {
            rightIndent = right;
            GUILayout.BeginVertical();
            GUILayout.BeginHorizontal();
            GUILayout.Space(left);
            GUILayout.BeginVertical(options);
        }

        public void Dispose()
        {
            GUILayout.EndVertical();
            GUILayout.Space(rightIndent);
            GUILayout.EndHorizontal();
            GUILayout.Space(downIndent);
            GUILayout.EndVertical();
        }
    }

    public class ZUILayoutBox : IDisposable
    {
        ZUILayoutArea box;
        ZUILayoutArea inner;

        public ZUILayoutBox(float _outer, float _inner, Color? color = null, params GUILayoutOption[] options)
        {
            color = color ?? GUI.color;
            box = new ZUILayoutArea(_outer, _outer, _outer, _outer, ZUIUtils.whiteStyle, color);
            inner = new ZUILayoutArea(_inner, _inner, _inner, _inner, options);
        }

        public void Dispose()
        {
            inner.Dispose();
            box.Dispose();
        }
    }

    public class ZUIEnableState : IDisposable
    {
        bool wasEnabled;

        public ZUIEnableState(bool state)
        {
            wasEnabled = GUI.enabled;
            GUI.enabled = state;
        }

        public void Dispose()
        {
            GUI.enabled = wasEnabled;
        }
    }

    public class ZUIColorState : IDisposable
    {
        Color prevColor;

        public ZUIColorState(Color color)
        {
            prevColor = GUI.color;
            GUI.color = color;
        }

        public void Dispose()
        {
            GUI.color = prevColor;
        }
    }
}