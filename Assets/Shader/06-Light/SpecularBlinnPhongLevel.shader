// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MyShader/06-Light/Specular/SpecularBlinnPhongLevel"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)      // 控制漫反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1)   // 控制高光反射颜色
        _Gloss("Gloss", Range(8.0, 256)) = 20          // 控制高光区域大小
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            // 获取Properties语句中定义的变量
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;   // 模型空间中顶点的位置
                float3 normal : NORMAL;     // 模型空间中顶点的法线
            };
            struct v2f {
                float4 pos : SV_POSITION;          // 裁剪空间中顶点的位置
                float3 worldNormal : TEXCOORD0;    // 顶点着色器计算得到的颜色
                float3 worldPos : TEXCOORD1;       // 顶点着色器计算得到的颜色
            };

            v2f vert (a2v v)
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);                         // 将顶点坐标从模型空间变化到裁剪空间
                f.worldNormal = UnityObjectToWorldNormal(v.normal) ;            // 将顶点法线从模型空间变换到世界空间
                // f.worldPos = mul(unity_ObjectToWorld, v.vertex);
                f.worldPos = UnityObjectToWorldDir(v.vertex);                // 将顶点坐标从模型空间变换到世界空间
                return f;
            }

            fixed4 frag (v2f f) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;                                                           // 获取环境光
                fixed3 worldNormal = normalize(f.worldNormal);                                                           // 获取顶点法线在世界空间的坐标
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));                                   // 获取光源的方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));                                           // 获取视线方向

                fixed3 halfDir = normalize(worldLightDir + viewDir);                                                     // 获取矢量h

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));            // 计算漫反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);   // 计算高光反射

                return fixed4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
