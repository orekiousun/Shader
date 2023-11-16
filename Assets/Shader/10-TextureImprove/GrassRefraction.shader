Shader "MyShader/10-TextureImprove/GrassRefraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}                     // 玻璃的材质纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}                    // 玻璃的法线纹理
		_Cubemap ("Environment Cubemap", Cube) = "Skybox" {}       // 模拟反射的环境纹理
		_Distortion ("Distortion", Range(0, 100)) = 10             // 用于控制模拟折射时图像的扭曲程度，控制折射偏移量
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0   // 用于控制折射程度，0时只包含反射效果，1时只包含折射效果
	}
	SubShader {
		Tags { 
			"RenderType"="Opaque"   // 设置RenderType是为了在使用着色器替换时，该物体可以被正确渲染
			"Queue"="Transparent"   // 把Queue设置为Transparent可以确保物体渲染时，其他所有不透明物体都已经被渲染到屏幕上了，否则无法得到 "透过玻璃看得到图像"
		}
		
		GrabPass {"_RefractionTex"}   // 通过关键词GrabPass定义了一个抓取屏幕图像的Pass，在该Pass中定义了一个字符串，该字符串内部的名称决定了抓取得到的屏幕图像会被存入到哪个纹理中

		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;          // 对应了使用GrabPass时指定的纹理名称
			float4 _RefractionTex_TexelSize;   // 得到该纹理的纹素大小，例如一个大小为256x512的纹理，纹素大小为(1/256, 1/512)
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 srcPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
                float4 TtoW1 : TEXCOORD3;  
                float4 TtoW2 : TEXCOORD4;
			};
			
			v2f vert(a2v v) {
			 	v2f f;
			 	f.pos = UnityObjectToClipPos(v.vertex);

				f.srcPos = ComputeGrabScreenPos(f.pos);   // 得到对应被抓取的屏幕图像的采样坐标
			 
			 	f.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	f.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                
				// 计算该顶点对应的从切线空间到世界空间的变换矩阵，w轴用于存储世界空间下的顶点坐标
                f.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
                f.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
                f.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
			 	
			 	return f;
			}
			
			fixed4 frag(v2f f) : SV_Target {
				float3 worldPos = float3(f.TtoW0.w, f.TtoW1.w, f.TtoW2.w);                                         // 通过w分量获取世界坐标
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				 
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, f.uv.zw));                                              // 对法线纹理采样，得到切线空间下的法线方向
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;   
				f.srcPos.xy = offset + f.srcPos.xy;                                                                // 对屏幕图像的采样坐标进行偏移，模拟折射效果，_Distortion越大偏移量越大
				fixed3 refrColor = tex2D(_RefractionTex, f.srcPos.xy/f.srcPos.w).rgb;                              // 对srcPos透视除法得到真正的屏幕坐标，再使用该坐标对抓取的屏幕图像进行采样，得到模拟的折射颜色

				bump = normalize(half3(dot(f.TtoW0.xyz, bump), dot(f.TtoW1.xyz, bump), dot(f.TtoW2.xyz, bump)));   // 把法线方向从切线空间变换到世界空间下
				fixed3 reflDir = reflect(-worldViewDir, bump);                                                     // 得到视角方向相对于法线方向的反射方向
				fixed4 texColor = tex2D(_MainTex, f.uv.xy);                                                        // 对材质纹理进行采样
				fixed3 reflColor = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;                                  // 使用反射方向对Cubemap采样，同时与材质纹理混合
				
				fixed3 finalColor = reflColor * (1 - _RefractAmount) + refrColor * _RefractAmount;                 // 使用_RefractAmount对反射和折射颜色相混合

				return fixed4(finalColor, 1.0);
			}
			ENDCG
		}
	} 
	FallBack "Specular"
}
