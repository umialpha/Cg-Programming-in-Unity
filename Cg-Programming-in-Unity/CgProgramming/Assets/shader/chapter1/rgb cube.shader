Shader "Cg shader for RGB cube" {
	SubShader{
		Pass{
		CGPROGRAM
#pragma vertex vert // vert function is the vertex shader
#pragma fragment frag // frag function is the fragment shader
#include "UnityCG.cginc"
		// for multiple vertex output parameters an output structure
		// is defined:
		struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 col : TEXCOORD0;
	};
	vertexOutput vert(appdata_full input)
		// vertex shader
	{
		vertexOutput output; // we don't need to type 'struct' here
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		output.col = input.texcoord;
		output.col = float4(
			(input.normal + float3(1.0, 1.0, 1.0)) / 2.0, 1.0);
		return output;
	}
	float4 frag(vertexOutput input) : COLOR // fragment shader
	{	
		return input.col;
	// Here the fragment shader returns the "col" input
	// parameter with semantic TEXCOORD0 as nameless
	// output parameter with semantic COLOR.
	}
		ENDCG
	}
	}
}