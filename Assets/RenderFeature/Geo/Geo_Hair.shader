//利用一个三角形的两个顶点和生成的中心挤出顶点 生成一个三角形 
//3个三角形形成一个三棱锥 共使用9个顶点

Shader "Unlit/Geo_Hair"
{
   Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [PowerSlider(3.0)]_Length("Length",Range(0,20)) = 1
		_Color("Color",Color)=(1,1,1,1)
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
			};

			struct v2g {
				float4 vertex:POSITION;
				float2 uv:TEXCOORD0;
			};

			struct g2f {
				float4 vertex:SV_POSITION;
				float2 uv:TEXCOORD0;
				float4 col:COLOR;
			};

            float _Length;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;

			v2g vert(a2v v) {
				v2g o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

            //静态制定单个调用的最大顶点个数 
            // [NVIDIA08]指出，当GS输出在1到20个标量之间时，可以实现GS的性能峰值，如果GS输出在27-40个标量之间，则性能下降50％。
            [maxvertexcount(9)]
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
            
            void geom(triangle v2g IN[3],inout TriangleStream<g2f> tristream)
            {
                g2f o;
                float3 edgeA = IN[1].vertex - IN[0].vertex;
                float3 edgeB = IN[2].vertex - IN[0].vertex;
                float3 normalFace = normalize(cross(edgeA,edgeB));

                float3 centerPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
                float2 centerTex = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

                centerPos += normalFace * _Length;

                for(int i = 0; i<3;i++)
                {
                    o.vertex = TransformObjectToHClip(IN[i].vertex);
                    o.uv = IN[i].uv;
                    					//添加顶点
					tristream.Append(o);

					uint index = (i + 1) % 3;
					o.vertex = TransformObjectToHClip(IN[index].vertex);
					o.uv = IN[index].uv;
					o.col = half4(0., 0., 0., 1.);

					tristream.Append(o);

					//外部颜色白
					o.vertex = TransformObjectToHClip(float4(centerPos, 1));
					o.uv = centerTex;
					o.col = half4(1.0, 1.0, 1.0, 1.);

					tristream.Append(o);
					//添加三角面
					tristream.RestartStrip();
                }
              
                 // 对于TriangleStream ，如果需要改变输出图元，需要每输出点足够对应相应的图元后都要RestartStrip()一下再继续构成下一图元，
                // 如：tStream.RestartStrip();
            }

            float4 frag (g2f i) : SV_Target
            {
              float4 col = tex2D(_MainTex,i.uv)*i.col*_Color;
				return col;
            }
            ENDHLSL
        }
    }
}
