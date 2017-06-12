// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/EdgeBlend"
{
	Properties
	{
		_Fade("Fade",Range(0,1)) = 1.0
		_Dist("Dist",Range(0,1)) = 0.1
		[Toggle] _ShowCam1("Show Cam 1",Float) = 1
		[Toggle] _ShowCam2("Show Cam 2",Float) = 1
		_MainTex("Cam1 Tex",2D) = "white" {}
		_MainTex2("Cam2 Tex",2D) = "white" {}

	}

		SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Overlay" }
		LOD 100

		ZTest Always        //Draw no matter what
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha        //Alpha Blending

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4x4 _Cam1Matrix;
			float4x4 _Cam2Matrix;

			float _Fade;
			float _Dist;

			uniform sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform sampler2D _MainTex2;
			float4 _MainTex2_ST;

			float _ShowCam1;
			float _ShowCam2;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
				float2 camUV1 : TEXCOORD1;
				float2 camUV2 : TEXCOORD2;
			};


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float4 camVertex1 = mul(_Cam1Matrix, v.vertex);
				o.camUV1 = camVertex1 / camVertex1.w;


				float4 camVertex2 = mul(_Cam2Matrix, v.vertex);
				o.camUV2 = camVertex2 / camVertex2.w;


				return o;
			}


			fixed4 frag(v2f i) : SV_Target
			{

				bool isOutsideCam1 = (i.camUV1.x < -1 || i.camUV1.y < -1 || i.camUV1.x > 1 || i.camUV1.y > 1);
				bool isOutsideCam2 = (i.camUV2.x < -1 || i.camUV2.y < -1 || i.camUV2.x > 1 || i.camUV2.y > 1);

				bool isCam1Border = (i.camUV1.x - _Dist < -1 || i.camUV1.y - _Dist < -1 || i.camUV1.x + _Dist > 1 || i.camUV1.y + _Dist > 1);
				bool isCam2Border = (i.camUV2.x - _Dist < -1 || i.camUV2.y - _Dist < -1 || i.camUV2.x + _Dist > 1 || i.camUV2.y + _Dist > 1);



				if (isOutsideCam1 && isOutsideCam2)
				{
					return fixed4(0, 0, 0, .3f);
				} else if (isOutsideCam1)
				{
					return fixed4(0, 1, 0, 1);
				} else if (isOutsideCam2)
				{
					return fixed4(1, 0, 0, 1);
				} else
				{
					//in both cams
					if (isCam1Border && isCam2Border) return fixed4(1, 0, 1, 1);
					else if (isCam1Border) return fixed4(1, 1, 0, 1);
					else if (isCam2Border) return fixed4(0, 0, 1, 1);
					else
					{
						//inside
						float minCam1Dist = min(1 - abs(i.camUV1.x), 1 - abs(i.camUV1.y));
						float minCam2Dist = min(1 - abs(i.camUV2.x), 1 - abs(i.camUV2.y));
						float p = .5;
						if (minCam1Dist < minCam2Dist) p = (max((minCam1Dist / minCam2Dist)-(1-_Fade),0))*.5;
						else if (minCam2Dist < minCam1Dist) p = 1-(max((minCam2Dist / minCam1Dist)-(1-_Fade),0))*.5;

						fixed4 col1 = tex2D(_MainTex, i.camUV1.xy) * p;
						fixed4 col2 = tex2D(_MainTex2, i.camUV2.xy) * (1 - p);
						fixed4 col = fixed4(0, 0, 0, 1);
						if (_ShowCam1) col += col1;
						if (_ShowCam2) col += col2;
						col.a = min(col.a, 1);
						return col;
					}

				}
			}
		ENDCG
		}
	}

		FallBack "Diffuse"
}
