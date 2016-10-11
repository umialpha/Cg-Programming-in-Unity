Shader "Cg semitransparent colors based on alpha" {
	Properties{
		_MainTex("RGBA Texture Image", 2D) = "white" {}
	}
		SubShader{
		Tags{ "Queue" = "Transparent" }

		Pass{
		Cull Front // first render the back faces
		ZWrite Off // don't write to depth buffer 
				   // in order not to occlude other objects
		Blend SrcAlpha OneMinusSrcAlpha
		// blend based on the fragment's alpha value

		CGPROGRAM

#pragma vertex vert  
#pragma fragment frag 

		uniform sampler2D _MainTex;

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
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}

	float4 frag(vertexOutput input) : COLOR
	{
		float4 color = tex2D(_MainTex, input.tex.xy);
		if (color.a < 0.1) // opaque front face?
		{
			color = float4(0.0, 0.0, 1.0, 0.3);
			// opaque green
		}
		return color;
	}

		ENDCG
	}

		Pass{
		Cull Back // now render the front faces
		ZWrite Off // don't write to depth buffer 
				   // in order not to occlude other objects
		Blend SrcAlpha OneMinusSrcAlpha
		// blend based on the fragment's alpha value

		CGPROGRAM

#pragma vertex vert  
#pragma fragment frag 

		uniform sampler2D _MainTex;

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
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}

	float4 frag(vertexOutput input) : COLOR
	{
		float4 color = tex2D(_MainTex, input.tex.xy);
		if (color.a < 0.1) // opaque front face?
		{
			color = float4(0.0, 0.0, 1.0, 0.3);
			// opaque green
		}
		
		return color;
	}

		ENDCG
	}
	}
		Fallback "Unlit/Transparent"
}