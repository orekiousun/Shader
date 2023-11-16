using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material _motionBlurMaterial = null;
    
    public Material material
    {
        get
        {
            // motionBlurShader是我们指定的Shader，对应了后面将会实现的MotionBlurWithDepthTexture.shader，_motionBlurMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, _motionBlurMaterial);
            return _motionBlurMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float blurSize = 0.5f;
    private Camera _myCamera;
    public Camera camera
    {
        get
        {
            if (_myCamera == null)
            {
                _myCamera = GetComponent<Camera>();
            }
            return _myCamera;
        }
    }

    private Matrix4x4 _previousViewProjectionMatrix;  // 保存上一帧摄像机的视角 * 投影矩阵

    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src">源纹理</param>
    /// <param name="dest">最终渲染纹理</param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            // 计算和传递运动模糊使用的各个属性
            material.SetFloat("_BlurSize", blurSize);
            material.SetMatrix("_PreviousViewProjectionMatrix", _previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;  // 分别得到当前摄像机的视角和投影矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
            _previousViewProjectionMatrix = currentViewProjectionMatrix;
            
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
        _previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
    }
}
