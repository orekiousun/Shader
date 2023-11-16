Shader "MyShader/13-DepthAndNormalTexture/EdgeDetectNormalAndDepth"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _EdgeOnly ("Edge Only", Float) = 1.0
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
        _SampleDistance ("Sample Distance", Float) = 1.0
        _Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)  // xy分量分别对应了法线和深度检测的灵敏度
    }
    SubShader
    {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        fixed _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        half4 _Sensitivity;
        sampler2D _CameraDepthNormalsTexture;  // 获取深度+法线纹理

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                uv.y = 1 - uv.y;
            #endif

            // 存储一个维数为5的纹理坐标数组。存储屏幕颜色图像的采样纹理以及使用Roberts算子时需要采样的纹理坐标，利用_SampleDistance控制采样距离
            // 把计算采样纹理坐标的代码从片元着色器中转移到顶点着色器中，可以减少运算，提高性能
            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance;
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance;
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance;
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance;

            return o;
        }

        // 计算对角线上两个纹理值的差值，要么返回0，要么返回1
        half CheckSum(half4 center, half4 sample)
        {
            // 分别得到两个采样点的法线和深度值
            half2 centerNormal = center.xy;
            float centerDepth = DecodeFloatRG(center.zw);
            half2 sampleNormal = sample.xy;
            float sampleDepth = DecodeFloatRG(sample.zw);

            // 计算两个法线之间的差值，并和一个阈值进比较
            half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
            int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
            // 计算两个深度值之间的差值，并和一个阈值进行比较
            float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
            int isSameDepth = diffDepth < 0.1 * centerDepth;

            // 1：法线和深度都很接近  0：法线和深度值不接近，说明是边缘
            return  isSameNormal * isSameDepth ? 1.0 : 0.0;
        }

        fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target
        {
            // 对深度/法线纹理进行采样
            half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
            half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
            half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
            half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);

            half edge = 1.0;

            edge *= CheckSum(sample1, sample2);
            edge *= CheckSum(sample3, sample4);

            // 将最终的边缘颜色进行混合，edge为1就是不是边缘，不混合，为0就是为边缘，混合
            fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
            fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

            // _EdgeOnly更接近1就更接近设置的backgroundColor
            return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
        }
        
        ENDCG
        
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRobertsCrossDepthAndNormal
            ENDCG
        }
    }
    Fallback Off
}
