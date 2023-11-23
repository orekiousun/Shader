Shader "MyShader/14-UnrealRendering/ToonShading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "white" {}                  // 控制漫反射色调的渐变纹理
        _Outline ("Outline", Range(0, 1)) = 0.1                  // 控制轮廓线宽度
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)    // 轮廓线颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1)             // 高光反射颜色
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01  // 用于计算高光反射时使用的阈值
    }
    SubShader
    {   
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        // 渲染轮廓线的Pass
        Pass
        {
            NAME "OUTLINE"  // 定义Pass的名称，方便复用
            Cull Front      // 剔除正面三角面片，只渲染背面
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            float _Outline;
            fixed4 _OutlineColor;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(a2v v)
            {
                v2f o;
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);                  // 将顶点变换到视角空间下 
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);  // 将法线变换到视角空间下
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline;          // 沿顶点方向进行扩张
                o.pos = mul(UNITY_MATRIX_P, pos);                             // 最后再将位置变换到裁剪空间
                return  o;
            } 

            float4 frag(v2f i) : SV_Target
            {
                return  float4(_OutlineColor.rgb, 1);                         // 使用轮廓颜色渲染背面即可
            }
            ENDCG
        }
        
        // 光照模型的Pass
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            float _SpecularScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 texcoord : TEXCOORD0; 
            };
            
            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = UnityObjectToWorldDir(v.vertex);        // 计算顶点的世界坐标

                TRANSFER_SHADOW(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                // 计算ambient环境光
                fixed4 c = tex2D(_MainTex, i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;                                                 // 计算材质反射率
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;                             // 计算环境光照

                // 计算diffuse漫反射
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);                                      // 计算当前世界坐标下的阴影值
                fixed diff = dot(worldNormal, worldLightDir);                                       // 计算半兰伯特光照的反射系数
                diff = (diff * 0.5 + 0.5) * atten;                                                  // 与阴影值相乘得到最终的反射系数
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;  // 使用漫反射系数对渐变纹理_Ramp进行采样，并将结果和材质的反射率、光照颜色相乘，作为最后漫反射光照

                fixed spec = dot(worldNormal, worldHalfDir);                                        
                fixed w = fwidth(spec) * 2.0;                                                       // 对高光区域进行抗锯齿处理，抗锯齿的w值
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);  // 当_SpecularScale为0时，完全消除高光反射
                

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
