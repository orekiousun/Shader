Shader "MyShader/08-Transparent/AlphaTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { 
            "Queue"="AlphaTest"
            "IgnoreProjector" = "True"
            "RenderType" = "TransparentCutout"
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.worldNormal = UnityObjectToWorldNormal(v.normal);
                f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return f;
            }

            fixed4 frag (v2f f) : SV_Target {
                fixed3 worldNormal = normalize(f.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
                fixed4 albedo = tex2D(_MainTex, f.uv);
                clip(albedo.a - _Cutoff);   // 如果 texColor.a - _Cutoff < 0 则直接舍弃当前像素的输出颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, 1);
;            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
