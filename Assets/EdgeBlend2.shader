// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/EdgeBlend2"
{
	Properties
	{
		_NumCams("NumCams",Range(1,6)) = 2
		_TargetCam("TargetCam",Range(0,6)) = 0
		_Fade("Fade",Range(-10,1)) = 0
		_Expo("Expo",Range(0,10)) = 0.1
		
		_MainTex("Main Tex",2D) = "white"{}
		
	
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
			float4x4 _Cam3Matrix;
			float4x4 _Cam4Matrix;
			float4x4 _Cam5Matrix;
			float4x4 _Cam6Matrix;

			float _Fade;
			float _Expo;
			float _NumCams;
			float _TargetCam;

			uniform sampler2D _MainTex;
			float4 _MainTex_ST;

			uniform sampler2D _DistTex;
			float4 _DistTex_ST;


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
				float2 camUV3 : TEXCOORD3;
				float2 camUV4 : TEXCOORD4;
				float2 camUV5 : TEXCOORD5;
				float2 camUV6 : TEXCOORD6;
			};


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float4 camVertex1 = mul(_Cam1Matrix, v.vertex);
				o.camUV1 = (camVertex1 / camVertex1.w)*.5 + .5;

				float4 camVertex2 = mul(_Cam2Matrix, v.vertex);
				o.camUV2 = (camVertex2 / camVertex2.w)*.5 + .5;

				float4 camVertex3 = mul(_Cam3Matrix, v.vertex);
				o.camUV3 = (camVertex3 / camVertex3.w)*.5 + .5;

				float4 camVertex4 = mul(_Cam4Matrix, v.vertex);
				o.camUV4 = (camVertex4 / camVertex4.w)*.5 + .5;

				float4 camVertex5 = mul(_Cam5Matrix, v.vertex);
				o.camUV5 = (camVertex5 / camVertex5.w)*.5 + .5;

				float4 camVertex6 = mul(_Cam6Matrix, v.vertex);
				o.camUV6 = (camVertex6 / camVertex6.w)*.5 + .5;


				return o;
			}


			fixed4 frag(v2f i) : SV_Target
			{
				
				float2 camUV[6] = {i.camUV1,i.camUV2,i.camUV3,i.camUV4,i.camUV5,i.camUV6};
				bool isInside[6];
				fixed numInsides = 0;

				for (int c = 0; c < _NumCams; c++)
				{
					isInside[c] = camUV[c].x >= 0 && camUV[c].y >= 0 && camUV[c].x <= 1 && camUV[c].y <= 1;
					//borders[c] = (camUV[c].x - _Dist < 0 || camUV[c].y - _Dist < 0 || camUV[c].x + _Dist > 1 || camUV[c].y + _Dist > 1);
					if (isInside[c])
					{
						numInsides++;
					}
				}
				
				//bool isOutsideCam1 = (i.camUV1.x < 0 || i.camUV1.y < 0 || i.camUV1.x > 1 || i.camUV1.y > 1);
				//bool isOutsideCam2 = (i.camUV2.x < 0 || i.camUV2.y < 0 || i.camUV2.x > 1 || i.camUV2.y > 1);
				
				//bool isCam1Border = (i.camUV1.x - _Dist < 0 || i.camUV1.y - _Dist < 0 || i.camUV1.x + _Dist > 1 || i.camUV1.y + _Dist > 1);
				//bool isCam2Border = (i.camUV2.x - _Dist < 0 || i.camUV2.y - _Dist < 0 || i.camUV2.x + _Dist > 1 || i.camUV2.y + _Dist > 1);


				if (numInsides == 0)
				{
					return fixed4(0, 0, 0, .3f);
				/*} else if (isOutsideCam1)
				{
					return fixed4(0, 1, 0, 1);
				} else if (isOutsideCam2)
				{
					return fixed4(1, 0, 0, 1);
				*/
				}else
				{
					
					if (_TargetCam > 0 && !isInside[_TargetCam - 1]) return fixed4(0, 0, 0, .5);

					float camDists[6];
					fixed4 cols[6];
					float totalDist = 0;
					
					for (float c = 0; c < _NumCams; c++)
					{
						cols[c] = fixed4(fmod((c + 1)*1.2, 1), fmod((c + 1)*1.5, 1), fmod((c + 1)*1.7, 1), 1);
						if (isInside[c]) 
						{
							float2 d = 1 - abs(camUV[c].xy - .5)*abs(camUV[c].xy - .5) * 4;
							camDists[c] = d.x*d.y;
							totalDist += camDists[c];
						} else
						{
							camDists[c] = 0;
						}
					}

					fixed4 col = fixed4(0, 0, 0, 1);
					float weights[6];
					float totalWeight = 0;

					for (int c2 = 0; c2 < _NumCams; c2++)
					{
						float p = camDists[c2] / totalDist;

						//Fading for smoother/harder transition
						const float PI = 3.14159;
						p = p * 2 * PI;
						p += _Fade*sin(p);
						p = p / (2 * PI);
						p = min(max(p, 0), 1);

						//adjust exposition
						p += _Expo*(.25 - (p - .5)*(p - .5));
						totalWeight += p;
						weights[c2] = p;
					}
					for (c2 = 0; c2 < _NumCams; c2++)
					{
						float p = weights[c2] / totalWeight;
						if (totalWeight == 0) p = 1 + _Expo*.25 / _NumCams;
						if (isInside[c2])
						{
							col += cols[c2] * p;
						}
						
						if(floor(_TargetCam) == c2+1) return fixed4(p, p, p, 1);
					}

					col.a = 1;
					return col;
				}
			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
