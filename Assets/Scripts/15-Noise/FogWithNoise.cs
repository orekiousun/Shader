using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithNoise : PostEffectsBase
{
    public Shader fogShader;
    private Material _fogMaterial = null;
    
    public Material material
    {
        get
        {
            // fogShader是我们指定的Shader，对应了后面将会实现的FogWithNoise.shader，_bloomMaterial是创建的材质，我们提供了名为Material的材质来访问它 
            _fogMaterial = CheckShaderAndCreateMaterial(fogShader, _fogMaterial);
            return _fogMaterial;
        }
    }

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

    private Transform _myCameraTransform;

    public Transform cameraTransform
    {
        get
        {
            if (_myCamera == null)
            {
                _myCameraTransform = camera.transform;
            }
            return _myCameraTransform;
        }
    }

    [Range(0.1f, 3.0f)] public float fogDensity = 1.0f;   // 控制雾的浓度
    public Color fogColor = Color.white;                  // 控制雾的颜色
    public float fogStart = 0.0f;                         // 控制雾的起始高度
    public float fogEnd = 2.0f;                           // 控制雾的终止高度
    public Texture noiseTexture;                          // 使用的噪声纹理
    [Range(-0.5f, 0.5f)] public float fogXSpeed = 0.1f;   // 噪声纹理在X方向上的移动速度
    [Range(-0.5f, 0.5f)] public float fogYSpeed = 0.1f;   // 噪声纹理在Y方向上的移动速度
    [Range(0.0f, 3.0f)] public float noiseAmount = 1.0f;  // 控制噪声程度

    /// <summary>
    /// 调用时会检查材质是否可用，如果可用就把参数传递给材质，再调用Graphics.Blit进行处理，否则，直接把原图像显示到屏幕上，不做任何处理
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;
            
            // 
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float aspect = camera.aspect;
			
            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop = cameraTransform.up * halfHeight;
			
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
			
            topLeft.Normalize();
            topLeft *= scale;
			
            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;
			
            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;
			
            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;
			
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);
            
            material.SetMatrix("_FrustumCornersRay", frustumCorners);
            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);
            
            material.SetTexture("_NoiseTex", noiseTexture);
            material.SetFloat("_FogXSpeed", fogXSpeed);
            material.SetFloat("_FogXSpeed", fogYSpeed);
            material.SetFloat("_NoiseAmount", noiseAmount);
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
    
}
