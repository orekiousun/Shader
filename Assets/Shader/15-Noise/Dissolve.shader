Shader "MyShader/15-Noise/Dissolve"
{
    Properties
    {
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0           // 控制消融程度，为时为正常效果，为1时会完全消融
        _LineWidth ("Burn Line Width", Range(0.0, 0.2)) = 0.1        // 控制模拟烧焦效果的线宽，值越大，火焰边缘的蔓延范围越广
        _MainTex ("Base (RGB)", 2D) = "white" {}                     // 漫反射纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}                      // 法线纹理
        _BurnFirstColor ("Burn First Color", Color) = (1, 0, 0, 1)   
        _BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)  // 对应了火焰边缘的两种颜色值
        _BurnMap("Burn Map", 2D) = "white" {}                        // 噪声纹理
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Off  // 关闭面片剔除
            
            CGPROGRAM
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            float _BurnAmount;
            float _LineWidth;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)  // 内置宏，声明一个用于对阴影纹理采样的坐标，参数为下一个可用级插值寄存器的索引值
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);  
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);           // 计算纹理坐标

                TANGENT_SPACE_ROTATION;                                      // 获取rotation矩阵
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;  // 计算切线空间的光线方向（用于计算法线纹理）
                o.worldPos = UnityObjectToWorldDir(v.vertex);
                TRANSFER_SHADOW(o);                                          // 计算世界空间下的顶点位置和阴影纹理的采样坐标
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;                                  // 对噪声纹理采样
                clip(burn.r - _BurnAmount);                                                      // 与阈值进行比较并裁剪

                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));  // 对法线纹理采样

                fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 计算烧焦的颜色
                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);                 // t为1时说明此时位于消融的边界处，为0时说明像素为正常的模型颜色
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);                   // 混合两种火焰的颜色

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);                                   // 计算光照阴影

                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));  // _BurnAmount为0时不显示消融效果
                return fixed4(finalColor, 1);
            }
            
            ENDCG
        }
    
        // 由于使用透明度测试的的物体阴影需要特别处理，如果仍需要使用普通的阴影Pass，那么被剔除的区域仍然会向其他物体投射阴影，造成”穿帮“。为了让物体的阴影也能配合透明度测试产生的效果，我们需要自定义一个投射阴影的Pass
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }  // 用于阴影投射的Pass的LightMode需要被设置为ShadowCaster
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster  // 指明它需要的编译指令
            #include "UnityCG.cginc"

            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            float _BurnAmount;
            
            struct v2f
            {    
                V2F_SHADOW_CASTER;  // 定义阴影投射需要定义的变量
                float2 uvBurnMap : TEXCOORD01;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);  // 填充V2F_SHADOW_CASTER中声明的变量
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;  // 计算噪声纹理的坐标
                clip(burn.r - _BurnAmount);                      // 使用噪声纹理的采样结果剔除片元
                SHADOW_CASTER_FRAGMENT(i);                       // 完成阴影投射
            }
            ENDCG
        }    
    }
    FallBack "Diffuse"
}
