using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UI;

public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material _edgeDetectMaterial;
    
    public Material material
    {
        get
        {
            // edgeDetectShader是我们指定的Shader，对应了后面将会实现的EdgeDetection.shader，_briSatConMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, _edgeDetectMaterial);
            return _edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float edgesOnly = 0.0f;   // 边缘线浅强度
    public Color edgeColor = Color.black;                // 描边颜色
    public Color backgroundColor = Color.white;          // 背景颜色
    
    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
