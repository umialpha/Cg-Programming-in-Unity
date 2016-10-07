Shader "Cg shader with two passes using discard" {
	SubShader{
		// first pass (is executed before the second pass)
		Pass{
		Cull Front // cull only front faces
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		struct vertexInput {
		float4 vertex : POSITION;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 posInObjectCoords : TEXCOORD0;
	};
	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		output.posInObjectCoords = input.vertex;
		return output;
	}
	float4 frag(vertexOutput input) : COLOR
	{
		if (input.posInObjectCoords.y > 0.0)
		{
			discard; // drop the fragment if y coordinate > 0
		}
		if (input.posInObjectCoords.x > 0.0)
		{
			if (input.posInObjectCoords.z > 0.0)
			{
				return float4(1.0, 0.0, 0.0, 1.0);
			}
			return float4(0.0, 1.0, 0.0, 1.0); // red
		}
		else {
			
			if (input.posInObjectCoords.z > 0.0)
			{
				return float4(1.0, 1.0, 0.0, 1.0);
			}
			return float4(0.0, 0.0, 1.0, 1.0); // red
		}
		
	}
		ENDCG
	}
		// second pass (is executed after the first pass)
		Pass{
		Cull Back // cull only back faces
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		struct vertexInput {
		float4 vertex : POSITION;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 posInObjectCoords : TEXCOORD0;
	};
	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		output.posInObjectCoords = input.vertex;
		return output;
	}
	float4 frag(vertexOutput input) : COLOR
	{
		if (input.posInObjectCoords.y > 0.0)
		{
			discard; // drop the fragment if y coordinate > 0
		}
		return float4(0.2, 0.3, 0.4, 1.0);
	}
		ENDCG
	}
	} 
}