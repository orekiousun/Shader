Shader "MyShader/12-PostProcessing/BrightnessSaturationAndContrast"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _Brightness ("Brightness", Float) = 1
        _Saturation ("Saturation", Float) = 1
        _Contrast ("Contrast", Float) = 1
    }
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            // 进行顶点变换并向片元着色器传递正确的纹理坐标
            // 使用内置的appdata_img结构体作为顶点着色器的输入，可以在UnityCG.cginc中找到该结构体的声明，它只包含了图像处理时必需的顶点坐标和纹理坐标等变量
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return  o;
            }

            // 实现用于调整亮度
            fixed4 frag (v2f i) : SV_Target
            {
                // 对原屏幕进行采样
                fixed4 renderTex = tex2D(_MainTex, i.uv);

                // Apply brightness：利用原颜色 * 亮度系数即可得到亮度
                fixed3 finalColor = renderTex.rgb * _Brightness;

                // Apply saturation：计算该像素对应的亮度值luminance，使用该亮度值创建一个饱和度为0的颜色值再利用_Saturation进行插值，得到希望饱和度的颜色
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 luminaceColor = fixed3(luminance, luminance, luminance);
                finalColor = lerp(luminaceColor, finalColor, _Saturation);

                // Apply contrast：创建一个对比度为0的颜色值（各分量均为0.5），再利用_Contrast进行插值
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return  fixed4(finalColor, renderTex.a);
            }
            ENDCG
        }
    }
    FallBack Off
}
