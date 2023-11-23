// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "MyShader/11-Animation/Billboard" {
    Properties {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1  
    }
    SubShader {
        Tags { 
            "Queue"="Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "DisableBatching" = "True"   // 表示不对该Shader使用批处理
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
            float _VerticalBillboarding;

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

                // 选择模型空间的原点作为广告牌的锚点，并利用内置变量获取模型空间下的视角位置
                float3 center = float3(0, 0, 0);
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                // 计算正交向量
                float3 normalDir = viewer - center;
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                // 当_VerticalBillboarding为1时，意味法线方向固定为视角方向
                // 当_VerticalBillboarding为0时，意味着向上方向固定为(0, 1, 0)

                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);   // 对y分量进行判断，得到合适的向上方向，防止法线方向和向上方向平行
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

                // 根据原始位置的位置相对于锚点的偏移量以及3个正交基向量，得到新的顶点位置
                float3 centerOffset = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffset.x + upDir * centerOffset.y + normalDir.z * centerOffset.z;

                o.pos = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
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
    FallBack "Transparent/VertexLit"
}
