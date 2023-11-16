// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MyShader/07-Texture/NormalMapWorldSpace"
{
    Properties {
        // 光照
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)      // 控制漫反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1)    // 控制高光反射颜色
        _Gloss("Gloss", Range(8.0, 256)) = 20          // 控制高光区域大小

        // 基础纹理
        _Color("Color Tint", Color) = (1, 1, 1, 1)     // 控制纹理总体色调
        _MainTex("Main Tex", 2D) = "white" {}          // 控制纹理图片
        
        // 凹凸纹理
        _BumpMap("Normal Map", 2D) = "bump" {}         // "bump"为Unity内置的法线纹理，当没有提供任何法线时，"bump"就对应了模型自带的法线信息
        _BumpScale("Bump Scale", Float) = 1.0          // 控制凹凸程度，当为0时，意味该法线纹理不会对光线产生任何影响
    }
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            // 获取Properties语句中定义的变量
            // 光照
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            // 基础纹理
            fixed4  _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;   // Unity中需要使用 纹理名_ST 的方式声明某个纹理的属性

            // 凹凸纹理
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            struct a2v {
                // 光照
                float4 vertex : POSITION;      // 模型空间中顶点的位置
                float3 normal : NORMAL;        // 模型空间中顶点的法线
                // 基础纹理
                float4 texcoord : TEXCOORD0;   // 顶点的第一组纹理坐标，通过该纹理坐标，经过缩放和偏移后可以计算得到顶点的uv坐标
                // 凹凸纹理
                float4 tangent : TANGENT;      // 把顶点的切线填充到tangent变量中
            };
            struct v2f {
                // 光照
                float4 pos : SV_POSITION;          // 裁剪空间中顶点的位置
                // 纹理
                float4 uv : TEXCOORD0;             // 在片元着色器中使用该坐标进行纹理采样，其中xy分量存储_MainTex的纹理坐标，zw分量存储_BumpMap的纹理坐标
                // 用3行分别存储从切线空间到世界空间变换矩阵的每一行，把世界空间下的顶点位置存储在这些变量的w分量中
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            // 顶点着色器在这里主要负责计算_MainTex和_BumpMap的纹理坐标，同时计算切线空间下的视角和光照方向，传递给片元着色器
            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);                         // 将顶点坐标从模型空间变化到裁剪空间

                // 将v2f的uv定义为float4类型，其中xy分量存储_MainTex的纹理坐标，zw分量存储_BumpMap的纹理坐标
                f.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;      
                f.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;   
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;                // 将顶点坐标从模型空间转换到世界空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);                 // 将法线方向从模型空间转换到世界空间
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);              // 将切线方向从模型空间转换到世界空间
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   // 计算世界空间的副切线方向
                
                f.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                f.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                f.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                float3 worldPos = float3(f.TtoW0.w, f.TtoW1.w, f.TtoW2.w);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // 获取切线空间下的法线方向
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, f.uv.zw));   // 使用内置函数直接映射，可以无视平台的差异  --  推荐使用该方法
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));   // x^2 + y^2 + z^2 = 1
                // 将从纹理中映射回来的法线方向从切线空间转换到世界空间
                fixed3 bumpNormal = normalize(half3(dot(f.TtoW0.xyz, bump), dot(f.TtoW1.xyz, bump), dot(f.TtoW2.xyz, bump)));

                fixed3 albedo = tex2D(_MainTex, f.uv.xy).rgb * _Color.rgb;   // 使用tex2D函数对纹理_MainTex进行采样
                // 这里也可以省去.xy，会将f.uv强制转换为float2类型

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;                                            // 获取环境光的同时乘以材质反射率
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(bumpNormal, lightDir));   // 计算漫反射的同时乘以材质反射率

                fixed3 halfDir = normalize(lightDir + viewDir);                                                
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bumpNormal, halfDir)), _Gloss);     // 计算高光反射

                return fixed4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
