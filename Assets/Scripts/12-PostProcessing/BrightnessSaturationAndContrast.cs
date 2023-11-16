using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{
    public Shader briSatConShader;
    private Material _briSatConMaterial;
    
    public Material material
    {
        get
        {
            // briSatConShader是我们指定的Shader，对应了后面将会实现的BrightnessSaturationAndContrast.shader，_briSatConMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, _briSatConMaterial);
            return _briSatConMaterial;
        }
    }

    [Range(0.0f, 3.0f)] public float brightness = 1.0f;
    [Range(0.0f, 3.0f)] public float saturation = 1.0f;
    [Range(0.0f, 3.0f)] public float contrast = 1.0f;
    
    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Contrast", contrast);
            
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
