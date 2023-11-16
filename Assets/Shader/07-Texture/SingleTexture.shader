Shader "MyShader/07-Texture/SingleTexture"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)      // 控制漫反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1)    // 控制高光反射颜色
        _Gloss("Gloss", Range(8.0, 256)) = 20          // 控制高光区域大小

        _Color("Color Tint", Color) = (1, 1, 1, 1)     // 控制纹理总体色调
        _MainTex("Main Tex", 2D) = "white" {}          // 控制纹理图片
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
            fixed4  _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;   // Unity中需要使用 纹理名_ST 的方式声明某个纹理的属性
            // 其中S是Scale表示缩放，T为Tanslation表示平移，_MainTex_ST可以让我们获取该纹理的缩放和偏移值，其中_MainTex_ST.xy存储缩放值，_MainTex_ST.zw存储偏移值


            struct a2v {
                float4 vertex : POSITION;     // 模型空间中顶点的位置
                float3 normal : NORMAL;       // 模型空间中顶点的法线
                float4 texcoord : TEXCOORD;   // 顶点的第一组纹理坐标
            };
            struct v2f {
                float4 pos : SV_POSITION;          // 裁剪空间中顶点的位置
                float3 worldNormal : TEXCOORD0;    // 顶点着色器计算得到的颜色
                float3 worldPos : TEXCOORD1;       // 顶点着色器计算得到的颜色
                float2 uv : TEXCOORD2;             // 在片元着色器中使用该坐标进行纹理采样
            };

            v2f vert (a2v v)
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);                         // 将顶点坐标从模型空间变化到裁剪空间
                f.worldNormal = UnityObjectToWorldNormal(v.normal) ;            // 将顶点法线从模型空间变换到世界空间
                // f.worldPos = mul(unity_ObjectToWorld, v.vertex);
                f.worldPos = UnityObjectToWorldDir(v.vertex);                   // 将顶点坐标从模型空间变换到世界空间
                 
                f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);                     // 也可以之间使用内置函数计算uv坐标，在UnityCG.cginc中
                // f.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;      // 首先使用缩放属性_MainTex_ST.xy对顶点纹理坐标进行缩放，再使用偏移属性_MainTex.zw进行偏移
                return f;
            }

            fixed4 frag (v2f f) : SV_Target
            {
                
                fixed3 worldNormal = normalize(f.worldNormal);                                                           // 获取顶点法线在世界空间的坐标
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));                                   // 获取光源的方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));                                          // 获取视线方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);                                                     // 获取矢量h
                fixed3 albedo = tex2D(_MainTex, f.uv).rgb * _Color.rgb;                                                  // 使用tex2D函数对纹理进行采样，使用采样结果和颜色属性的乘积作为材质反射率

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;                                                  // 获取环境光的同时乘以材质反射率
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));   // 计算漫反射的同时乘以材质反射率
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);   // 计算高光反射
                return fixed4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
