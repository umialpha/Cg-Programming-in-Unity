Shader "Cg shader better cutaways" {
	SubShader{
		
		Pass{
		Cull Off // turn off triangle culling, alternatives are:
				 // Cull Back (or nothing): cull only back faces
				 // Cull Front : cull only front faces
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
		float4x4 _Matrix;
		struct vertexInput {
		float4 vertex : POSITION;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 col : TEXCOORD0;
		float4 position_in_world_space: TEXCOORD1;
	};
	vertexOutput vert(appdata_full input)
		// vertex shader
	{
		vertexOutput output; // we don't need to type 'struct' here
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		output.col = input.texcoord;
		output.col = float4(
			(input.normal + float3(1.0, 1.0, 1.0)) / 2.0, 1.0);
		output.position_in_world_space =
			mul(unity_ObjectToWorld, input.vertex);
		return output;
	}
	
	
	float4 frag(vertexOutput input) : COLOR
	{
		float4 obj_pos = mul(_Matrix, input.position_in_world_space);
		float l = length(obj_pos);
		if (l <= 1.5)
		{
			discard; 
		}

		return input.col;
	}
		ENDCG
	}
	}
}