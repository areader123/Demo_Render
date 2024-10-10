using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//视锥体剔除 避免传入不在摄像机里面的点对应的localToWorldMatric的矩阵
public class FrustumVIewCulling : MonoBehaviour
{
    [Range(1, 500000)]
    public int instanceCount = 10000;
    [Range(1, 1000)]
    public float radius = 100;
    public Mesh instanceMesh;
    public Material instanceMaterial;
    public bool enableCulling = true;
    public float offsetDistance = 1;
    private bool cachedEnableKillOut = false;
    private int cachedInstanceCount = -1;
    private float cachedInstanceRadius = -1;
    private float cachedDistance = -1;
    private ComputeBuffer localToWorldBuffer;
    private int instanceRealCount = 1;

    private Camera m_Camera;

    private void OnEnable() {
        m_Camera = GetComponent<Camera>();
         UpdateBuffers();
    }
    private void Update() {
          if (cachedInstanceCount != instanceCount || cachedInstanceRadius != radius || cachedEnableKillOut != enableCulling || cachedDistance != offsetDistance)
            UpdateBuffers();
         Graphics.DrawMeshInstancedProcedural(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, new Vector3(radius, radius, radius)), instanceRealCount);
    }

    void UpdateBuffers()
    {
        Random.InitState(1);//?????
        List<Matrix4x4> matrix4X4s = new List<Matrix4x4>();

        if(localToWorldBuffer != null)
        {
            localToWorldBuffer.Release();
        }

        for(int i = 0; i < instanceCount;i++)
        {
            var randPos = Random.insideUnitSphere * radius;
            if(enableCulling)
            {
                if(IsPointInFrustum(randPos))
                {
                    matrix4X4s.Add(Matrix4x4.TRS(randPos, Quaternion.identity,Vector3.one));
                }
            }else
            {
                 matrix4X4s.Add(Matrix4x4.TRS(randPos, Quaternion.identity, Vector3.one));
            }
        }
        localToWorldBuffer = new ComputeBuffer(matrix4X4s.Count,4*4*4);
        localToWorldBuffer.SetData(matrix4X4s);
        instanceMaterial.SetBuffer("localToWorldBuffer",localToWorldBuffer);
        instanceRealCount = matrix4X4s.Count;
        cachedInstanceCount = instanceCount;
        cachedInstanceRadius = radius;
        cachedEnableKillOut = enableCulling;
        cachedDistance = offsetDistance;

    }

    bool IsPointInFrustum(Vector3 point)
    {
        Plane[] planes =  GeometryUtility.CalculateFrustumPlanes(m_Camera);
        //基于camera 得到6个视锥体的plane
        for(int i = 0; i < planes.Length;i++)
        {
            var plane = Plane.Translate(planes[i], planes[i].normal * offsetDistance);//对plane进行偏移
             if (!plane.GetSide(point))//判断点是否在plane内
            {
                return false;
            }
        }
        return true;
    }
        void OnDisable()
    {
        if (localToWorldBuffer != null)
            localToWorldBuffer.Release();
        localToWorldBuffer = null;
    }

}
