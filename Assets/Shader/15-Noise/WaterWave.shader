Shader "MyShader/15-Noise/WaterWave"
{
    Properties
    {
        _Color ("Main Color", Color) = (0, 0.15, 0.115, 1)              // 控制水面颜色
        _MainTex ("Base (RGB)", 2D) = "white" {}                        // 水面材质纹理
        _WaveMap ("Wave Map", 2D) = "bump" {}                           // 由噪声纹理生成的法线纹理
        _CubeMap ("Environment Cubemap", Cube) = "_SkyBox" { }          // 用于模拟反射的立方体纹理
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01  // 控制法线在X方向上的平移速度 
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01    // 控制法线在Y方向上的平移速度
        _Distortion ("Distortion", Range(0, 100)) = 10
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"  // "Queue" = "Transparent": 确保物体渲染时，其他所有不透明物体都已经被渲染到屏幕上了
            "RenderType" = "Opaque"  // "RenderType" = "Opaque": 在使用着色器替换（Render Replacement）时，该物体可以在需要时被正确渲染
        }
        
        GrabPass { "_RefractionTex" }  // 抓取到的屏幕图像将被存在_RefractionTex纹理中
        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            fixed _Distortion;
            sampler2D _RefractionTex;        // 使用GrabPass时指定的纹理名称
            float4 _RefractionTex_TexelSize;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);         // 得到对应被抓取屏幕图像的采样坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);  
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);  // 计算两个纹理的采样坐标

                float3 worldPos = UnityObjectToWorldDir(v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 计算顶点到切线空间的变换矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);                                        // 得到世界坐标
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));                                     // 计算视角方向
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);                                        // 计算法线纹理的当前偏移量

                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;                
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;  
                fixed3 bump = normalize(bump1 + bump2);                                                           // 对法线纹理进行两次采样，模拟两层交叉的水面波动效果，归一化后得到切线空间的法线方向

                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;                              // 对屏幕的采样坐标进行偏移，模拟折射效果，_Distortion值越大，偏移量越大，水面背后的物体看起来的变形程度越大
                // 使用切线空间下的法线方向进行偏移，该空间下的法线可以反映顶点局部空间下的法线方向
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;                                                  // 与屏幕坐标的z相乘，模拟深度越大，偏移量越大的效果，最后将偏移值叠加到屏幕坐标上
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;                             // 使用透视除法，并对_RefractionTex进行采样，得到模拟的折射颜色

                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));  // 将法线方向从切线空间变换到世界空间下
                fixed3 reflDir = reflect(-viewDir, bump);                                                         // 得到视角方向相对于法线方向的反射方向
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);                                               // 对主纹理进行纹理动画，模拟水波效果
                fixed3 reflCol = texCUBE(_CubeMap, reflDir).rgb * texColor.rgb * _Color.rgb;                      // 使用反射方向对CubeMap进行采样，并把结果和主纹理颜色相乘后得到反射颜色

                fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);                                         // 计算菲涅尔系数
                fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
                return fixed4(finalColor, 1);
            }
            
            ENDCG
        } 
    }
    FallBack off
}
