using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Main_Camera : MonoBehaviour
{
    new Camera camera ;
    float nearClipPlane;
    [SerializeField] Material underMaterial;
    // Start is called before the first frame update
    void Start()
    {
        camera = GetComponent<Camera>();
        nearClipPlane = camera.nearClipPlane;

    }

    // Update is called once per frame
    void Update()
    {
        GetCorner();
    }

    private void GetCorner()
    {
        float size = camera.orthographicSize;
        underMaterial.SetFloat("_Size",size);
        Vector4[] corners = new Vector4[4];

        // 左下
        corners[0] = camera.ViewportToWorldPoint(new Vector3(0.0f, 0.0f, nearClipPlane));
        // 右下
        corners[1] = camera.ViewportToWorldPoint(new Vector3(1.0f, 0.0f, nearClipPlane));
        // 左上
        corners[2] = camera.ViewportToWorldPoint(new Vector3(0.0f, 1.0f, nearClipPlane));
        // 右上
        corners[3] = camera.ViewportToWorldPoint(new Vector3(1.0f, 1.0f, nearClipPlane));

        underMaterial.SetVectorArray("_CameraCorner", corners);
    }

}
