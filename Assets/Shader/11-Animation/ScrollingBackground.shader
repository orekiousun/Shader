Shader "MyShader/11-Animation/ScrollingBackground" {
    Properties {
        _MainTex ("Base Layer (RGB)", 2D) = "white" {}      // 第一层背景纹理
        _DetailTex ("2nd Layer (RGB)", 2D) = "white" {}     // 第二层背景纹理
        _ScrollX ("Base layer Scroll Speed", Float) = 1.0   // 第一层的滚动速度
        _Scroll2X ("2nd layer Scrool Spedd", Float) = 1.0   // 第二层的滚动速度
        _Multiplier ("Layer Multiplier", Float) = 1         // 控制纹理总体亮度
    }
    SubShader {
        Tags {
            "RenderType"="Opaque" 
            "Queue" = "Geometry"
        }
        
        Pass {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            v2f vert (a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算纹理坐标，并利用 _Time.y 变量在水平方向上对纹理坐标进行偏移，达到滚动的效果
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
                fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                c.rgb *= _Multiplier;
                return c;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
