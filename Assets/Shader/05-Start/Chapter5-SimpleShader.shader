Shader "MyShader/05-SimpleShader"   // 定义Shder名字
{
    Properties
    {
        // 声明一个color类型的属性
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader  
    {
        Pass   
        { 
            CGPROGRAM   
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;   // CG中需要定义一个属性和名称都匹配的变量

            struct a2v
            {
                float4 myVertex : POSITION;     
                float3 normal : NORMAL;      
                float4 texcoord : TEXCOORD0;  
            };

            struct v2f
            {
                float4 pos : SV_POSITION;  
                fixed3 myColor : COLOR0;   
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.myVertex);
                o.myColor = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);   
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                fixed3 c = i.myColor;
                // 使用Color属性来控制输出颜色
                c *= _Color.rgb;
                return fixed4(c, 1.0);
            }
            
            ENDCG
        }
    }
}
