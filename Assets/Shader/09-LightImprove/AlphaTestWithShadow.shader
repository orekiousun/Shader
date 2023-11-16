Shader "MyShader/09-LightImprove/AlphaTestWithShadow"
{
    Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			Cull Off
			
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert(a2v v) {
			 	v2f f;
			 	f.pos = UnityObjectToClipPos(v.vertex);
			 	f.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	f.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	TRANSFER_SHADOW(f);
			 	return f;
			}
			
			fixed4 frag(v2f f) : SV_Target {
				fixed3 worldNormal = normalize(f.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));
				fixed4 texColor = tex2D(_MainTex, f.uv);
				clip (texColor.a - _Cutoff);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
							 	
				UNITY_LIGHT_ATTENUATION(atten, f, f.worldPos);
			 	
				return fixed4(ambient + diffuse * atten, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/Cutout/VertexLit"
}
