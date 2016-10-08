// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Cg per-vertex diffuse lighting" {
	Properties{
		_Color("Diffuse Material Color", Color) = (1,1,1,1)
	}
		SubShader{
			Pass{
			Tags{ "LightMode" = "ForwardBase" }
			// make sure that all uniforms are correctly set
			CGPROGRAM
			#include "UnityCG.cginc" // for UnityObjectToWorldNormal
			#include "UnityLightingCommon.cginc" // for _LightColor0
			#pragma vertex vert
			#pragma fragment frag
			uniform float4 _Color; // define shader property for shaders
								   // The following built-in uniforms (apart from _LightColor0)
								   // are defined in "UnityCG.cginc", which could be #included

			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 col : COLOR;
			};
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;
				// multiplication with unity_Scale.w is unnecessary
				// because we normalize transformed vectors
				float3 normalDirection = normalize(float3(mul(float4(input.normal, 0.0), modelMatrixInverse).xyz));
				float3 lightDirection;
				float attenuation;
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					attenuation = 1.0; // no attunuation
					lightDirection = normalize(float3(_WorldSpaceLightPos0.xyz));
				}
				else  // point or spot light
				{
					float3 vertexToLightSource = float3(_WorldSpaceLightPos0.xyz) - mul(modelMatrix, input.vertex);
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance;
					lightDirection = normalize(vertexToLightSource);
				}
				float3 diffuseReflection = attenuation * float3(_LightColor0.xyz)
					* float3(_Color.xyz)* max(0.0, dot(normalDirection, lightDirection));
				output.col = float4(diffuseReflection, 1.0);
				output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
				return output;
			}
			float4 frag(vertexOutput input) : COLOR
			{
				return input.col;
			}
				ENDCG
		}
			Pass{
			Tags { "LightMode" = "ForwardAdd"}
			Blend One One
			CGPROGRAM
				#include "UnityCG.cginc" // for UnityObjectToWorldNormal
			#include "UnityLightingCommon.cginc" // for _LightColor0
	#pragma vertex vert
	#pragma fragment frag
				uniform	float4 _Color;
			struct vertexInput {
				float4 vertex: POSITION;
				float3 normal: NORMAL;
			};
			struct vertexOutput {
				float4 pos: SV_POSITION;
				float4 col: COLOR;
			};
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;
				// multiplication with unity_Scale.w is unnecessary
				// because we normalize transformed vectors
				float3 normalDirection = normalize(float3(mul(float4(input.normal, 0.0), modelMatrixInverse).xyz));
				float3 lightDirection;
				float attenuation;
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					attenuation = 1.0; // no attunuation
					lightDirection = normalize(float3(_WorldSpaceLightPos0.xyz));
				}
				else  // point or spot light
				{
					float3 vertexToLightSource = float3(_WorldSpaceLightPos0.xyz) - mul(modelMatrix, input.vertex);
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance;
					lightDirection = normalize(vertexToLightSource);
				}
				float3 diffuseReflection = attenuation * float3(_LightColor0.xyz)
					* float3(_Color.xyz)* max(0.0, dot(normalDirection, lightDirection));
				output.col = float4(diffuseReflection, 1.0);
				output.pos = mul(UNITY_MATRIX_MVP, input.vertex);
				return output;
			}
			float4 frag(vertexOutput input) : COLOR
			{
				return input.col;
			}
				ENDCG

			}
	}
		// The definition of a fallback shader should be commented out
		// during development:
		// Fallback "Diffuse"
}