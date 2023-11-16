using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]  // 首先，所有屏幕后处理效果都需要绑定在某个计算机上，并且我们希望在编辑器模式下也可以执行脚本来查看效果
public class PostEffectsBase : MonoBehaviour
{
    private void CheckResources()
    {
        bool isSupported = CheckSupported();

        if (isSupported == false)
        {
            NotSupported();
        }
    }
    
    /// <summary>
    /// 为了提前检测资源和条件是否满足，我们在Start函数中调用CheckResources函数
    /// </summary>
    protected bool CheckSupported()
    {
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogWarning("This Platform does not support image effects or render textures");
            return false;
        }

        return true;
    }

    protected void NotSupported()
    {

    }
    
    /// <summary>
    /// 指定一个Shader来创建一个用于处理渲染纹理的材质
    /// </summary>
    /// <param name="shader">指定该特效需要使用的Shader</param>
    /// <param name="material">用于和后期处理的材质</param>
    /// <returns></returns>
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (shader == null)
        {
            return null;
        }
        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }
        if (shader.isSupported == false)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material) return material;
            else return null;
        }
    }
    
    
    #region Unity CallBack

    void Start()
    {
        CheckResources();
    }
    
    void Update()
    {
        
    }
    
    #endregion
}
