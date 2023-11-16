Shader "MyShader/10-TextureImprove/Mirror"
{
    Properties {
        _MainTex("Main Tex", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.uv = v.texcoord;
                f.uv.x = 1 - f.uv.x;   // 翻转x分量的纹理坐标，使得镜子里显示的图像都左右相反
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                return tex2D(_MainTex, f.uv);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
