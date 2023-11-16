Shader "MyShader/08-Transparent/AlphaBlendBothSide"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { 
            "Queue"="Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }

        Pass
        {
            // 由于上一个Pass已经得到了逐像素的正确的深度信息，该Pass就可以按照像素级别的深度排序结果进行透明渲染
            Tags { "LightMode" = "ForwardBase" }
            Cull Front
            ZWrite Off   // 关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha   // 开始并设置Pass的混合模式
            // 把源颜色的混合因子设为SrcAlpha，把目标颜色的混合因子设为OneMinusSrcAlpha，以得到合适的半透明效果

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed4 albedo = tex2D(_MainTex, f.uv);
                // 移除了透明度测试的代码
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, albedo.a * _AlphaScale);   // 设置了返回值中的透明通道
            }
            ENDCG
        }
        Pass
        {
            // 由于上一个Pass已经得到了逐像素的正确的深度信息，该Pass就可以按照像素级别的深度排序结果进行透明渲染
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite Off   // 关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha   // 开始并设置Pass的混合模式
            // 把源颜色的混合因子设为SrcAlpha，把目标颜色的混合因子设为OneMinusSrcAlpha，以得到合适的半透明效果

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed4 albedo = tex2D(_MainTex, f.uv);
                // 移除了透明度测试的代码
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, albedo.a * _AlphaScale);   // 设置了返回值中的透明通道
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
