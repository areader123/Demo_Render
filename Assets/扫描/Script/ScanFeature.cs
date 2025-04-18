using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Random = UnityEngine.Random;
using DG.Tweening;
using System;
using Unity.Profiling;
using UnityEngine.Serialization;

public class ScanFeature : ScriptableRendererFeature
{
    public Settings settings;
    static ScanFeature _instance;
    CustomRenderPass m_ScriptablePass;

    [System.Serializable]
    public class Settings
    {
        public Material scanMaterial;
        public int blitMaterialPassIndex = 0;
        public Color scanMaterialColor = Color.black;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;


        [Header("Static Settings")] public Color scanColorHead = Color.blue;
        public Color scanColor = Color.blue;
        public float outlineWidth = 0.1f;
        public float scanLineWidth = 1f;
        public float scanLineInterval = 1f;
        public float headScanLineWidth = 1f;

        [Header("Dynamics Settings(control by code)")]
        public float scanLineBrightness = 1f;

        public float scanRange = 1f;
        public float outlineBrightness = 1f;
        public float headScanLineDistance = 8f;
        public Vector3 scanCenterWS = new Vector3(468.1f, -13f, -31.6f);
        public float outlineStarDistance = 30f;

        [Header("Render Mark")] public Material markMaterial;
        public GameObject markParticle3;
        public GameObject markParticle2;
        public GameObject markParticle1;
    }

    readonly static int ScanColorHead = Shader.PropertyToID("scanColorHead");
    readonly static int ScanColor = Shader.PropertyToID("scanColor");

    readonly static int OutlineWidth = Shader.PropertyToID("outlineWidth");
    readonly static int OutlineBrightness = Shader.PropertyToID("outlineBrightness");
    readonly static int OutlineStarDistance = Shader.PropertyToID("outlineStarDistance");

    readonly static int ScanLineWidth = Shader.PropertyToID("scanLineWidth");
    readonly static int ScanLineInterval = Shader.PropertyToID("scanLineInterval");
    readonly static int ScanLineBrightness = Shader.PropertyToID("scanLineBrightness");
    readonly static int ScanRange = Shader.PropertyToID("scanRange");

    readonly static int HeadScanLineDistance = Shader.PropertyToID("headScanLineDistance");
    readonly static int HeadScanLineWidth = Shader.PropertyToID("headScanLineWidth");
    readonly static int HeadScanLineBrightness = Shader.PropertyToID("headScanLineBrightness");
    readonly static int ScanCenterWs = Shader.PropertyToID("scanCenterWS");

    // 地形标记的参数
    readonly static int ColorAlpha = Shader.PropertyToID("colorAlpha");

    static bool canScan = true;
    static bool showMark = false;
    static Tween markTween;

    public static void ExecuteScan(Transform _player)
    {
        StartScan(_player);
    }


    public static void StartScan(Transform player)
    {
        if (!canScan)
        {
            return;
        }

        canScan = false;
        showMark = true;
        markTween?.Kill();
        var scanCenter = player.position - player.forward * 2;
        //
        var material = _instance.settings.scanMaterial;
        var markMaterial = _instance.settings.markMaterial;
        
        material.SetVector(ScanCenterWs, scanCenter);

        // 控制扫描线前进
        material.SetFloat(HeadScanLineDistance, 4);
        material.DOFloat(250, HeadScanLineDistance, 3.5f).SetEase(Ease.InSine).onComplete += () => { canScan = true; };


        // 随着距离前进，扫描范围变大
        material.SetFloat(ScanRange, 1);
        material.DOFloat(5, ScanRange, 1.5f).SetEase(Ease.InSine).SetDelay(1);

        // 控制扫描线和最前方的扫描线颜色颜色
        material.SetFloat(ScanLineBrightness, 0.3f);
        material.SetFloat(HeadScanLineBrightness, 0);
        material.DOFloat(1, ScanLineBrightness, 0.2f).SetDelay(0.25f);
        material.DOFloat(1, HeadScanLineBrightness, 0.1f).SetDelay(0.25f);
        material.DOFloat(0, ScanLineBrightness, 0.5f).SetDelay(2.25f).SetEase(Ease.Linear);
        material.DOFloat(0, HeadScanLineBrightness, 0.5f).SetDelay(2.25f).SetEase(Ease.Linear);

        // 控制轮廓
        material.SetFloat(OutlineBrightness, 1);
        material.SetFloat(OutlineStarDistance, 0);
        material.DOFloat(0, OutlineBrightness, 0.5f).SetDelay(2.25f).SetEase(Ease.Linear);
        material.DOFloat(30, OutlineStarDistance, 1f).SetEase(Ease.InCubic);
        
        // 控制地形标记的透明度
        // markMaterial.SetFloat( ColorAlpha, 0 );
        // markMaterial.DOFloat( 1, ColorAlpha, 1f );
        // markTween = markMaterial.DOFloat( 0, ColorAlpha, 1f ).SetDelay( 7 );
        // markTween.onComplete += () => {
        //     showMark = false;
        // };
        
        GenerateTerrainMarks(player);
    }

