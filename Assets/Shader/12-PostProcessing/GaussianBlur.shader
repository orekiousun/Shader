Shader "MyShader/12-PostProcessing/GaussianBlur"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        // CGINCLUDE类似于C++中头文件的功能，由于高斯模糊需要定义两个Pass，但它们使用的片元着色器代码完全相同，使用CGINCLUDE可以避免我们编写两个完全一样的frag函数
        CGINCLUDE
        
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };

        v2f vertBlurVertical(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;

            // 只进行垂直方向的偏移，定义了一组高斯采样地方邻与纹理坐标，利用和_BlurSize相乘控制采样距离。
            // _BlurSize越大，模糊程度越高，但是采样数不会受到影响，但同时。过大的_BlurSize会造成虚影。
            // 将计算采样纹理坐标的代码转移到顶点着色器中，可以减少运算，提高性能
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;

            return o;
        }

        v2f vertBlurHorizontal(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;

            // 只进行水平方向的偏移，定义了一组高斯采样地方邻与纹理坐标，利用和_BlurSize相乘控制采样距离。
            // _BlurSize越大，模糊程度越高，但是采样数不会受到影响，但同时。过大的_BlurSize会造成虚影。
            // 将计算采样纹理坐标的代码转移到顶点着色器中，可以减少运算，提高性能
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.y * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.y * 1.0, 0.0) * _BlurSize;

            return o;
        }

        fixed4 fragBlur(v2f i) : SV_Target
        {
            // 三个记录的高斯权重
            float weight[3] = {0.4026, 0.2442, 0.0545};
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            for(int it = 1; it < 3; it++)
            {
                // 声明各个领域像素对应的weight，然后将结果值sum初始化为当前像素值乘以它的权重值
                // 根据对称性进行两次迭代，每次迭代包含两次纹理采样，并把像素值和权重值相乘后的结果叠加到sum中，最后返回滤波结果sum
                sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
            }
            // 上述操作即一个1x5矩阵乘以一个5x3矩阵
            // 1x5矩阵：[0.0545, 0.2442, 0.4026, 0.2442, 0.0545]
            // 5x3矩阵：每一行都是对应每个点的颜色值
            // 最后叠加得到一个1x3矩阵的rgb值
            return  fixed4(sum, 1.0);
        }
        
        ENDCG
        
        ZTest Always Cull Off ZWrite Off
        
        Pass 
        {
            // 为Pass使用NAME语义定义他们的名字，由于高斯模糊是常见的图像处理操作，很多屏幕特效都是建立在它的基础上的。
            // 为Pass定义名字，可以在其他Shader中直接通过它们的名字来使用该Pass，而不需要重复再编写代码
            NAME "GAUSSIAN_BLUR_VERTICAL"
            
            CGPROGRAM
            
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            
            ENDCG
        }
        
        Pass 
        {
            NAME "GAUSSIAN_BLUR_HORIZONTAL"
            
            CGPROGRAM
            
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            
            ENDCG
        }
        
        
    }
    FallBack Off
}
