Shader "MyShader/14-UnrealRendering/Hatching"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)  // 控制模型颜色
        _TileFactor ("Tile Factor", Float) = 1       // 纹理的平铺系数，越大模型上的素描线条越密
        _Outline ("Outline", Range(0 , 1)) = 0.1     
        _Hatch0 ("Hatch 0", 2D) = "white" {}
        _Hatch1 ("Hatch 1", 2D) = "white" {}
        _Hatch2 ("Hatch 2", 2D) = "white" {}
        _Hatch3 ("Hatch 3", 2D) = "white" {}
        _Hatch4 ("Hatch 4", 2D) = "white" {}
        _Hatch5 ("Hatch 5", 2D) = "white" {}         // 渲染时使用的6张纹理，线条密度依次增大
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "Queue" = "Geometry"}
        UsePass "MyShader/14-UnrealRendering/ToonShading/OUTLINE"  // 直接使用上一节中渲染轮廓线的Pass 
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"

            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 hatchWeights0 : TEXCOORD1;
                fixed3 hatchWeights1 : TEXCOORD2;  // 由于声明了6张纹理，这意味着需要6个权重，把他们存储在两个 fixed3 类型的变量中
                float3 worldPos : TEXCOORD3;       // 用于添加阴影效果
                SHADOW_COORDS(4)                   // 声明阴影纹理的采样坐标
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _TileFactor;                              // 得到纹理采样坐标
                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));  
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = max(0, dot(worldLightDir, worldNormal));            // 获得漫反射系数

                o.hatchWeights0 = fixed3(0, 0, 0);
                o.hatchWeights1 = fixed3(0, 0, 0);  // 初始化权重
                float hatchFactor = diff * 7.0;     // 缩放diff

                // 判断hatchFactor所处的子区间来计算对应的纹理混合权重
                if (hatchFactor > 6.0)
                {
                    
                }
                else if(hatchFactor > 5.0)
                {
                    o.hatchWeights0.x = hatchFactor - 5.0;
                }
                else if(hatchFactor > 4.0)
                {
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                }
                else if(hatchFactor > 3.0)
                {
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
                }
                else if(hatchFactor > 2.0)
                {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                }
                else if(hatchFactor > 1.0)
                {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights0.x;
                }
                else
                {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights0.y;
                }

                o.worldPos = UnityObjectToWorldDir(v.vertex);  // 计算顶点的世界坐标
                TRANSFER_SHADOW(o);                            // 计算阴影纹理的采样坐标
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 对每张纹理进行采样并对权重值相乘得到每张纹理的采样颜色
                fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;

                // 计算纯白在渲染中的贡献度（素描中往往有留白的部分，我们希望在最后的渲染中光照最亮的部分是纯白色的，而不是黑色）
                fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);

                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 混合各个颜色值，并和阴影值，模型颜色相乘返回最终结果
                return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
