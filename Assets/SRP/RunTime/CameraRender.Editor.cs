using UnityEditor;
using UnityEditor.PackageManager.UI;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

partial class CameraRender 
{
    partial void DrawGizmos();
    partial void DrawUnsupportedShaders();
    partial void PrepareForSceneWindow();
    partial void PrepareBuffer();

#if UNITY_EDITOR
    private static ShaderTagId[] llegacyShaderTagIds = {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };

    private static Material errorMaterial;

    private string SampleName {get;set;}

    partial void DrawGizmos()
    {
       // Determines whether or not to draw Gizmos.
        if(Handles.ShouldRenderGizmos()){
            context.DrawGizmos(camera,GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera,GizmoSubset.PostImageEffects);
        }
    }

    partial void DrawUnsupportedShaders()
    {
        //错误材质
        if(errorMaterial == null){
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }
        //把不支持的shader按顺序设置成各pass绘制
        var drawingSetting = new DrawingSettings(llegacyShaderTagIds[0],new SortingSettings(camera)){
            overrideMaterial = errorMaterial
        };
        for(int i = 0; i < llegacyShaderTagIds.Length; i++) {
            drawingSetting.SetShaderPassName(i,llegacyShaderTagIds[i]);      
            var filteringSetting = FilteringSettings.defaultValue;
            context.DrawRenderers(cullingResults, ref drawingSetting, ref filteringSetting);
        }
    }

    //在scene窗口显示UI
    partial void PrepareForSceneWindow()
    {
        if(camera.cameraType == CameraType.SceneView)
             ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
    }

    partial void PrepareBuffer()
    {
         // 保证buffer名字前后一致
        Profiler.BeginSample("Editor Only");
        buffer.name = SampleName = camera.name;
        Profiler.EndSample();
    }
#else
     // 不使用常量而是定义只get的属性，这样在运行模式下不会分配额外内存
    string SampleName => bufferName;
#endif

}

