Shader "MyShader/13-DepthAndNormalTexture/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;                      // 主纹理的纹素大小
        sampler2D _CameraDepthTexture;                 // Unity传递的深度纹理
        float4x4 _CurrentViewProjectionInverseMatrix;  // 脚本传递来的矩阵
        float4x4 _PreviousViewProjectionMatrix;        // 脚本传递来的矩阵
        half _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;            
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
            // 处理平台差异导致的图像翻转问题
            if (_MainTex_TexelSize.y < 0)
            {
               o.uv_depth.y = 1 - o.uv_depth.y;
            }
            #endif

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);    // 获取深度纹理（深度纹理采样）
            float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);    // 由于深度纹理d是NDC下的坐标映射而来的，我们想要构建像素的NDC坐标H，就需要把这个深度值重新映射回NDC，机像素的NDC坐标
            float4 D = mul(_CurrentViewProjectionInverseMatrix, H);             // 利用视角*投影矩阵对其进行变换，得到世界空间下的坐标
            float4 worldPos = D / D.w;

            float4 currentPos = H;
            float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);  // 得到前一帧的世界空间坐标
            previousPos /= previousPos.w;

            float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;          // 计算速度值
            float2 uv = i.uv;
            float4 c = tex2D(_MainTex, uv);
            uv += velocity * _BlurSize;
            // 利用速度值对领域像素进行采样，利用_BlurSize控制采样距离
            for(int it = 1; it < 3; it++)
            {
                float4 currentColor = tex2D(_MainTex, uv);
                c += currentColor;
                uv += velocity * _BlurSize;
            }
            c /= 3;

            return fixed4(c.rgb, 1.0);
        }

        
        ENDCG

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    Fallback Off
}
