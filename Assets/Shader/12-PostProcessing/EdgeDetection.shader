Shader "MyShader/12-PostProcessing/EdgeDetection"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _EdgeOnly ("Edge Only", Float) = 1.0
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragSobel
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half4 _MainTex_TexelSize;   // xxx_TexelSize是Unity为我们提供的xxx的像素尺寸大小，值为：Vector4(1/width, 1/height, width, height)
            // 例如一张512x512大小的纹理，该值大约为0.001953(1/512)
            // 由于卷积需要对相邻区域内的纹理进行采样，因此我们需要利用_MainTex_TexelSize来计算各个相邻区域的纹理坐标
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv[9] : TEXCOORD0;
            };

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = v.texcoord;

                // 计算在顶点着色器中计算边缘检测时需要的邻域纹理坐标，即计算像素及其周围8个像素的纹理坐标，对应了使用Sobel算子采样时需要的9个邻域纹理坐标。
                // 通过把计算采用纹理坐标的代码从片元着色器中转移到顶点着色器，可以减少运算，提高性能。
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                
                return  o;
            }

            fixed4 luminance(fixed4 color)
            {
                return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i)
            {
                const half Gx[9] = {-1, -2, -1, 0, 0, 0, 1, 2, 1};
                const half Gy[9] = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                for(int it = 0; it < 9; it ++)
                {
                    texColor = luminance(tex2D(_MainTex, i.uv[it]));   // 获取到对应位置的亮度值，通过亮度值计算梯度，来来判断是否为边缘点
                    edgeX += texColor * Gx[it];                              // 进行水平方向卷积
                    edgeY += texColor * Gy[it];                              // 进行竖直方向卷积
                } 

                half edge = 1 - abs(edgeX) - abs(edgeY);                     // edge越小，梯度越大，表明该位置越可能是一个边缘点
                return  edge;
            }

            fixed4 fragSobel (v2f i) : SV_Target
            {
                half edge = Sobel(i);                                                      // edge越小，表明该位置越可能是一个边缘点，进行插值时该值就约接近_EdgeColor

                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);   // 计算背景为原图下的颜色值
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);           // 计算纯色下的颜色值（_BackgroundColor相当于整体的一个色调）
                return  lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            ENDCG
        }
    }
    Fallback Off
}
