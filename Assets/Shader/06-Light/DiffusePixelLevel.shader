// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "MyShader/06-Light/Diffuse/DiffusePixelLevel"
{
    Properties {
		// 声明一个Color属性，初始化为白色，用于控制材质的漫反射颜色 
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
	 }
	 SubShader {
		Pass {
			// LightMode标签是Pass标签中的一种，只有定义了正确的LightMode，才能得到一些Unity的内置光照变量
			Tags {"LightMode" = "ForwardBase"}   // 如果是使用URP，则这里设置为UniversalForward
			// Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM
			// 分别定义顶点着色器和片元着色器的名字
			#pragma vertex vert
			#pragma fragment frag

			// 为了使用Unity中的一些内置变量，需要包含Unity的内置文件Lighting.cginc
			#include "Lighting.cginc"

			// 为了在CG语句中使用Properties语义块中声明的属性，需要定义一个和该属性类型相匹配的变量
			fixed4  _Diffuse;

			// 定义顶点着色器的输入和输出结构体
			struct a2v {
				float4 vertex : POSITION;   // 模型空间中的顶点位置 
				float3 normal : NORMAL;     // 用于访问顶点的法线
			};
			struct v2f {
				float4 pos : SV_POSITION;         // 裁剪空间中的顶点坐标
				fixed3 worldNormal : TEXCOORD0;   // 将顶点信息计算的光照颜色传递给片元着色器
			};

			// 漫反射的计算都在顶点着色器中进行
			v2f vert(a2v v) {
				v2f f;
				// 将顶点从模型空间通过MVP矩阵变换到裁剪空间
				f.pos = UnityObjectToClipPos(v.vertex);
				
				// 将法线从模型空间变换到世界空间
				f.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				return f;
			}

			fixed4 frag(v2f f) : SV_Target {
				// 获取环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// 获取世界空间法线
				fixed3 worldNormal = normalize(f.worldNormal);

				// 获取光源方向
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				// 计算漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				fixed3 color = ambient + diffuse;
				return fixed4(color, 1);
			}

			ENDCG
		}
	 }
	 FallBack "VertexLit"
}
