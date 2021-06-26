Shader "Unlit/CombineCloudTexture"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            //CGPROGRAM
            HLSLPROGRAM

            #pragma target 3.5
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature _USE_UNBLURED_ALPHA

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _CloudTex;

            //#define CLOUD_RIVER

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            /*float4 boxBlur(float2 uv, sampler2D textureSampler){
                float4 color = float4(0,0,0,0);
                float sampleCount = 0;
                float _unevenBoxSize = floor(_BoxSize)%2 == 0 ? floor(_BoxSize) + 1 : floor(_BoxSize);

                [loop]
                for(int i = -floor(_unevenBoxSize/2.0); i < floor(_unevenBoxSize/2.0); i++){
                    [loop]
                    for(int j = -floor(_unevenBoxSize/2.0); j < floor(_unevenBoxSize/2.0); j++){
                        float2 uvOffset = float2(i * _HSize, j * _VSize) * _OffsetScale * _BlurInterp;
                        float2 blurUv = uv + uvOffset;
                        color += tex2D(textureSampler, blurUv);
                        sampleCount += 1;
                    }   
                }

                color /= sampleCount;
                return color;
            }*/

            float4 frag(v2f i) : SV_Target
            {
                float4 cloudSample = tex2D(_CloudTex, i.uv);
                float4 sceneColor = tex2D(_MainTex, i.uv);
                
                float3 outColor = lerp(sceneColor.rgb, cloudSample.rgb, cloudSample.a);

                return float4(outColor, 1);
            }
            ENDHLSL
            //ENDCG
        }
    }
}
