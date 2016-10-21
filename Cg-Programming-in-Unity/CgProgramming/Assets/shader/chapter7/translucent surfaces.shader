// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Cg translucent surfaces" {
	Properties{
	_Color("Diffuse Material Color", Color) = (1,1,1,1)
	_SpecColor("Specular Material Color", Color) = (1,1,1,1)
	_Shininess("Shininess", Float) = 10
	_DiffuseTranslucentColor("Diffuse Translucent Color", Color)
	= (1,1,1,1)
	_ForwardTranslucentColor("Forward Translucent Color", Color)
	= (1,1,1,1)
	_Sharpness("Sharpness", Float) = 10
	}
		CGINCLUDE
	#include "UnityCG.cginc"
	uniform float4 _LightColor0;
	uniform float4 _Color;
	uniform float4 _SpecColor;
	uniform float _Shininess;
	uniform float4 _DiffuseTranslucentColor;
	uniform float4 _ForwardTranslucentColor;
	uniform float _Sharpness;
	
	struct vertexInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float3 posWorld: TEXCOORD0;
		float3 normalDir: TEXCOORD1;
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
	float4 fragWithAmbient(vertexOutput input) : COLOR
	{
		float3 normalDirection = normalize(input.normalDir);
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		normalDirection = faceforward(normalDirection, -viewDirection, normalDirection);
		float3 lightDirection;
		float attenuation;
		if (0.0 == _WorldSpaceLightPos0.w)
		{
			attenuation = 1.0;
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else
		{
			float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1 / distance;
			lightDirection = normalize(vertexToLightSource);
		}
		// computation of the Phong reflection model
		float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
		float diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb
			* max(0.0, dot(normalDirection, lightDirection));
		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0)
		{
			specularReflection = float3(0.0, 0.0, 0.0);
		}
		else
		{
			float powBase = max(0.0, dot(reflect(-lightDirection, normalDirection), normalDirection));
			specularReflection = attenuation * _LightColor0.rgb
				* _SpecColor.rgb * pow(powBase, _Shininess);
		}

		// computation of the translucent illumination
		float3 diffuseTranslucency = attenuation * _LightColor0.rgb
			* _DiffuseTranslucentColor.rgb * max(0.0, dot(lightDirection, -normalDirection)); // here is the difference
		float3 forwardTranslucency;
		if (dot(normalDirection, lightDirection) > 0.0)
		{
			forwardTranslucency = float3(0.0, 0.0, 0.0);
		}
		else
		{
			forwardTranslucency = attenuation * _LightColor0.rgb
				* _ForwardTranslucentColor.rgb * pow(max(0.0,
					dot(-lightDirection, viewDirection)), _Sharpness);
		}
		return float4(ambientLighting
			+ diffuseReflection + specularReflection
			+ diffuseTranslucency + forwardTranslucency, 1.0);
	}
	float4 fragWithoutAmbient(vertexOutput input) : COLOR
	{
		float3 normalDirection = normalize(input.normalDir);
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		normalDirection = faceforward(normalDirection, -viewDirection, normalDirection);
		float3 lightDirection;
		float attenuation;
		if (0.0 == _WorldSpaceLightPos0.w)
		{
			attenuation = 1.0;
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else
		{
			float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1 / distance;
			lightDirection = normalize(vertexToLightSource);
		}
		// computation of the Phong reflection model
		float diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb
			* max(0.0, dot(normalDirection, lightDirection));
		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0)
		{
			specularReflection = float3(0.0, 0.0, 0.0);
		}
		else
		{
			float powBase = max(0.0, dot(reflect(-lightDirection, normalDirection), normalDirection));
			specularReflection = attenuation * _LightColor0.rgb
				* _SpecColor.rgb * pow(powBase, _Shininess);
					
		}

		// computation of the translucent illumination
		float3 diffuseTranslucency = attenuation * _LightColor0.rgb
			* _DiffuseTranslucentColor.rgb * max(0.0, dot(lightDirection, -normalDirection)); // here is the difference
		float3 forwardTranslucency;
		if (dot(normalDirection, lightDirection) > 0.0)
		{
			forwardTranslucency = float3(0.0, 0.0, 0.0);
		}
		else
		{
			forwardTranslucency = attenuation * _LightColor0.rgb
				* _ForwardTranslucentColor.rgb * pow(max(0.0,
					dot(-lightDirection, viewDirection)), _Sharpness);
		}
		return float4(
			diffuseReflection + specularReflection
			+ diffuseTranslucency + forwardTranslucency, 1.0);
	}
		ENDCG
		SubShader {
			Pass{
				Tags{ "lightMode" = "ForwardBase" }
				Cull Off
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment fragWithAmbient
				ENDCG
			}
			Pass{
				Tags{ "lightMode" = "ForwardBase" }
				Cull Off
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment fragWithoutAmbient
				ENDCG
		}
	}
}
