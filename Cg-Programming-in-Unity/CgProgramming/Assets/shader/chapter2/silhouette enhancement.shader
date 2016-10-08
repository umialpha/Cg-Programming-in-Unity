Shader "Cg silhouette enhancement" {
	Properties{
		_Color("Color", Color) = (0, 1, 1, 0.5)
		// user-specified RGBA color including opacity
	}
		SubShader{
		Tags{ "Queue" = "Transparent" }
		// draw after all opaque geometry has been drawn
		Pass{
		ZWrite Off // don't occlude other objects
		Blend SrcAlpha OneMinusSrcAlpha // standard alpha blending
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		uniform float4 _Color; // define shader property for shaders
							   // The following built-in uniforms are also defined in
							   // "UnityCG.cginc", which could be #included
	//uniform float4 uscale = float4(1,1,1,1); // w = 1/scale; see _World2Object
	// uniform float3 _WorldSpaceCameraPos;
	// uniform float4x4 _Object2World; // model matrix
	// uniform float4x4 _World2Object; // inverse model matrix
									// (all but the bottom-right element have to be scaled
									// with unity_Scale.w if scaling is important)
	struct vertexInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float3 normal : TEXCOORD;
		float3 viewDir : TEXCOORD1;
	};
	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;
		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;
		// multiplication with unity_Scale.w is unnecessary
		// because we normalize transformed vectors
		/**
		for Normal Transformation
		use:
			mul(normal, WorldToObj )
		see:http://www.lighthouse3d.com/tutorials/glsl-12-tutorial/the-normal-matrix/
		**/
		float4 p4 = mul(float4(input.normal, 0.0), modelMatrixInverse);
		float3 p3 = float3(p4.xyz);
		output.normal = normalize(p3);
		output.viewDir = normalize(_WorldSpaceCameraPos
			- float3(mul(modelMatrix, input.vertex).xyz));
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}
	float4 frag(vertexOutput input) : COLOR
	{
		float3 normalDirection = normalize(input.normal);
		float3 viewDirection = normalize(input.viewDir);
		float dotAngle = abs(dot(viewDirection, normalDirection));
		float newOpacity = min(1.0, _Color.a / dotAngle);
		return float4(float3(_Color.xyz) / dotAngle, newOpacity);
	}
		ENDCG
	}
	}
}