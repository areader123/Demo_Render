using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
using UnityEngine;

namespace LoneStack
{
    public class LoneStackAssetsCreator : Editor
    {
        const string FILE_NAME_DEFAULT = "EffectShader";
        const string TEMPLATES_FOLDER = "Assets/LoneStack/Editor";

        const string KEY_Name = "##Name##";
        const string KEY_NameMinusEditor = "##NameMinusEditor##";

        class LSFileCreationCallback : EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                Object o = ReplaceAssetTerms(pathName, resourceFile);
                ProjectWindowUtil.ShowCreatedAsset(o);
            }

            Object ReplaceAssetTerms(string created, string template)
            {
                string objName = Path.GetFileNameWithoutExtension(created);
                string objNameMinusEditor = objName.EndsWith("Editor") ?
                    objName.Remove(objName.Length - "Editor".Length) : objName;

                UTF8Encoding encoding = new UTF8Encoding(true, false);

                if (File.Exists(template))
                {
                    StreamReader reader = new StreamReader(template);
                    string templateText = reader.ReadToEnd();
                    reader.Close();

                    templateText = templateText.Replace(KEY_Name, objName);
                    templateText = templateText.Replace(KEY_NameMinusEditor, objNameMinusEditor);

                    StreamWriter writer = new StreamWriter(Path.GetFullPath(created), false, encoding);
                    writer.Write(templateText);
                    writer.Close();

                    AssetDatabase.ImportAsset(created);
                    return AssetDatabase.LoadAssetAtPath(created, typeof(Object));
                }
                else
                {
                    Debug.LogError("The template file was not found: " + template);
                    return null;
                }
            }
        }

        static readonly Texture2D shaderIcon = EditorGUIUtility.IconContent("Shader Icon").image as Texture2D;
        static readonly Texture2D csScriptIcon = EditorGUIUtility.IconContent("cs Script Icon").image as Texture2D;

        [MenuItem("Assets/Create/LoneStack/EffectShader", priority = 1000)]
        public static void CreateShader()
        {
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(path)) return;

            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
                0,
                CreateInstance<LSFileCreationCallback>(),
                path + "/" + FILE_NAME_DEFAULT + ".shader",
                shaderIcon,
                TEMPLATES_FOLDER + "/LoneStackBaseShader.txt");
        }

        [MenuItem("Assets/Create/LoneStack/RawEffectShader", priority = 1000)]
        public static void CreateShaderRaw()
        {
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(path)) return;

            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
                0,
                CreateInstance<LSFileCreationCallback>(),
                path + "/" + FILE_NAME_DEFAULT + ".shader",
                shaderIcon,
                TEMPLATES_FOLDER + "/LoneStackBaseShaderRaw.txt");
        }

        [MenuItem("Assets/Create/LoneStack/EffectScript", priority = 1020)]
        public static void CreateEffectScript()
        {
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(path)) return;

            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
                0,
                CreateInstance<LSFileCreationCallback>(),
                path + "/" + FILE_NAME_DEFAULT + ".cs",
                csScriptIcon,
                TEMPLATES_FOLDER + "/LoneStackBaseEffectScript.txt");
        }

        [MenuItem("Assets/Create/LoneStack/EffectEditor", priority = 1040)]
        public static void CreateEffectEditor()
        {
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(path)) return;

            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
                0,
                CreateInstance<LSFileCreationCallback>(),
                path + "/" + FILE_NAME_DEFAULT + "Editor.cs",
                csScriptIcon,
                TEMPLATES_FOLDER + "/LoneStackBaseEffectEditor.txt");
        }
    }
}