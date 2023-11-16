using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material _motionBlurMaterial;
    
    public Material material
    {
        get
        {
            // motionBlurShader是我们指定的Shader，对应了后面将会实现的MotionBlur.shader，_motionBlurMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, _motionBlurMaterial);
            return _motionBlurMaterial;
        }
    }

    [Range(0.0f, 0.9f)] public float blurAmount = 0.5f;  // blurAmount的值越大，运动的拖尾效果就越明显。为了防止拖尾效果完全替代当前帧的渲染结果，我们把它的值截取在0.0-0.9范围内 
    private RenderTexture _accumulationTexture;          // 定义一个RenderTexture类型的变量，保存之前图像叠加的结果

    private void OnDisable()
    {
        DestroyImmediate(_accumulationTexture);
    }

    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            // 创建_accumulationTexture
            if (_accumulationTexture == null || _accumulationTexture.width != src.width || _accumulationTexture.height != src.height)
            {
                // 判断_accumulationTexture是否满足条件，包括是否为空和分辨率是否满足，如果不满足就重新生成一个并把源纹理渲染进_accumulationTexture
                DestroyImmediate(_accumulationTexture);
                _accumulationTexture = new RenderTexture(src.width, src.height, 0);
                // 由于我们会自己控制该变量的销毁，因此可以把它的hideFlags设置为HideAndDontSave，这意味着这个变量不会显示在Hierarchy中，也不会保存在场景中
                _accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, _accumulationTexture);
            }
            // MarkRestoreExpected表明需要进行一个渲染纹理的恢复操作，恢复操作（restore operation）发生在渲染到纹理而该纹理又没有被提前清空或销毁的情况下
            // 我们每次调用OnRenderImage是需要把当前的帧图像和_accumulationTexture中的图像混合， _accumulationTexture纹理不需要提前清空，因为它保存了我们之前的混合结果
            // _accumulationTexture.MarkRestoreExpected();
            material.SetFloat("_BlurAmount", 1.0f - blurAmount);
            Graphics.Blit(src, _accumulationTexture, material);
            Graphics.Blit(_accumulationTexture, dest);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