    struct Marks
    {
        public Vector3 markPosition;
        public int markCategory;
    }

    static Marks[] _marks; // 存每个标记的数据
    const int horizentalCount = 7; // 横向的列数
    const int verticalCount = 5; // 向前的点行数
    const float gridStep = .5f; // 两个点之间的距离


    static void ShootParticle(Vector3 position, Vector3 normal, int index = 3)
    {
        float distanceToCamera01 = Vector3.Distance(position, Camera.main.transform.position) / 20 + 0.5f;

        GameObject instance;
        switch (index)
        {
            case 3:
                instance = Instantiate(_instance.settings.markParticle3);
                break;
            case 2:
                instance = Instantiate(_instance.settings.markParticle2);
                break;
            default:
                instance = Instantiate(_instance.settings.markParticle1);
                break;
        }

        instance.transform.position = position;
        instance.transform.localScale = Random.Range(0.5f, 1.5f) * Vector3.one * distanceToCamera01;
        instance.transform.GetChild(0).localScale = Random.Range(2f, 5f) * Vector3.one * distanceToCamera01;
    }


    public static void GenerateTerrainMarks(Transform player)
    {
        // 每次扫描前清空数组
        Array.Clear(_marks, 0, _marks.Length);
        var forward = player.forward;
        var right = player.right;


        // 把撒点的初始位置顶到角色头顶的左后方
        Vector3 position = player.position - forward * 2 + Vector3.up * 100;
        var rayCastPos = position - right * horizentalCount / 2 * gridStep - forward * (3 * gridStep);

        // 横向纵向套两个循环，不断碰撞检测和写入数组
        for (int i = 0; i < verticalCount; i++)
        {
            for (int j = 0; j < horizentalCount; j++)
            {
                Physics.Raycast(rayCastPos, Vector3.down, out RaycastHit hit, 300, LayerMask.GetMask("Scan", "Road"));
                if (hit.collider is null)
                {
                    rayCastPos += right * gridStep;
                    continue;
                }

                var normal = hit.normal;

                // 根据法线的纵向值来判断斜率，设置该点的标志是什么
                if (hit.collider.isTrigger)
                {
                    Physics.Raycast(rayCastPos, Vector3.down, out hit, 300, LayerMask.GetMask("Scan"));
                    _marks[i * horizentalCount + j].markCategory = 0;
                    _marks[i * horizentalCount + j].markPosition = hit.point;
                }
                else if (normal.y < 0.75f)
                {
                    _marks[i * horizentalCount + j].markCategory = 3;
                    // 红叉只有33%的概率出现
                    if (Random.Range(0f, 1f) < 0.3f)
                    {
                        _marks[i * horizentalCount + j].markPosition = hit.point;
                        ShootParticle(hit.point, normal, 3);
                    }
                }
                else if (normal.y < 0.85f)
                {
                    _marks[i * horizentalCount + j].markCategory = 2;
                    _marks[i * horizentalCount + j].markPosition = hit.point;
                    if (Random.Range(0f, 1f) < 0.0003)
                    {
                        ShootParticle(hit.point, normal, 1);
                    }
                }
                else
                {
                    _marks[i * horizentalCount + j].markCategory = 1;
                    _marks[i * horizentalCount + j].markPosition = hit.point;
                    if (Random.Range(0f, 1f) < 0.0002)
                    {
                        ShootParticle(hit.point, normal, 1);
                    }
                }

                rayCastPos += right * gridStep;

                // debug 显示绘制
                if (hit.normal.y < 0.8f)
                {
                    Debug.DrawLine(hit.point, hit.point + hit.normal * 0.2f, Color.red, 10);
                }
                else if (hit.normal.y < 0.9f)
                {
                    Debug.DrawLine(hit.point, hit.point + hit.normal * 0.2f, Color.yellow, 10);
                }
                else
                {
                    Debug.DrawLine(hit.point, hit.point + hit.normal * 0.2f, Color.cyan, 10);
                }
            }


            rayCastPos -= right * horizentalCount * gridStep;
            rayCastPos += forward * gridStep;

            //每次生成一行地形标记后，等待一帧，并绘制当前帧的地形标记
        }
    }


    class CustomRenderPass : ScriptableRenderPass
    {
        string _passName;
        Settings _settings;
        private RenderTargetIdentifier _Color;
        private RenderTargetIdentifier _destination;
        private RenderTargetIdentifier _depth;
        private RenderTargetHandle tempRT;
        private RenderTextureDescriptor m_Descriptor;


