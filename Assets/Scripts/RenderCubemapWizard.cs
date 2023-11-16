using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RenderCubemapWizard : ScriptableWizard   // 继承自向导(Wizard)类
{
	public Transform renderFromPosition;
	public Cubemap cubemap;

    void OnWizardCreate()
	{
		GameObject go = new GameObject("CubemapCamera");       // 创建一个临时摄像机用于渲染
		go.AddComponent<Camera>();
		go.transform.position = renderFromPosition.position;   // renderFromPosition由用户指定，在此处动态创建一个摄像机
		go.GetComponent<Camera>().RenderToCubemap(cubemap);    // 把从当前位置观察到的图像渲染到用户指定的立方体纹理cubemap中
		DestroyImmediate(go);                                  // 完成后销毁摄像机
	}

	[MenuItem("GameObject/Render into Cubemap")]   // 点击 GameObject/Render into Cubemap 时会执行下方函数
	static void RenderCubemap()
    {
		ScriptableWizard.DisplayWizard<RenderCubemapWizard>("Render cubemap", "Render!");   // 显示向导，并在点击 Render! 按钮时执行 OnWizardCreate() 函数，创建 Cubemap
	}
}
