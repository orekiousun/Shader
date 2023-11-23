Shader "MyShader/11-Animation/ImageSequenceAnimation" {
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        _VerticalAmount ("Vertical Amount", Float) = 4
        _Speed ("Speed", Range(1, 100)) = 30
    }
    SubShader {
        Tags { 
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }
        ZWrite off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0; 
            };
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            v2f vert (a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target {
                // 计算行列数
                float time = floor(_Time.y * _Speed);          // floor函数对结果取整
                float row = floor(time / _HorizontalAmount);   // 根据时间获得行索引
                float column = time - row * _VerticalAmount;   // 根据时间获得列索引

                half2 uv = i.uv + half2(column, -row);   // 使用当前的行数对纹理采样的uv结果进行偏移
                // 把原纹理坐标按行数和列数进行等分
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex, uv);   // 进行纹理采样
                c.rgb *= _Color;

                return c;
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
