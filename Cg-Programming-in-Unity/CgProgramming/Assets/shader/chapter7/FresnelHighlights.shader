// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Cg Fresnel hightlighs" {
	Properties{
		_MainTex("RGBA Texture For Material Color", 2D) = "white" {}
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
		_BumpMap("Normal Map", 2D) = "bump" {}
	}

	CGINCLUDE	
	#include "UnityCG.cginc"
	uniform float4 _LightColor0;
	uniform sampler2D _MainTex;
	uniform float4 _MainTex_ST;
	uniform sampler2D _BumpMap;
	uniform float4 _BumpMap_ST;
	uniform float _Shininess;
	uniform float4 _SpecColor;
	struct vertexInput {
		float4 vertex: POSITION;
		float4 texcoord: TEXCOORD0;
		float3 normal: NORMAL;
		float3 tangent: TANGENT;
	};
	struct vertexOutput {
		float4 pos: SV_POSITION;
		float4 posWorld: TEXCOORD0;
		float4 tex: TEXCOORD1;
		float3 tangentWorld : TEXCOORD2;
		float3 normalWorld : TEXCOORD3;
		float3 binormalWorld : TEXCOORD4;
	};
				 
	vertexOutput vert(vertexInput input) {
		vertexOutput output;
		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;
		output.normalWorld = normalize(mul(input.normal, modelMatrixInverse));
		output.tangentWorld = normalize(mul(modelMatrix, input.tangent));
		output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld));
		output.tex = input.texcoord;
		output.posWorld = mul(modelMatrix, input.vertex);
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
		return output;
	}

	float4 fragWithAmbient(vertexOutput input): COLOR
	{
		float4 encodeNormal = tex2D(_BumpMap, 
								_BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
		float4 color = tex2D(_MainTex, 
								_MainTex_ST.xy * input.tex.xy + _MainTex_ST.zw);
		float3 localCoords = float3(2.0 * encodeNormal.a - 1.0,
									2.0 * encodeNormal.g - 1.0,
									0);
		localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));
		float3x3 local2WorldTranspose = float3x3(
										input.tangentWorld,
										input.binormalWorld,
										input.normalWorld
										);
		float3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection;
		float attenuation;
		if (0.0 == _WorldSpaceLightPos0.w) // directional light?
		{
			attenuation = 1.0; // no attenuation
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else {
			float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1.0 / distance;
			lightDirection = normalize(vertexToLightSource);
		}
		float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * color.rgb;
		float3 diffuseReflection = attenuation * _LightColor0.rgb
			* color.rgb * max(0, dot(normalDirection, lightDirection));
		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0) {
			// light source on the wrong side?
			specularReflection = float3(0.0, 0.0, 0.0);
		}
		else
		{	
			float3 halfwayDirection = normalize(lightDirection + viewDirection);
			float w = pow(1.0 - max(0.0, dot(halfwayDirection, viewDirection)), 5.0);
			float3 specColor = lerp(_SpecColor.rgb, float3(1.0, 1.0, 1.0), w);
			float3 reflectDirection = reflect(-lightDirection, normalDirection);
			specularReflection = attenuation * _LightColor0.rgb
				* specColor * pow(
									max(
										0.0, dot(reflectDirection, viewDirection)
									), _Shininess
								);
									
		}
		return float4(ambientLighting + diffuseReflection + specularReflection, 1.0);
						
	}

	float4 fragWithoutAmbient(vertexOutput input) : COLOR
	{
		float4 encodeNormal = tex2D(_BumpMap,
			_BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
		float4 color = tex2D(_MainTex,
			_MainTex_ST.xy * input.tex.xy + _MainTex_ST.zw);
		float3 localCoords = float3(2.0 * encodeNormal.a - 1.0,
			2.0 * encodeNormal.g - 1.0,
			0);
		localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));
		float3x3 local2WorldTranspose = float3x3(
			input.tangentWorld,
			input.binormalWorld,
			input.normalWorld
			);
		float3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDirection;
		float attenuation;
		if (0.0 == _WorldSpaceLightPos0.w) // directional light?
		{
			attenuation = 1.0; // no attenuation
			lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		}
		else {
			float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float distance = length(vertexToLightSource);
			attenuation = 1.0 / distance;
			lightDirection = normalize(vertexToLightSource);
		}
		float3 diffuseReflection = attenuation * _LightColor0.rgb
			* color.rgb * max(0, dot(normalDirection, lightDirection));
		float3 specularReflection;
		if (dot(normalDirection, lightDirection) < 0.0) {
			// light source on the wrong side?
			specularReflection = float3(0.0, 0.0, 0.0);
		}
		else
		{
			float3 halfwayDirection = normalize(lightDirection + viewDirection);
			float w = pow(1.0 - max(0.0, dot(halfwayDirection, viewDirection)), 5.0);
			float3 specColor = lerp(_SpecColor.rgb, float3(1.0, 1.0, 1.0), w);
			float3 reflectDirection = reflect(-lightDirection, normalDirection);
			specularReflection = attenuation * _LightColor0.rgb
				* specColor * pow(
					max(
						0.0, dot(reflectDirection, viewDirection)
					), _Shininess
					);

		}
		return float4(diffuseReflection + specularReflection, 1.0);
	}
	ENDCG
	SubShader {
		Pass{
			Tags{ "LightMode" = "ForwardBase" }
			// pass for ambient light and first light source

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment fragWithAmbient  
			// the functions are defined in the CGINCLUDE part
			ENDCG
		}

		Pass{
			Tags{ "LightMode" = "ForwardAdd" }
			// pass for additional light sources
			Blend One One // additive blending 

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment fragWithoutAmbient
			// the functions are defined in the CGINCLUDE part
			ENDCG
		}
	}
	
}
