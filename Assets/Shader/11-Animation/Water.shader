Shader "MyShader/11-Animation/Water" {
    Properties {
        _MainTex ("Main Tex", 2D) = "white" {}           // 河流纹理
        _Color ("Color Tint", Color) = (1, 1, 1, 1)      // 控制整体颜色
        _Magnitude ("Distortion Magnitude", Float) = 1   // 控制水流波动幅度
        _Frequency ("Distortion Frequency", Float) = 1   // 控制波动频率
        _InvWaveLength ("Distortion Inverse Wave Length", Float) = 10   // 控制波长倒数，越大波长越小
        _Speed ("Speed", Float) = 0.5                    // 控制河流纹理的移动速度
    }
    SubShader {
        Tags { 
            "Queue"="Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "DisableBatching" = "True"
        }

        Pass {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
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
                float4 offset;
                offset.yzw = float3(0.0, 0.0, 0.0);   // 只希望对x方向进行位移，将yzw设置为0
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + 
                    v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;   
                    // 利用_Frequency属性和内置的_Time.y变量来控制正弦函数的频率
                    // 初相通过模型空间下的位置位置分量 * _InvWaveLength 控制波长
                    // 最后乘以 _Magnitude 控制幅度，得到最终的位移
                o.pos = UnityObjectToClipPos(v.vertex + offset);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv += float2(0.0, _Time.y * _Speed);   // 控制水平方向上的纹理动画偏移
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
