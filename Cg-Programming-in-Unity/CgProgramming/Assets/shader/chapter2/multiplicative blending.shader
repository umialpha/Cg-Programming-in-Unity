Shader "Cg shader using multiplicative blending" {
	SubShader{
		Tags{ "Queue" = "Transparent" }
		// draw after all opaque geometry has been drawn
		Pass{
		Cull Off // draw front and back faces
		ZWrite Off // don't write to depth buffer
				   // in order not to occlude other objects
		Blend Zero SrcAlpha // multiplicative blending
							// for attenuation by the fragment's alpha
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
		return float4(1.0, 0.0, 0.0, 0.3);
		}
		ENDCG
	}
	}
}