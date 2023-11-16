// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "MyShader/09-LightImprove/ForwardRendering"
{
    Properties
    {
        _Diffuse("Diffuse", COLOR) = (1, 1, 1, 1)
        _Specular("Specular", COLOR) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass {
            // Base Pass，处理一个逐像素的平行光以及所有的逐顶点和SH光源  --  一般是平行光，环境光，自发光
            // 这里只处理了平行光
            Tags { "LightMode" = "ForwardBase" }   // 设置渲染路径标签

            CGPROGRAM
            #pragma multi_compile_fwdbase   // 使用#pragma编译指令，保证我们在Shader中使用光照衰减等光照变量可以被正确赋值
            #pragma vertex vert 
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return f;
            }

            fixed4 frag(v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                fixed atten = 1.0;
                
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }

        Pass {
            // Additional Pass，处理其他影响该物体的逐像素光源，每个光源执行一次Pass  --  一般处理点光源，聚光灯等
            // 这里只处理了点光源
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One   // 开启和设置了混合模式，以确保Addtional Pass计算得到的光照结果可以在帧缓存中与之前的光照结果进行叠加

            CGPROGRAM
            #pragma multi_compile_fwdadd   // 保证在Additional Pass中访问到正确的光照变量
            #pragma vertex vert 
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return f;
            }

            fixed4 frag(v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);

                #ifdef USING_DIRECTIONAL_LIGHT   // 判断是否为平行光
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - f.worldPos.xyz);
                #endif

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;   // 如果是平行光，衰减值为1
                #else 
                    float3 lightCoord = mul(unity_WorldToLight, float4(f.worldPos, 1)).xyz;   // 得到光源空间下的坐标
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;   // 使用该坐标对衰减纹理进行采样得到衰减值
                    // Unity使用一张纹理图作为查找表，以在片元着色器中得到光源的衰减
                #endif
                
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
