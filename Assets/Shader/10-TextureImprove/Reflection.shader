Shader "MyShader/10-TextureImprove/Reflection"
{
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _ReflectionColor ("Reflection Color", Color) = (1, 1, 1, 1)   // 控制反射颜色
        _ReflectionAmount ("Reflection Amount", Range(0, 1)) = 1      // 控制材质的反射程度
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}          // 用于模拟反射的环境映射纹理
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
                float3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            fixed4 _Color;
            fixed4 _ReflectionColor;
            fixed _ReflectionAmount;
            samplerCUBE _Cubemap;

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                f.worldViewDir = UnityWorldSpaceViewDir(f.worldPos);
                f.worldRefl = reflect(-f.worldViewDir, f.worldNormal);   // 计算反射方向，用于立方体纹理采样
                TRANSFER_SHADOW(f);
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed3 worldViewDir = normalize(f.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 reflection = texCUBE(_Cubemap, f.worldRefl).rgb * _ReflectionColor.rgb;   // 使用 CG 的 texCUBE 函数对立方体纹理采样
                
                UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos);   // 计算光照阴影和衰减
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectionAmount) * atten;   // 使用 _ReflectionAmount 来混合漫反射颜色和反射颜色，并在环境光照相加后返回
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
