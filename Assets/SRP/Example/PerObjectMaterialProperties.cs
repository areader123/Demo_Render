using System;
using UnityEngine;

// 禁止一个GameObject挂载多个该脚本
[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour{
    private static int baseColorId = Shader.PropertyToID("_BaseColor");
    
    // 使用MaterialPropertyBlock，表示想要使用相同的材质绘制不同的物体，但每个物体的属性不同
    // 这会使SRP Batcher失效
    private static MaterialPropertyBlock block;
    
    // 在材质面板上显示该属性
    [SerializeField] private Color baseColor = Color.white;

    void Awake() {
        
    }

    // Editor-only function that Unity calls when the script is loaded or a value changes in the Inspector.
    // Use this to perform an action after a value changes in the Inspector; for example, making sure that data stays within a certain range.
    private void OnValidate() {
        if (block == null)
            block = new MaterialPropertyBlock();
        block.SetColor(baseColorId, baseColor);
        GetComponent<Renderer>().SetPropertyBlock(block);
    }
}