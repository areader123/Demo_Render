using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using System;


#if UNITY_EDITOR
using UnityEditor;
#endif
public enum HeightMapResolution
{
    [InspectorName("128")] _128 = 128,
    [InspectorName("256")] _256 = 256,
    [InspectorName("512")] _512 = 512,
    [InspectorName("1024")] _1024 = 1024,
}
#if UNITY_EDITOR
[ExecuteAlways, DisallowMultipleComponent, RequireComponent(typeof(Camera))]
[CanEditMultipleObjects]
#endif
public class HeightMapRender : MonoBehaviour
{
    static readonly string m_HeightMapShaderName = "Unlit/SceneHeightMap";
    Camera m_Camera;

    public HeightMapResolution heightMapResolution = HeightMapResolution._512;
    [SerializeField, Tooltip("勾选后，Camera组件将会被锁定，不能再编辑，防止误操作")]
    private bool m_LockEdit = false;

    public bool LockEdit//在set的同时 触发代码
    {
        set
        {
            if (value)
            {
                transform.hideFlags = HideFlags.NotEditable;
                if (m_Camera)
                {
                    m_Camera.hideFlags = HideFlags.NotEditable;
                }
            }
            else
            {
                transform.hideFlags = HideFlags.None;
                if (m_Camera)
                {
                    m_Camera.hideFlags = HideFlags.None;
                }
            }

            m_LockEdit = value;
        }
        get { return m_LockEdit; }
    }

    RenderTextureFormat m_Format = RenderTextureFormat.ARGB32;
    Shader m_HeightMapShader;

    Shader HeightMapShader//实时更新
    {
        get
        {
            if (m_HeightMapShader == null)
            {
                m_HeightMapShader = Shader.Find(m_HeightMapShaderName);
            }
            return m_HeightMapShader;
        }
    }

    HeightMapResolution m_HeightMapResolutionCache = HeightMapResolution._128;

    RenderTexture m_SceneHeightRT;

    public RenderTexture SceneHeightRT//数据存储在m_SceneHeightRT。调用SceneHeightRT，当出现参数变化时，自动更新
    {
        get
        {
            if (m_SceneHeightRT == null || m_HeightMapResolutionCache != heightMapResolution)
            {
                m_SceneHeightRT?.Release();
                m_HeightMapResolutionCache = heightMapResolution;
                var size = (int)heightMapResolution;
                m_SceneHeightRT = RenderTexture.GetTemporary(size, size, 64, m_Format);
            }
            return m_SceneHeightRT;
        }
        set
        {
            m_SceneHeightRT = value;
        }
    }

    [SerializeField] private Matrix4x4 m_SceneHeightMatrixVP;
     private HeightMapRenderPass m_ScriptablePass;
    public static Matrix4x4 SceneHeightMatrixVP;

    private void OnValidate()
    {
        LockEdit = m_LockEdit;//修改值 触发set
        Init();
    }
    private void OnEnable()//加入pass 确定RenderPassEvent
    {
        LockEdit = m_LockEdit;
        Init();
        SceneHeightMatrixVP = m_SceneHeightMatrixVP;
#if UNITY_EDITOR

        m_ScriptablePass = new HeightMapRenderPass(SceneHeightRT)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
        RenderPipelineManager.beginCameraRendering += BeginCameraRendering;
#endif
    }
    private void OnDisable()//取消pass
    {
#if UNITY_EDITOR
        m_SceneHeightRT?.Release();
        m_HeightMapShader = null;
        RenderPipelineManager.beginCameraRendering -= BeginCameraRendering;
#endif 
    }

    void Init()//初始化相机的固定数据
    {
        m_Camera = GetComponent<Camera>();
        m_Camera.transform.rotation = Quaternion.Euler(90, 0, 0);
        m_Camera.depth = -1;
        m_Camera.targetTexture = SceneHeightRT;
        // m_Camera.SetReplacementShader(HeightMapShader, "");
        if (Application.isPlaying)
        {
            m_Camera.enabled = false;
        }
        m_SceneHeightMatrixVP = GetMatrixVP();//得到世界矩阵和投影矩阵
    }

    private Matrix4x4 GetMatrixVP()//得到世界矩阵和投影矩阵
    {
        Matrix4x4 ProjectionMatrix = GL.GetGPUProjectionMatrix(m_Camera.projectionMatrix, false);
        return ProjectionMatrix * m_Camera.worldToCameraMatrix;
    }

    public bool IsChanged()//判断当前矩阵和上一个矩阵是否相同
    {
        var matrixVP = GetMatrixVP();
        return !matrixVP.Equals(m_SceneHeightMatrixVP);
    }

    private void Update()
    {
        SetCameraParms();
    }

    private void SetCameraParms()//实时修改相机数据
    {
        if (m_Camera)
        {
            m_Camera.orthographic = true;
            m_Camera.clearFlags = CameraClearFlags.Color;
            m_Camera.backgroundColor = Color.white;
            m_Camera.allowMSAA = false;
            m_Camera.allowHDR = false;
        }
    }

    private void BeginCameraRendering(ScriptableRenderContext context, Camera camera)//根据形参camera 的到相机的renderer 将数据成员m_ScriptablePass加入到renderer
    {
        CameraType cameraType = camera.cameraType;
        if (cameraType == CameraType.Preview || !camera.gameObject.Equals(gameObject)) return;


        ScriptableRenderer renderer = camera.GetUniversalAdditionalCameraData().scriptableRenderer;

        renderer.EnqueuePass(m_ScriptablePass);
    }

    class HeightMapRenderPass : ScriptableRenderPass//渲染的具体逻辑 构造函数传入渲染数据
    {
        ProfilingSampler m_profilingSample = new ProfilingSampler("HeightMapRender");
        RenderTexture m_SceneHeightRT;
        FilteringSettings m_FilteringSettings;
        ShaderTagId m_ShaderTagId = new ShaderTagId("UniversalForward");
        Material m_OverrideMaterial;
        


        public HeightMapRenderPass(RenderTexture target)
        {
            m_SceneHeightRT = target;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.all);
            m_OverrideMaterial = CoreUtils.CreateEngineMaterial(m_HeightMapShaderName);
        } 
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            Camera camera = renderingData.cameraData.camera;
            CommandBuffer cmd = CommandBufferPool.Get();

            DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData,
                renderingData.cameraData.defaultOpaqueSortFlags);
            drawingSettings.overrideMaterial = m_OverrideMaterial;
            drawingSettings.overrideMaterialPassIndex = 0;

            using(new ProfilingScope(cmd,m_profilingSample))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                cmd.SetRenderTarget(m_SceneHeightRT);
                cmd.ClearRenderTarget(true, true, Color.white);

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

        }
    }
}
