#ifndef __LONESTACK_CGINC_
#define __LONESTACK_CGINC_

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct ls_appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct ls_v2f
{
	float2 uv : TEXCOORD0;
	float4 vertex : SV_POSITION;
};

ls_v2f ls_vert(ls_appdata i)
{
	ls_v2f o;
	o.vertex = i.vertex;
	o.vertex.xy = o.vertex.xy * 2 - 1;
	o.uv = i.uv;
#if UNITY_UV_STARTS_AT_TOP
	o.uv.y = 1 - o.uv.y;
#endif
	return o;
}

#endif //!__LONESTACK_CGINC_