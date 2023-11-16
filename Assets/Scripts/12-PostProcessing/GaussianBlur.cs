using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material _gaussianBlurMaterial;
    
    public Material material
    {
        get
        {
            // gaussianBlurShader是我们指定的Shader，对应了后面将会实现的GaussianBlur.shader，_gaussianBlurMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, _gaussianBlurMaterial);
            return _gaussianBlurMaterial;
        }
    }

    [Range(0, 4)] public int iterations = 3;              // 高斯模糊迭代次数
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;   // 模糊范围，对应GaussianBlur.shader中的_BlurSize，越大取得的采样点间距越大
    [Range(1, 8)] public int downSample = 2;              // 缩放系数

    #region Edition1: just apply blur

    // /// <summary>
    // /// Edition1: just apply blur
    // /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    // /// </summary>
    // /// <param name="src"></param>
    // /// <param name="dest"></param>
    // private void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {
    //     if (material != null)
    //     {
    //         int rtW = src.width;
    //         int rtH = src.height;
    //         // 由于高斯模糊需要调用两个Pass，我们需要使用一块中间缓存来存储第一个Pass执行完毕后得到的模糊结果
    //         RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);   // 分配一块与屏幕图像大小相同的缓冲区
    //
    //         // Render the vertical pass
    //         Graphics.Blit(src, buffer, material, 0);                                            // 使用Shader中的第一个Pass对src进行处理，并将结果存储在buffer中
    //         // Render the horizontal pass
    //         Graphics.Blit(buffer, dest, material, 1);                                           // 使用Shader中的第二个Pass对上一次处理的结果buffer进行处理，并将结果存储在dest中，返回最终的屏幕图像
    //         
    //         RenderTexture.ReleaseTemporary(buffer);                                                   // 释放之前分配的内存
    //     }
    //     else
    //     {
    //         Graphics.Blit(src, dest);
    //     }
    // }

    #endregion

    #region Edition2: Scale the render Texture

    // /// <summary>
    // /// Edition2: Scale the render Texture 
    // /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    // /// </summary>
    // /// <param name="src"></param>
    // /// <param name="dest"></param>
    // private void OnRenderImage(RenderTexture src, RenderTexture dest)
    // {
    //     // 利用缩放对图像进行降采样，从而减少需要处理的像素个数，提高性能
    //     if (material != null)
    //     {
    //         // 声明缓冲区大小时，使用了小于原屏幕分辨率的尺寸，并将该临时渲染纹理的滤波模式设置为双线性
    //         // 这样，在调用第一个pass时，我们需要处理的像素个数就是原来的几分之一，适当的降采样不仅可以提高性能，还可以得到更好的模糊效果
    //         int rtW = src.width/downSample;
    //         int rtH = src.height/downSample;
    //         // 由于高斯模糊需要调用两个Pass，我们需要使用一块中间缓存来存储第一个Pass执行完毕后得到的模糊结果
    //         RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);   // 分配一块缓冲区
    //         buffer.filterMode = FilterMode.Bilinear;
    //         
    //         // Render the vertical pass
    //         Graphics.Blit(src, buffer, material, 0);                                            // 使用Shader中的第一个Pass对src进行处理，并将结果存储在buffer中
    //         // Render the horizontal pass
    //         Graphics.Blit(buffer, dest, material, 1);                                           // 使用Shader中的第二个Pass对上一次处理的结果buffer进行处理，并将结果存储在dest中，返回最终的屏幕图像
    //         
    //         RenderTexture.ReleaseTemporary(buffer);                                                   // 释放之前分配的内存
    //     }
    //     else
    //     {
    //         Graphics.Blit(src, dest);
    //     }
    // }

    #endregion

    #region Edition3: use iteration for larger blur

    /// <summary>
    /// Edition3: use iteration for larger blur
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // 利用缩放对图像进行降采样，从而减少需要处理的像素个数，提高性能
        if (material != null)
        {
            // 声明缓冲区大小时，使用了小于原屏幕分辨率的尺寸，并将该临时渲染纹理的滤波模式设置为双线性
            // 这样，在调用第一个pass时，我们需要处理的像素个数就是原来的几分之一，适当的降采样不仅可以提高性能，还可以得到更好的模糊效果
            int rtW = src.width/downSample;
            int rtH = src.height/downSample;
            // 由于高斯模糊需要调用两个Pass，我们需要使用一块中间缓存来存储第一个Pass执行完毕后得到的模糊结果
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);   // 分配一块缓冲区
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src, buffer0);   // 将源纹理渲染到buffer0中

            for (int i = 0; i < iterations; i++)
            {
                // 将buffer0作为最终渲染目标
                // 1.将buffer0作为源纹理，渲染第一个pass到buffer1中，清空buffer0，将buffer1赋值给buffer0（此时buffer0中保存了上一步的渲染结果）
                // 2.buffer0作为上一步渲染的结果源纹理，再次渲染第二个的pass到buffer1中，再次清空buffer0，将buffer1赋值给buffer0（此时buffer0中保存了上一步的渲染结果）
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 0);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            
            Graphics.Blit(buffer0, dest);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

    #endregion
}
