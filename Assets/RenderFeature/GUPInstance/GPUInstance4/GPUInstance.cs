using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GPUInstance : MonoBehaviour
{
    [Range(1,500000)]
    public int instanceCount = 10000;
    [Range(1,1000)]
    public float radius = 100;
    public Mesh instanceMesh;
    public Material instanceMaterial;
    //随便找个位置做随机
    public Transform target;

    private int cachedInstanceCount = -1;
    private float cachedInstanceRadius = -1;
    private ComputeBuffer localToWorldBuffer;
    private void Start()
    {
        UpdateBuffers();    
    }

    private void Update() 
    {
        if(cachedInstanceCount != instanceCount || cachedInstanceRadius != radius)
        {
            UpdateBuffers();
        }    
        Graphics.DrawMeshInstancedProcedural(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, new Vector3(radius, radius, radius)), instanceCount);
    }

    void UpdateBuffers()
    {
        Matrix4x4[] matrix4X4s = new Matrix4x4[instanceCount];
        if(localToWorldBuffer != null)
        {
            localToWorldBuffer.Release();
        }
        localToWorldBuffer = new ComputeBuffer(instanceCount, 4*4*4);
        for(int i = 0; i < instanceCount; i++) 
        {
            target.position = Random.onUnitSphere * radius;
            matrix4X4s[i] = target.localToWorldMatrix;    
        }
        localToWorldBuffer.SetData(matrix4X4s);
        instanceMaterial.SetBuffer("localToWorldBuffer",localToWorldBuffer);
        cachedInstanceCount = instanceCount;
        cachedInstanceRadius = radius;
    }

    private void OnDisable() 
    {
        if(localToWorldBuffer != null)
        {
            localToWorldBuffer.Release();
        }    
        localToWorldBuffer = null;
    }

    
}
