Shader "MyShader/17-SurfaceShader/NormalExtrusion"
{
    Properties
    {
        _ColorTint ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Base (RGB)",2D) = "white" {}
        _BumpMap ("Normalmap", 2D) = "bump" {}
        _Amount ("Extrusion Amount", Range(-0.5, 0.5)) = 0.1
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque"}
        LOD 300
        
        CGPROGRAM

        #pragma surface surf CustomLambert vertex:myvert finalcolor:mycolor addshadow exclude_path:deferred exclude_path:prepass nometa
        // surf - 表面函数
		// CustomLambert - 光照函数
		// vertex:myvert - 顶点修改函数
		// finalcolor:mycolor - 颜色修改函数
		// addshadow - 由于我们修改了顶点位置，因此要对其他物体产生正确的阴影效果并不能直接依赖FallBack中找到的阴影投射Pass，addshadow参数可以告诉Unity要生成一个该表面着色器对应的阴影投射Pass
		// 默认情况下，Unity会为所有支持的渲染路径生成相应的Pass，为了缩小自动生成的代码量，做了以下操作
		// exclude_path:deferred/exclude_path:prepas - 告诉Unity不要为延迟渲染路径生成相应的Pass
		// nometa - 取消对提取元数据的Pass的生成

        #pragma target 3.0

        fixed4 _ColorTint;
        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _Amount;

        struct Input
        {
            float2 uv_MainTeX;
            float2 uv_BumpMap;
        };

        // 顶点修改函数：使用顶点法线对顶点位置进行膨胀
        void myvert(inout appdata_full v)
        {
            v.vertex.xyz += v.normal * _Amount;
        }

        // 表面函数
        void surf(Input IN, inout SurfaceOutput o)
        {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTeX);
            o.Albedo = tex.rgb;  // 使用主纹理设置表面属性中的反射率
            o.Alpha = tex.a;     // 使用法线纹理设置表面法线方向
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }

        // 光照函数：实现简单的兰伯特漫反射光照模型
        half4 LightingCustomLambert(SurfaceOutput s, half3 lightDir, half atten)
        {
            half NdotL = dot(s.Normal, lightDir);
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
            c.a = s.Alpha;
            return c;
        }

        // 颜色修改函数：使用颜色参数对输出颜色进行调整
        void mycolor(Input IN, SurfaceOutput o, inout fixed4 color)
        {
            color *= _ColorTint;
        }
        
        ENDCG
    }
    FallBack "Legacy Shaders/Diffuse"
}
