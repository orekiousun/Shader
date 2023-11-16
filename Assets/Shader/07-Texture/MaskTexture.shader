Shader "MyShader/07-Texture/MaskTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}

        _BumpMap("Normal Map", 2D) = "bump" {}         
        _BumpScale("Bump Scale", Float) = 1.0      

        _SpecularMask ("Specular Mask", 2D) = "white" {}
        _SpecularScale ("Specular Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            
            fixed4 _Color; 
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _BumpMap;
            float _BumpScale;

            sampler2D _SpecularMask; 
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;


            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);
                f.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                TANGENT_SPACE_ROTATION;
                
                f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                f.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                
                return f;
            }

            fixed4 frag (v2f f) : SV_Target
            {
                fixed3 tangentLightDir = normalize(f.lightDir);
                fixed3 tangentViewDir = normalize(f.viewDir);

                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, f.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, f.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

                // 利用r分量计算掩码值
                fixed specularMask = tex2D(_SpecularMask, f.uv).r * _SpecularScale;
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss) * specularMask;

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
