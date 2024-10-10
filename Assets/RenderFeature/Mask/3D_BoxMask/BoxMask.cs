using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteAlways]
public class BoxMask : MonoBehaviour
{
    [SerializeField] private Material BoxMaskMaterial;
    [SerializeField]Transform centerTransform;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        BoxMaskMaterial.SetVector("_MaskCenter",centerTransform.position);
    }
}
