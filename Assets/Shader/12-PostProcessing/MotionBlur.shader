Shader "MyShader/12-PostProcessing/MotionBlur"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        fixed _BlurAmount;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed4 fragRGB(v2f i) : SV_Target
        {
            // RGB版本的Shader对当前图像进行采样，并将其A通道的值设置为_BlurAmount，以便在后面混合时使用它的透明度进行混合
            return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
        }

        half4 fragA(v2f i) : SV_Target
        {
            // 直接返回采样结果
            // 维护渲染纹理的透明通道值，不让其受到混合时使用的透明度值的影响
            return  tex2D(_MainTex, i.uv);
        }
        
        ENDCG
        
        ZTest Always Cull Off Zwrite Off
        
        Pass 
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            CGPROGRAM

            #pragma  vertex vert
            #pragma  fragment fragRGB
            
            ENDCG
        }
        
        Pass 
        {
            Blend One Zero
            ColorMask A
            CGPROGRAM

            #pragma  vertex vert
            #pragma  fragment fragA
            
            ENDCG
        }
    }
    Fallback Off
}
