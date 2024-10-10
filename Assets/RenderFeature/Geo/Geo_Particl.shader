//由三个顶点生成一个顶点并沿法线挤出 最后仅输出生成的顶点 几何着色器
Shader "Unlit/Geo_Particl"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Size("Size",Range(0.0,10)) = 0.0
		_Color("Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v {
				float4 vertex:POSITION;
				float2 uv:TEXCOORD0;
				float3 normal:NORMAL;
			};

           struct v2g {
				float4 vertex:POSITION;
				float2 uv:TEXCOORD0;
			};
            struct g2f {
				float4 vertex:SV_POSITION;
				float2 uv:TEXCOORD0;
			};

            float _Size;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;

            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = (v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            //静态制定单个调用的最大顶点个数 
            // [NVIDIA08]指出，当GS输出在1到20个标量之间时，可以实现GS的性能峰值，如果GS输出在27-40个标量之间，则性能下降50％。
            [maxvertexcount(1)]
            // 输入类型 point v2g input[1]
            // point ： 输入图元为点，1个顶点
            // line ： 输入图元为线，2个顶点
            // triangle ： 输入图元为三角形，3个顶点
            // lineadj ： 输入图元为带有邻接信息的直线，由4个顶点构成3条线
            // triangleadj ： 输入图元为带有邻接信息的三角形，由6个顶点构成

            // 输出类型  inout PointStream<g2f> outStream  可以自定义结构体，g2f、v2f...
            //inout:关键词
            //TriangleStream: 输出类型，如下：
            // PointStream ： 输出图元为点
            // LineStream ： 输出图元为线
            // TriangleStream ： 输出图元为三角形
            
            void geom(triangle v2g IN[3],inout PointStream<g2f> pointStream)
            {
                g2f o;
                float3 edgeA = IN[1].vertex - IN[0].vertex;
                float3 edgeB = IN[2].vertex - IN[0].vertex;
                float3 normalFace = normalize(cross(edgeA,edgeB));

                float3 tempPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

                 tempPos += normalFace * _Size;
                o.vertex = TransformObjectToHClip(tempPos);
                o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
                pointStream.Append(o);
            }

            float4 frag (g2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex,i.uv)*_Color;
				return col;
            }
            ENDHLSL
        }
    }
}
