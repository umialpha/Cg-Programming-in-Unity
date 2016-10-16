// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Cg per-pixel lighting with cookies" {
	Properties{
		_Color("Diffuse Material Color", Color) = (1,1,1,1)
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
	}
		SubShader{
		Pass{
		Tags{ "LightMode" = "ForwardBase" } // pass for ambient light 
											// and first directional light source without cookie

		CGPROGRAM

#pragma vertex vert  
#pragma fragment frag 

#include "UnityCG.cginc"
		uniform float4 _LightColor0;
	// color of light source (from "Lighting.cginc")

	// User-specified properties
	uniform float4 _Color;
	uniform float4 _SpecColor;
	uniform float _Shininess;

	struct vertexInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 posWorld : TEXCOORD0;
		float3 normalDir : TEXCOORD1;
	};

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		output.posWorld = mul(modelMatrix, input.vertex);
		output.normalDir = normalize(
			mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}

	float4 frag(vertexOutput input) : COLOR
	{
		float3 normalDirection = normalize(input.normalDir);

		float3 viewDirection = normalize(
			_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection =
			normalize(_WorldSpaceLightPos0.xyz);

		float3 ambientLighting =
			UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

		float3 diffuseReflection =
			_LightColor0.rgb * _Color.rgb
			* max(0.0, dot(normalDirection, lightDirection));

		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0)
			// light source on the wrong side?
		{
			specularReflection = float3(0.0, 0.0, 0.0);
			// no specular reflection
		}
		else // light source on the right side
		{
			specularReflection = _LightColor0.rgb
				* _SpecColor.rgb * pow(max(0.0, dot(
					reflect(-lightDirection, normalDirection),
					viewDirection)), _Shininess);
		}

		return float4(ambientLighting + diffuseReflection
			+ specularReflection, 1.0);
	}

		ENDCG
	}

		Pass{
		Tags{ "LightMode" = "ForwardAdd" }
		// pass for additional light sources
		Blend One One // additive blending 

		CGPROGRAM

#pragma multi_compile_lightpass

#pragma vertex vert  
#pragma fragment frag 

#include "UnityCG.cginc"
		uniform float4 _LightColor0;
	// color of light source (from "Lighting.cginc")
	uniform float4x4 unity_WorldToLight; // transformation 
									// from world to light space (from Autolight.cginc)
#if defined (DIRECTIONAL_COOKIE) || defined (SPOT)
	uniform sampler2D _LightTexture0;
	// cookie alpha texture map (from Autolight.cginc)
#elif defined (POINT_COOKIE)
	uniform samplerCUBE _LightTexture0;
	// cookie alpha texture map (from Autolight.cginc)
#endif

	// User-specified properties
	uniform float4 _Color;
	uniform float4 _SpecColor;
	uniform float _Shininess;

	struct vertexInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 posWorld : TEXCOORD0;
		// position of the vertex (and fragment) in world space 
		float4 posLight : TEXCOORD1;
		// position of the vertex (and fragment) in light space
		float3 normalDir : TEXCOORD2;
		// surface normal vector in world space
	};

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		output.posWorld = mul(modelMatrix, input.vertex);
		output.posLight = mul(unity_WorldToLight, output.posWorld);
		output.normalDir = normalize(
			mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}

	float4 frag(vertexOutput input) : COLOR
	{
		float3 normalDirection = normalize(input.normalDir);

		float3 viewDirection = normalize(
			_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection;
		float attenuation = 1.0;
		// by default no attenuation with distance

#if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
		lightDirection = normalize(_WorldSpaceLightPos0.xyz);
#elif defined (POINT_NOATT)
		lightDirection = normalize(
			_WorldSpaceLightPos0 - input.posWorld.xyz);
#elif defined(POINT)||defined(POINT_COOKIE)||defined(SPOT)
		float3 vertexToLightSource =
			_WorldSpaceLightPos0.xyz - input.posWorld.xyz;
		float distance = length(vertexToLightSource);
		attenuation = 1.0 / distance; // linear attenuation 
		lightDirection = normalize(vertexToLightSource);
#endif

		float3 diffuseReflection =
			attenuation * _LightColor0.rgb * _Color.rgb
			* max(0.0, dot(normalDirection, lightDirection));

		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0)
			// light source on the wrong side?
		{
			specularReflection = float3(0.0, 0.0, 0.0);
			// no specular reflection
		}
		else // light source on the right side
		{
			specularReflection = attenuation * _LightColor0.rgb
				* _SpecColor.rgb * pow(max(0.0, dot(
					reflect(-lightDirection, normalDirection),
					viewDirection)), _Shininess);
		}

		float cookieAttenuation = 1.0;
		// by default no cookie attenuation
#if defined (DIRECTIONAL_COOKIE)
		cookieAttenuation = tex2D(_LightTexture0,
			input.posLight.xy).a;
#elif defined (POINT_COOKIE)
		cookieAttenuation = texCUBE(_LightTexture0,
			input.posLight.xyz).a;
#elif defined (SPOT)
		cookieAttenuation = tex2D(_LightTexture0,
			input.posLight.xy / input.posLight.w
			+ float2(0.5, 0.5)).a;
#endif

		return float4(cookieAttenuation
			* (diffuseReflection + specularReflection), 1.0);
	}

		ENDCG
	}
	}
		Fallback "Specular"
}