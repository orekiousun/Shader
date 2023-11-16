Shader "MyShader/07-Texture/NormalMapTangentSpace"
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
                float3 lightDir : TEXCOORD1;       // 顶点着色器计算得到的切线空间下的光照方向
                float3 viewDir : TEXCOORD2;        // 顶点着色器计算得到的切线空间下的视线方向
                // 纹理
                float4 uv : TEXCOORD0;             // 在片元着色器中使用该坐标进行纹理采样，其中xy分量存储_MainTex的纹理坐标，zw分量存储_BumpMap的纹理坐标
            };

            // 顶点着色器在这里主要负责计算_MainTex和_BumpMap的纹理坐标，同时计算切线空间下的视角和光照方向，传递给片元着色器
            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);                         // 将顶点坐标从模型空间变化到裁剪空间

                // 将v2f的uv定义为float4类型，其中xy分量存储_MainTex的纹理坐标，zw分量存储_BumpMap的纹理坐标
                f.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;      
                f.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;      

                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;  // 计算副切线方向
                // 由于和切线与法线均垂直的方向有两个，所以在计算副切线时我们使用v.tangent.w和叉积结果相乘来决定选择的方向
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);                       // 得到从模型空间到切线空间的变换矩阵
                TANGENT_SPACE_ROTATION;  // 是UnityCG.cginc中提供的rotation变换矩阵，写入该行后后面就可以直接使用rotation矩阵

                f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;   // 获取模型空间下的光照方向，利用rotation变换矩阵把它从模型空间变换到切线空间
                f.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;     // 获取模型空间下的视角方向，利用rotation变换矩阵把它从模型空间变换到切线空间
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                // 获取切线空间下光照和视角方向并归一化
                fixed3 tangentLightDir = normalize(f.lightDir);   
                fixed3 tangentViewDir = normalize(f.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, f.uv.zw);   // 利用tex2D对法线纹理_BumpMap进行采样，得到法线经过映射后的像素值

                // 由于法线纹理中存储的是把法线经过映射后得到的像素值，所以下面需要把法线映射回来(如果Unity中把该法线的纹理类型设置为Normal map，就需要在代码中手动映射)
                fixed3 tangentNormal;   // 存储切线空间中的法线方向
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;                         // 将xy分量按照法线纹理映射公式映射回法线方向，同时乘以凹凸程度
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));   // z分量可由x分量计算获得
                tangentNormal = UnpackNormal(packedNormal);   // 使用内置函数直接映射，可以无视平台的差异  --  推荐使用该方法
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));      // x^2 + y^2 + z^2 = 1

                fixed3 albedo = tex2D(_MainTex, f.uv.xy).rgb * _Color.rgb;   // 使用tex2D函数对纹理_MainTex进行采样
                // 这里也可以省去.xy，会将f.uv强制转换为float2类型

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;                                                      // 获取环境光的同时乘以材质反射率
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(tangentNormal, tangentLightDir));   // 计算漫反射的同时乘以材质反射率

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);                                                // 获取矢量h
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);     // 计算高光反射

                return fixed4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
