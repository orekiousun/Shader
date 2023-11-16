Shader "MyShader/10-TextureImprove/Refraction"
{
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _RefractColor ("Refraction Color", Color) = (1, 1, 1, 1)   // 控制折射颜色
        _RefractAmount ("Refraction Amount", Range(0, 1)) = 1      // 控制材质的折射程度
        _RefractRation ("Refraction Ration", Range(0, 1)) = 0.5    // 得到不同材质的透射比
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}       // 用于模拟反射的环境映射纹理
    }
    SubShader {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            fixed4 _Color;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRation;
            samplerCUBE _Cubemap;

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                f.worldViewDir = UnityWorldSpaceViewDir(f.worldPos);
                f.worldRefr = refract(-normalize(f.worldViewDir), normalize(f.worldNormal), _RefractRation);   // 使用 CG 的 refract 函数来计算折射方向
                // 参数分别为：
                //      入射光线方向(需要为归一化后的矢量)
                //      表面法线(同样需要归一化)
                //      入射光线所在介质的折射率和折射光线所在介质的折射率之间的比值，例如空气折射率和玻璃的比值就是 1/1.5
                TRANSFER_SHADOW(f);
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed3 worldViewDir = normalize(f.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 refraction = texCUBE(_Cubemap, f.worldRefr).rgb * _RefractColor.rgb;   // 使用 CG 的 texCUBE 函数对立方体纹理采样
                
                UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos);   // 计算光照阴影和衰减
                fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;   // 使用 _RefractAmount 来混合漫反射颜色和反射颜色，并在环境光照相加后返回
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
