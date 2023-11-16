using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material _bloomMaterial;
    
    public Material material
    {
        get
        {
            // bloomShader是我们指定的Shader，对应了后面将会实现的Bloom.shader，_bloomMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, _bloomMaterial);
            return _bloomMaterial;
        }
    }

    [Range(0, 4)] public int iterations = 3;
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;
    [Range(1, 8)] public int downSample = 2;
    [Range(0.0f, 4.0f)] public float luminanceThreshold = 0.6f;

    /// <summary>
    /// 与高斯模糊代码基本一致
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // 利用缩放对图像进行降采样，从而减少需要处理的像素个数，提高性能
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            // 声明缓冲区大小时，使用了小于原屏幕分辨率的尺寸，并将该临时渲染纹理的滤波模式设置为双线性
            // 这样，在调用第一个pass时，我们需要处理的像素个数就是原来的几分之一，适当的降采样不仅可以提高性能，还可以得到更好的模糊效果
            int rtW = src.width/downSample;
            int rtH = src.height/downSample;
            // 由于高斯模糊需要调用两个Pass，我们需要使用一块中间缓存来存储第一个Pass执行完毕后得到的模糊结果
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);   // 分配一块缓冲区
            buffer0.filterMode = FilterMode.Bilinear;
            
            // 1.pass0提取处图像中的较亮区域，存储在buffer0中
            Graphics.Blit(src, buffer0, material, 0);  // 调用第0个pass，将源纹理经过material处理后的结果渲染进buffer0中
            
            // 2.pass1和pass2分别进行纵向和横向的高斯模糊，模糊后的较亮区域会存储在buffer0中
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);  // 调用第1个pass，将buffer0经过material处理后的结果渲染进buffer1中
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 2);  // 调用第2个pass，再将buffer0经过material处理后的结果渲染进buffer1中
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            
            // 3.把buffer0传递给材质中的_Bloom纹理属性，并使用最后一个pass来进行最后的混合，将结果存储在目标渲染纹理dest中
            material.SetTexture("_Bloom", buffer0);    // 将buffer0设置为_Bloom纹理
            Graphics.Blit(src, dest, material, 3);      // 将源纹理通过第3个pass渲染到dest中
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