        //GPU Instance
        GraphicsBuffer _graphicsBuffer;
        GraphicsBuffer.IndirectDrawIndexedArgs[] _commandData;
        ComputeBuffer _computeBuffer;


        Mesh mesh;

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _Color = renderingData.cameraData.renderer.cameraColorTarget;
            _depth = renderingData.cameraData.renderer.cameraDepthTarget;
            _destination = renderingData.cameraData.renderer.cameraColorTarget;
            m_Descriptor = renderingData.cameraData.cameraTargetDescriptor;
            tempRT.Init("_TempRT");
            cmd.GetTemporaryRT(tempRT.id, m_Descriptor, FilterMode.Bilinear);
           // ConfigureTarget(tempRT.Identifier());
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_settings.scanMaterial == null)
                return;
            if (renderingData.cameraData.camera.cameraType != CameraType.Game) return;
            CommandBuffer cmd = CommandBufferPool.Get(_passName);
            using (new ProfilingScope(cmd, new ProfilingSampler(cmd.name)))
            {
                //  Blitter.BlitCameraTexture(cmd,_depth,_Color,_settings.scanMaterial,_settings.blitMaterialPassIndex);
                Blit(cmd, _depth, _destination, _settings.scanMaterial, _settings.blitMaterialPassIndex);
                // Blit(cmd, tempRT.Identifier(), _destination);
                //if (showMark)
               // {
                   // cmd.SetRenderTarget(_Color,_depth);
                    var matProp = new MaterialPropertyBlock();
                    _computeBuffer.SetData( _marks );
                    matProp.SetBuffer( "markBuffer", _computeBuffer );
                    _commandData[0].indexCountPerInstance = 6;
                    _commandData[0].instanceCount = horizentalCount * verticalCount;
                    _graphicsBuffer.SetData( _commandData );
                   // cmd.DrawMeshInstancedIndirect( mesh, 0, _settings.markMaterial, 0, _graphicsBuffer, 0, matProp );
                    cmd.DrawMeshInstancedProcedural(mesh, 0, _settings.markMaterial, 0, 100,matProp);
                //}
            }

            Camera camera = Camera.main;
            _settings.scanMaterial.SetMatrix("_ViewToWorld", camera.cameraToWorldMatrix);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(tempRT.id);
        }

        public CustomRenderPass(Settings settings)
        {
            _passName = "ScanFeature";
            this._settings = settings;

            _graphicsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1,
                GraphicsBuffer.IndirectDrawIndexedArgs.size);
            _commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[1];
            _computeBuffer = new ComputeBuffer(horizentalCount * verticalCount, sizeof(float) * 4);
            
            mesh = new Mesh{
                vertices = new Vector3[6],
                uv = new[]{
                    new Vector2( 0, 0 ),
                    new Vector2( 1, 1 ),
                    new Vector2( 0, 1 ),
                    new Vector2( 0, 0 ),
                    new Vector2( 1, 0 ),
                    new Vector2( 1, 1 ),
                }
            };
            _settings.scanMaterial.SetVector(ScanCenterWs, _settings.scanCenterWS);


            _settings.scanMaterial.SetColor(ScanColorHead, _settings.scanColorHead);
            _settings.scanMaterial.SetColor(ScanColor, _settings.scanColor);
            _settings.scanMaterial.SetFloat(OutlineWidth, _settings.outlineWidth);
            _settings.scanMaterial.SetFloat(OutlineBrightness, _settings.outlineBrightness);
            _settings.scanMaterial.SetFloat(OutlineStarDistance, _settings.outlineStarDistance);

            _settings.scanMaterial.SetFloat(ScanLineWidth, _settings.scanLineWidth);
            _settings.scanMaterial.SetFloat(ScanLineInterval, _settings.scanLineInterval);
            _settings.scanMaterial.SetFloat(ScanLineBrightness, _settings.scanLineBrightness);
            _settings.scanMaterial.SetFloat(ScanRange, _settings.scanRange);

            _settings.scanMaterial.SetFloat(HeadScanLineDistance, _settings.headScanLineDistance);
            _settings.scanMaterial.SetFloat(HeadScanLineWidth, _settings.headScanLineWidth);

            // 
        }
    }


    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(settings);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = settings.renderPassEvent;
        _instance = this;
        _marks = new Marks[horizentalCount * verticalCount];
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.scanMaterial == null) return;
        if (!Application.isPlaying) return;
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            //声明要使用的颜色和深度缓冲区
            m_ScriptablePass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_ScriptablePass.ConfigureInput(ScriptableRenderPassInput.Normal);
            m_ScriptablePass.ConfigureInput(ScriptableRenderPassInput.Depth);
        }

        renderer.EnqueuePass(m_ScriptablePass);
    }
}