using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using TMPro;
using UnityEngine;
[ExecuteInEditMode]
public class Grass : MonoBehaviour
{
    [Range(1, 100)]
    public int grassCount = 1;
    [Range(1, 1000)]
    public float radius = 100;
    public Mesh grassMesh;
    public Material grassMaterial;
    // 草面片大小
    public Vector2 grassQuadSize = new Vector2(0.1f, 0.6f);
    // 交互对象
    public Transform playerTrs;
    // 碰撞范围
    [Range(0, 10)]
    public float crashRadius;
    // 下压强度
    [Range(0, 100)]
    public float pushStrength;

    private int cachedGrassCount = -1;
    private Vector2 cachedGrassQuadSize;

    private ComputeBuffer grassBuffer;
    private Mesh terrianMesh;
    private int grassTotalCount;

    private RenderTexture pathRenderTexture;

      void Start()
    {
        terrianMesh = GetComponent<MeshFilter>().sharedMesh;
        // CreatePathRenderTexture();
        UpdateBuffers();
    }


    private void Update() {
         if (cachedGrassCount != grassCount || !cachedGrassQuadSize.Equals(grassQuadSize))
            UpdateBuffers();
        //当修改暴露的参数时，调用 UpdateBuffers() 更新buffer

        Vector4 playerPos = playerTrs.TransformPoint(Vector3.zero);//?
        playerPos.w = crashRadius;
        grassMaterial.SetVector("_PlayerPos", playerPos);
        grassMaterial.SetFloat("_PushStrength", pushStrength);

        Graphics.DrawMeshInstancedProcedural(grassMesh, 0,grassMaterial,new Bounds(Vector3.zero,new Vector3(radius,radius,radius)),grassTotalCount);

    }

    private void UpdateBuffers()
    {
        if (terrianMesh == null)
            terrianMesh = GetComponent<MeshFilter>().sharedMesh;

        if (grassBuffer != null)
            grassBuffer.Release();
        List<GrassInfo> grassInfos = new List<GrassInfo>();

        grassTotalCount = 0;

        //得到plane的三角形
        var triIndex = terrianMesh.triangles;
        var vertices = terrianMesh.vertices;
        var len = triIndex.Length;
        //遍历所有三角形的三个顶点
        for(var i = 0; i < len; i += 3)
        {
            var vertex1 = vertices[triIndex[i]];
            var vertex2 = vertices[triIndex[i + 1]];
            var vertex3 = vertices[triIndex[i + 2]];

            Vector3 normal = CalculateTriangleNormal(vertex1, vertex2, vertex3);
            //在每一个三角形上生成一个变换矩阵 让每一个GUPInstance出来的quad变换到 
            //通过plane原有顶点生成的新顶点上，并附带旋转
            for(int j = 0 ; j < grassCount; j++)
            {
                 //贴图参数，暂时不用管 用于贴图的变换
                Vector2 texScale = Vector2.one;
                Vector2 texOffset = Vector2.zero;
                Vector4 texParams = new Vector4(texScale.x, texScale.y, texOffset.x, texOffset.y);
                //三角形 重心坐标 随机点
                Vector3 randPos = RandomTriangle(vertex1,vertex2,vertex3);
                //
                randPos += normal.normalized * 0.5f * grassQuadSize.y;
                Quaternion upToNormal = Quaternion.FromToRotation(Vector3.up,normal);
                float rot = UnityEngine.Random.Range(0, 180);
                //构造变换矩阵
                //randPos 属于plane 所以用transform
                var localToWorld = Matrix4x4.TRS(transform.TransformPoint(randPos), upToNormal * Quaternion.Euler(0, rot, 0), Vector3.one);
                GrassInfo grassInfo = new GrassInfo()
                {
                    localToWorld = localToWorld,
                    texParams = texParams
                };

                grassInfos.Add(grassInfo);
                grassTotalCount++;
            }
        }
        grassBuffer = new ComputeBuffer(grassTotalCount,64+16);
        grassBuffer.SetData(grassInfos);
        grassMaterial.SetBuffer("_GrassInfoBuffer", grassBuffer);
        grassMaterial.SetVector("_GrassQuadSize", grassQuadSize);
        cachedGrassCount = grassCount;
        cachedGrassQuadSize = grassQuadSize;
    }

    void OnDisable()
    {
        if (grassBuffer != null)
            grassBuffer.Release();
        grassBuffer = null;
    }
    public static Vector3 RandomTriangle(Vector3 A, Vector3 B, Vector3 C)
    {
        // 重心坐标
        float randomX = UnityEngine.Random.Range(0, 1f);
        float randomY = UnityEngine.Random.Range(0, 1 - randomX);
        float randomZ = 1 - randomX - randomY;
        return A * randomX + B * randomY + C * randomZ;
    }

    public static Vector3 CalculateTriangleNormal(Vector3 p1, Vector3 p2, Vector3 p3)
    {
        var vx = p2 - p1;
        var vy = p3 - p1;
        return Vector3.Cross(vx, vy);
    }

    struct GrassInfo
    {
        public Matrix4x4 localToWorld;
        public Vector4 texParams;
    }
}
