Shader "MyShader/13-DepthAndNormalTexture/FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _FogDensity ("Fog Density", Float) = 1.0
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogStart ("Fog Start", Float) = 0.0
        _FogEnd ("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        float4x4 _FrustumCornersRay;    // 虽然没有在Properties中声明，但是还是可以通过脚本传递给Shader
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;  // Unity会把深度纹理传给该值 
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP // 处理平台差异
            if(_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            // 利用纹理坐标判断该点对应了四个角中的哪个角（个人认为这里世界坐标的获取不够准确）
            // 这里是将整个屏幕看作一个贴图，texcoord里面记录的是每个点对应的屏幕纹理
            int index = 0;
            if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
            {
                index = 0;
            }
            else if(v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
            {
                index = 1;
            }
            else if(v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
            {
                index = 2;
            }
            else
            {
                index = 3;
            }

            #if UNITY_UV_STARTS_AT_TOP  // 处理平台差异
            if(_MainTex_TexelSize.y < 0)
                index = 3 - index;
            #endif
            o.interpolatedRay = _FrustumCornersRay[index];

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));  // 对深度纹理进行采样后得到视角空间下的线性深度值
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;               // 得到世界空间下的位置
            // 实现居于高度的雾效模拟
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);                          // 计算像素高度对应的雾效系数（采用线性的方法，个人认为这里计算出来的像素高度是粗略的）
            fogDensity = saturate(fogDensity * _FogDensity);                                            // 将雾效系数与设置的雾效强度进行混合，并把结果截取在[0, 1]范围内
            fixed4 finalColor = tex2D(_MainTex, i.uv);                                                  // 对纹理进行采样，得到颜色值
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);                           // 将雾的颜色与原颜色值进行混合
            return  finalColor;
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
    FallBack Off
}
