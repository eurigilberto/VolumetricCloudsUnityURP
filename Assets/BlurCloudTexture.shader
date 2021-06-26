Shader "Unlit/BlurCloudTexture"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

        [Header(BoxFilter Filter Params)]
        _HSize("HSize", Float) = 0.001
        _VSize("VSize", Float) = 0.001
        _SampleTimes("Sample Times", Int) = 20
        _OffsetScale("Offset Scale", Range(0,2)) = 1
        _BlurInterp("Blur Intensity", Range(0,1)) = 1
        _BoxSize("Box Size", Range(2, 10)) = 5
        [Toggle(_USE_UNBLURED_ALPHA)] _use_unblur_alpha("Use Unblured Alpha", Float) = 0
        _AlphaCutout("Alpha cutour", Range(0,1)) = 0

        [Header(Kawahara Filter Params)]
        _WindowSize("Window Size", Range(1,10)) = 1
        _MultiplyOffset("OffsetMultiplier", Range(0, 3))=1

        [Toggle(_USE_KAWAHARA)] _use_kawahara("Use Kwahara", Float) = 0
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
            #pragma shader_feature _USE_KAWAHARA

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;

            float _HSize;
            float _VSize;

            int _SampleTimes;
            float _OffsetScale;
            float _BlurInterp;
            float _BoxSize;
            float _AlphaCutout;

            float _WindowSize;
            float _MultiplyOffset;
            float2 _ImageSize;

            //#define CLOUD_RIVER

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 boxBlur(float2 uv, sampler2D textureSampler){
                float2 moveSize = float2(1/_ImageSize.x, 1/_ImageSize.y);

                float4 color = float4(0,0,0,0);
                float sampleCount = 0;
                float _unevenBoxSize = floor(_BoxSize)%2 == 0 ? floor(_BoxSize) + 1 : floor(_BoxSize);

                [loop]
                for(int i = -floor(_unevenBoxSize/2.0); i < floor(_unevenBoxSize/2.0); i++){
                    [loop]
                    for(int j = -floor(_unevenBoxSize/2.0); j < floor(_unevenBoxSize/2.0); j++){
                        float2 uvOffset = float2(i * moveSize.x, j * moveSize.y) * _OffsetScale * _BlurInterp;
                        float2 blurUv = uv + uvOffset;
                        color += tex2D(textureSampler, blurUv);
                        sampleCount += 1;
                    }   
                }

                color /= sampleCount;
                return color;
            }

            float4 regionAverage(float2 moveSize, float2 xRegion, float2 yRegion, float2 uv, sampler2D texSampler){
                float4 acumulator = float4(0,0,0,0);
                float itterations = 0;
                for(int i = xRegion.x; i <= xRegion.y; i++){
                    for(int j = yRegion.x; j <= yRegion.y; j++){
                        float2 uvOffset = float2(float(i) * moveSize.x, float(j) * moveSize.y);
                        float2 newUv = uv + uvOffset * _MultiplyOffset;
                        acumulator += tex2D(texSampler, newUv);
                        itterations++;
                    }
                }
                return acumulator / itterations;
            }

            float4 regionStandardDeviation(float2 moveSize, float2 xRegion, float2 yRegion, float2 uv, sampler2D texSampler, float4 average){
                float4 acumulator = float4(0,0,0,0);
                float itterations = 0;
                for(int i = xRegion.x; i <= xRegion.y; i++){
                    for(int j = yRegion.x; j <= yRegion.y; j++){
                        float2 uvOffset = float2(i * moveSize.x, j * moveSize.y);
                        float2 newUv = uv + uvOffset * _MultiplyOffset;
                        acumulator += pow(tex2D(texSampler, newUv) - average, float4(2,2,2,2));
                        itterations++;
                    }
                }
                return acumulator / itterations;
            }

            int4 SelectAverages(float4x4 deviations){
                //This is going to select in which region the minimun deviation is found for each rgba value individualy
                //The values in the minDeviationLocation represent the regions in wich the minimun deviation for the r value is found and so on
                int4 minDeviationRegion = int4(0,0,0,0);
                
                for(int j = 0; j < 4; j++){    
                    for(int i = 1; i < 4; i++){
                        if(deviations[i][j] < deviations[minDeviationRegion[j]][j]){
                            minDeviationRegion[j] = i;
                        }
                    }
                }

                return minDeviationRegion;
            }

            float4 KawaharaFilter(float2 uv, sampler2D texSampler){
                float2 moveSize = float2(1/_ImageSize.x, 1/_ImageSize.y);
                float4x4 averages;
                float4x4 deviations;

                //region1
                float2 r1X = float2(0, _WindowSize);
                float2 r1Y = float2(0, _WindowSize);
                averages[0] = regionAverage(            moveSize, r1X, r1Y, uv, texSampler);
                deviations[0] = regionStandardDeviation(  moveSize, r1X, r1Y, uv, texSampler, averages[0]);

                //region2
                float2 r2X = float2(-_WindowSize, 0);
                float2 r2Y = float2(0, _WindowSize);
                averages[1] = regionAverage(            moveSize, r2X, r2Y, uv, texSampler);
                deviations[1] = regionStandardDeviation(  moveSize, r2X, r2Y, uv, texSampler, averages[1]);

                //region3
                float2 r3X = float2(-_WindowSize, 0);
                float2 r3Y = float2(-_WindowSize, 0);
                averages[2] = regionAverage(            moveSize, r3X, r3Y, uv, texSampler);
                deviations[2] = regionStandardDeviation(  moveSize, r3X, r3Y, uv, texSampler, averages[2]);

                //region4
                float2 r4X = float2(0, _WindowSize);
                float2 r4Y = float2(-_WindowSize, 0);
                averages[3] = regionAverage(            moveSize, r4X, r4Y, uv, texSampler);
                deviations[3] = regionStandardDeviation(  moveSize, r4X, r4Y, uv, texSampler, averages[3]);

                int4 selectedAverages = SelectAverages(deviations);

                float4 result = float4(0,0,0,0);
                for(int j = 0; j < 4; j++){
                    result[j] = averages[selectedAverages[j]][j];
                }

                return result;
            }

            float4 frag(v2f i) : SV_Target
            {
                #ifdef _USE_KAWAHARA
                    return KawaharaFilter(i.uv, _MainTex);
                #else
                    return boxBlur(i.uv, _MainTex);
                #endif
            }
            ENDHLSL
            //ENDCG
        }
    }
}
