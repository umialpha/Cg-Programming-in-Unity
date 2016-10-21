// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Cg translucent bodies" {
	Properties{
		_Color("Diffuse Color", Color) = (1,1,1,1)
		_Waxiness("Waxiness", Range(0,1)) = 0
		_SpecColor("Specular Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
		_TranslucentColor("Translucent Color", Color) = (0,0,0,1)
	}
		CGINCLUDE
		#include "UnityCG.cginc"
		uniform float4 _LightColor0;
		// color of light source (from "Lighting.cginc")
		// User-specified properties
		uniform float4 _Color;
		uniform float _Waxiness;
		uniform float4 _SpecColor;
		uniform float _Shininess;
		uniform float4 _TranslucentColor;
		struct vertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};
		struct vertexOutput {
			float4 pos : SV_POSITION;
			float4 posWorld : TEXCOORD0;
			float3 normalDir : TEXCOORD1;
		};
		vertexOutput waxniessvert(vertexInput input)
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
		ENDCG


		SubShader{
		// pass for 
		// ambient light and first light source on back faces
		// render back faces only
		// mark rasterized pixels in framebuffer with alpha = 0
		Pass{
		Tags {"LightMode" = "ForwardBase"}
		Cull Front
		Blend One Zero
		CGPROGRAM
		#pragma vertex waxniessvert
		#pragma fragment frag
		
		
		float4 frag(vertexOutput input): COLOR
		{
			float3 normalDirection = normalize(input.normalDir);
			float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
			float3 lightDirection;
			float attenuation;
			if (0.0 == _WorldSpaceLightPos0.w)
			{
				attenuation = 1.0;
				lightDirection = normalize(_WorldSpaceLightPos0.xyz);
			}
			else{
				float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float distance = length(vertexToLightSource);
				attenuation = 1.0 / distance;
				lightDirection = normalize(vertexToLightSource);
			}
			float3 ambientLighting = _TranslucentColor.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;
			float3 diffuseReflection = _TranslucentColor.rgb * attenuation * _LightColor0.rgb
			* max(0.0, dot(normalDirection, lightDirection));
			float silhouetteness = 1.0 - abs(dot(viewDirection, normalDirection));
			return float4(silhouetteness*(ambientLighting + diffuseReflection), 0);
		}

		ENDCG
		}
		PASS
		{
			Tags{"LightMode" = "ForwardAdd"}
			Cull Front  // render back faces only
			Blend One One  // additive blending
			CGPROGRAM
			#pragma vertex waxniessvert
			#pragma fragment frag
			float4 frag(vertexOutput input): COLOR
			{
				float3 normalDirection = normalize(input.normalDir);
				float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
				float3 lightDirection;
				float attenuation;
				if(0.0 == _WorldSpaceLightPos0.w ){
					attenuation = 1.0;
					lightDirection = _WorldSpaceCameraPos.xyz;
				}else{
					float3 vertexToLightSource  = _WorldSpaceCameraPos.xyz - input.posWorld.xyz;
					lightDirection = normalize(vertexToLightSource);
					float3 distance = length(vertexToLightSource);
					attenuation = 1 / distance;
				}
				float3 diffuseReflection = _TranslucentColor.rgb * attenuation *
				_LightColor0 * max(0.0, dot(normalDirection, viewDirection));
				float silhouetteness = 
				1.0 - abs(dot(viewDirection, normalDirection));
				return float4(silhouetteness * diffuseReflection, 0.0);
			}
			
			ENDCG
		}
		PASS{
			Tags{"LightMode" = "ForwardBase"}
			Cull Back  // render front faces only (default behavior)
			// set colors of pixels with alpha = 1 to black by multiplying with 1 - alpha
			Blend Zero OneMinusDstColor
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			 float4 vert(float4 vertexPos : POSITION) : SV_POSITION 
			 {
				return mul(UNITY_MATRIX_MVP, vertexPos);
			 }
 
			 float4 frag(void) : COLOR 
			 {
				return float4(0.0, 0.0, 0.0, 0.0); 
			 }
			 ENDCG  
		}
		PASS{
			Tags{ "LightMode" = "ForwardBase"}
			Cull Back
			// multiply color in framebuffer
			// with silhouetteness in fragment's alpha and add colors
			Blend One SrcAlpha
			CGPROGRAM
			#pragma vertex waxniessvert  
			#pragma fragment frag 
			float4 frag(vertexOutput input): COLOR
			{
				float3 normalDirection = normalize(input.normalDir);
				float3 viewDirection = normalize( _WorldSpaceCameraPos - input.posWorld.xyz);
				float3 attenuation;
				float3 lightDirection;
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
				   attenuation = 1.0; // no attenuation
				   lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				} 
				else // point or spot light
				{
				   float3 vertexToLightSource = 
					  _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				   float distance = length(vertexToLightSource);
				   attenuation = 1.0 / distance; // linear attenuation 
				   lightDirection = normalize(vertexToLightSource);
				}
 
				float3 ambientLighting = 
				   UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
				float3 diffuseReflection = 
					attenuation * _LightColor0.rgb * _Color.rgb
					*(_Waxiness + (1.0 - _Waxiness) * max(0.0, dot(normalDirection, lightDirection)));
				float3 specularReflection;
				if (dot(normalDirection, lightDirection) < 0.0)
				{
					specularReflection = float3(0.0, 0.0, 0.0);
				}
				else{
					specularReflection = attenuation * _LightColor0.rgb 
					* _SpecColor.rgb * pow(max(0.0, dot(
					reflect(-lightDirection, normalDirection), 
					viewDirection)), _Shininess);
				}
				float silhouetteness = 1.0 - abs(dot(viewDirection, normalDirection));
				return float4(ambientLighting + diffuseReflection 
               + specularReflection, silhouetteness);
			}
			ENDCG 
		}
		PASS{
			Tags{"LightMode" = "ForwardAdd"}
			Cull Back
			Blend One One

			CGPROGRAM
			#pragma vertex waxniessvert  
			#pragma fragment frag 
			float4 frag(vertexOutput input): COLOR
			{
				float3 normalDirection = normalize(input.normalDir);
				float3 viewDirection = normalize( _WorldSpaceCameraPos - input.posWorld.xyz);
				float3 attenuation;
				float3 lightDirection;
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					attenuation = 1.0; // no attenuation
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				} 
				else // point or spot light
				{
					float3 vertexToLightSource = 
						_WorldSpaceLightPos0.xyz - input.posWorld.xyz;
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance; // linear attenuation 
					lightDirection = normalize(vertexToLightSource);
				}
				float3 diffuseReflection = 
					attenuation * _LightColor0.rgb * _Color.rgb
					*(_Waxiness + (1.0 - _Waxiness) * max(0.0, dot(normalDirection, lightDirection)));
				float3 specularReflection;
				if (dot(normalDirection, lightDirection) < 0.0)
				{
					specularReflection = float3(0.0, 0.0, 0.0);
				}
				else{
					specularReflection = attenuation * _LightColor0.rgb 
						* _SpecColor.rgb * pow(max(0.0, dot(
						reflect(-lightDirection, normalDirection), 
						viewDirection)), _Shininess);
				}
				float silhouetteness = 1.0 - abs(dot(viewDirection, normalDirection));
				return float4(diffuseReflection 
				+ specularReflection, silhouetteness);
			}
			ENDCG 
		}
	}
}
