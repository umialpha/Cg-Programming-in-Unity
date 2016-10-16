shader "Cg shader with single texture" {
	Properties{
		_MainTex("Texture Image", 2D) = "white" {}
	// a 2D texture property that we call "_MainTex", which should
	// be labeled "Texture Image" in Unity's user interface.
	// By default we use the built-in texture "white"  
	// (alternatives: "black", "gray" and "bump").
	}
		SubShader{
		Pass{
		CGPROGRAM

#pragma vertex vert  
#pragma fragment frag 

		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
	// a uniform variable refering to the property above
	// (in fact, this is just a small integer specifying a 
	// "texture unit", which has the texture image "bound" 
	// to it; Unity takes care of this).

	struct vertexInput {
		float4 vertex : POSITION;
		float4 texcoord : TEXCOORD0;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 tex : TEXCOORD0;
	};

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;

		output.tex = input.texcoord;
		// Unity provides default longitude-latitude-like 
		// texture coordinates at all vertices of a 
		// sphere mesh as the input parameter 
		// "input.texcoord" with semantic "TEXCOORD0".
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}
	float4 frag(vertexOutput input) : COLOR
	{
		return tex2D(_MainTex,
		_MainTex_ST.xy * input.tex.xy + _MainTex_ST.zw);
	// look up the color of the texture image specified by 
	// the uniform "_MainTex" at the position specified by 
	// "input.tex.x" and "input.tex.y" and return it

	}

		ENDCG
	}
	}
		Fallback "Unlit/Texture"
}