Shader "MyShader/12-PostProcessing/Bloom"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}                  // 渲染纹理
        _Bloom ("Bloom(RGB)", 2D) = "black" {}                   // 高斯模糊后的较亮区域
        _LuminanceThreshold("Luminance Threshold", Float) = 0.5  // 用于提取较亮区域使用的阈值
        _BlurSize ("Blur Size", Float) = 1.0                     // 控制不同迭代之间高斯模糊的模糊区域范围
    }
    SubShader
    {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        // 定义提取较亮区域需要使用的顶点着色器和片元着色器
        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return  o;
        }

        // 计算亮度值
        fixed luminance(fixed4 color)
        {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        fixed4 fragExtractBright(v2f i) : SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            // 将采样得到的亮度值减去阈值，并把结果截取到0-1范围内，再与原像素相乘，得到提取后的亮部
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
            return  c * val;
        }

        // 定义混合亮部图像和原图像时使用的顶点着色器和片元着色器
        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;
            o.pos  = UnityObjectToClipPos(v.vertex);
            // 定义了两个纹理坐标存储再类型为half4的uv中，xy分量供原图使用，zw分量供_Bloom使用
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            // 对纹理坐标进行平台差异化处理，推测为有的平台纹理坐标为负
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
            #endif

            return  o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            // 将两张纹理的采样结果混合即可
            return  tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
        
        ENDCG
        
        ZTest Always Cull Off ZWrite Off
        
        Pass 
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        
        UsePass "MyShader/PostProcessing/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        
        UsePass "MyShader/PostProcessing/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"
        
        Pass 
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    FallBack Off
}
