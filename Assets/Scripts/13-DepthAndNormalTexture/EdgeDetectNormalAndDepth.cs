using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetectNormalAndDepth : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material _edgeDetectMaterial;
    
    public Material material
    {
        get
        {
            // edgeDetectShader是我们指定的Shader，对应了后面将会实现的EdgeDetectNormalAndDepth.shader，_edgeDetectMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, _edgeDetectMaterial);
            return _edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float edgesOnly = 0.0f;
    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
    public float sampleDistance = 1.0f;                 // 控制对深度 + 法线纹理采样时，使用的采样距离（视觉上看，sampleDistance值越大，描边越宽）
    public float sensitivityDepth = 1.0f;               // 邻域深度值相差值
    public float sensitivityNormals = 1.0f;             // 邻域法线值相差值

    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    [ImageEffectOpaque] private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // 这里需要添加[ImageEffectOpaque]属性，表示只在非透明Shader执行完之后调用，而不对透明Shader起效果
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor" ,backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }
}
