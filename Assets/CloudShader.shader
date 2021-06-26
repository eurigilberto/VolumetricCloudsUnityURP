Shader "PosProcess/CloudShader"
{
    Properties
    {
        _CoverageTex("Coverage/Type Texture", 2D) = "white" {}
        _CloudTex("Cloud Texture", 3D) = "white" {}
        _CoverageOverHeightTex("Coverage Over Height Texture", 2D) = "white" {}
        
        _DensityMin("Density Min Inv Lerp", float) = -1.0
        _SecondSampleOffset("Second Sample Offset", vector) = (0,0,0)
        
        [Header(Cloud Movement)]
        _TimeMul("MovementSpeed", Range(0, 0.2)) = 0.02
        _SpeedMultipliers("Speed Multipliers", Vector) = (1,1,1,1)

        [Header(Cloud Shaping)]
        _RegionLimits("Region Limits", Vector) = (1,1,1,1)
        _ScaleOffsetMain("Primary Scale", Vector) = (1,1,1,0)
        _ScaleOffsetSecondary("Secondary Scale", Vector) = (1,1,1,0)
        _ScaleMultipliers("Scale Multipliers", Vector) = (1,1,1,1)
        _DetailMultiplier("Detail Multiplier", float) = 0.1
        _InvLerpCoverage("InvLerp Coverage Params", Vector) = (0.1,1,1,1)
        _HeightTypeInvLerp("Height Type Inverse Lerp", Vector) = (0,1,0,1)
        _MainDensityInvLerpCoverage("Main Density InvLerp Coverage", Vector) = (1,1,1,1)
        [Space]
        _MainStepCount("Main Step Count", Range(40, 512)) = 50
        _IncreaseStepSizeTransition("Increase Step Size Transition", Vector) = (0,100,0,0)
        _CloudDistance("Cloud Distance", Float) = 100
        _DepthBias("Depth Bias", Float) = 0
        [Space]
        _BendingMult("Bending Multiplier", Range(-2, 2)) = 0
        _BendDistanceMult("Bending Distance Multiplier", Range(0, 5))=1
        [Space]
        _DensityMul("Density Multiplier", Range(0,20)) = 0.01

        [Header(Cloud Lighting)]
        _DensityExpMultiplier("Density Exponential Multiplier", Range(0, 30)) = 4
        _BeerMultiplier("Beer Multiplier", float) = 1
        _PowderMultiplier("Powder Multiplier", float) = 1
        _BeerPowderMultiplier("Beer-Powder Multiplier", Range(0,10)) = 1
        _HenyenLawIntensity("HenyenLawIntensity", float) = 1
        _ScatteringConstant("Scattering Constant", Range(0.2,0.99)) = 1
        [Space]
        _BrightColor("Bright Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,0)
        [Space]
        _DensityTowardsSunSteps("DensityTowardsSunSteps", Range(0,100)) = 20
        _MultiplyDensityToSun("Density to Sun Multiplier", Range(0,10)) = 1
        

        [Header(Cloud Noise)]
        _NoiseScale("Noise Scale", Range(0, 1000)) = 2
        _NoiseIntensity("Noise Interpolator", Range(0,1)) = 1
        _NoiseDisplacement("Noise Displacement", Range(0,100)) = 0
        
        [Header(Shadow)]
        _SceneShadowSteps("Shadow Steps", Range(0,20)) = 20
        _MultiplyCloudDensity("Step Density Multiply", Range(0,10)) = 1
        _ScreenShadowColor("Screen Shadow Color", Color) = (1,1,1,1)
        _ScreenShadowOpacity("Shadow Opacity", Range(0,1)) = 0.5
        _ScreenShadowNoiseDisplacement("Shadow Noise Displacement", Range(0,1)) = 0.1
        _ShadowDistance("Shadow Distance", Range(1, 2000)) = 500

        [Toggle(_HARD_SHADOW)] _enable_hard_shadow("Hard Shadow", Float) = 0
        _ShadowCutoffPoint("Hard Shadow Cutoff", Range(0,1)) = 1
    }
    SubShader
    {
        LOD 100

        Pass
        {
            //CGPROGRAM
            HLSLPROGRAM

            #pragma target 3.5
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog

            #pragma shader_feature _HARD_SHADOW
            #pragma multi_compile _ _SHADOW_PASS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#include "UnityCG.cginc"

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
                float3 viewVector : TEXCOORD1;
            };
            sampler2D _CoverageTex;
            sampler2D _CoverageOverHeightTex;
            sampler3D _CloudTex;
            sampler2D _CameraDepthTexture;

            float _DensityMin;

            float3 _SecondSampleOffset;

            float3 _volumeBoundsMin;
            float3 _volumeBoundsMax;

            float _DetailMultiplier;

            float _DensityMul;
            float4 _InvLerpCoverage;
            float4 _HeightTypeInvLerp;
            float2 _MainDensityInvLerpCoverage;
            float3 _ScaleOffsetMain;
            float3 _ScaleOffsetSecondary;
            float3 _ScaleMultipliers;
            float4 _SpeedMultipliers;
            float _TimeMul;
            float _ScatteringConstant;
            float _BeerMultiplier;

            float _DensityExpMultiplier;
            float _BendingMult;
            float _BendDistanceMult;
            float _CloudDistance;

            float3 _BrightColor;
            float3 _ShadowColor;

            float _PowderMultiplier;
            float _BeerPowderMultiplier;

            float _HenyenLawIntensity;

            float _MainStepCount;
            float _DensityTowardsSunSteps;

            float _NoiseScale;
            float _NoiseIntensity;
            float _NoiseDisplacement;

            float3 _mainLightDirection;
            float _MultiplyDensityToSun;

            float _SceneShadowSteps;
            float _MultiplyCloudDensity;
            float4 _ScreenShadowColor;
            float _ScreenShadowOpacity;
            float _ScreenShadowNoiseDisplacement;
            float _ShadowCutoffPoint;
            float _ShadowDistance;
            float _DepthBias;

            float4 _IncreaseStepSizeTransition;

            struct CloudLight{
                float3 direction;
                float distanceAttenuation;
                float maxTravelDistance;
                float3 color;
            };

            CloudLight GetLightData(float3 positionWS){
                CloudLight lightData;
                
                /* This was for a point light test
                float3 lightPosition = _AdditionalLightsPosition[0].xyz;
                float3 posToLight = lightPosition - positionWS;
                float4 distanceAttenuation = _AdditionalLightsAttenuation[0];
                
                float distance = length(posToLight);
                float distanceSqr = dot(posToLight,posToLight);
                float distanceFalloff = unity_LightData.z;// distanceAttenuation.w/10;
                float smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);

                lightData.direction = normalize(lightPosition - positionWS);
                lightData.distanceAttenuation = distanceFalloff;
                lightData.maxTravelDistance = distance;
                lightData.color = _AdditionalLightsColor[0].rgb;*/

                lightData.direction = _MainLightPosition.xyz;
                lightData.distanceAttenuation = 1;
                lightData.maxTravelDistance = 100000000;
                lightData.color = float3(1,1,1);

                return lightData;
            }

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            {//This function was taken from unity's documentation
                float2 dir = unity_gradientNoise_dir(UV * Scale);
                Out = frac(dir.x + dir.y);
                //Out = unity_gradientNoise(UV * Scale) + 0.5;
            }

            //#define CLOUD_RIVER

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir)
            {
                float3 t0 = (boundsMin - rayOrigin) / rayDir;
                float3 t1 = (boundsMax - rayOrigin) / rayDir;

                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0.0,dstA);
                float dstInsideBox = max(0.0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float invLerp(float from, float to, float value) {
                float top = value - from;
                float down = to - from;
                return top / down;
            }

            float textureMainSample(float3 p, float speedMultiplier, float3 scaleVec, float scaleMultiplier, sampler3D samp){
                float3 movementOffset = float3(_Time.y * _TimeMul * speedMultiplier, 0, 0);
                float3 scale = scaleVec * scaleMultiplier;
                float3 scaledPoint = p/(scale) + movementOffset;
                return tex3D(samp, scaledPoint);
            }

            float3 depthToWorldPos(float depth, float3 viewDir){
                return _WorldSpaceCameraPos + viewDir * depth;
            }

            //Cloud river
            float sceneDensity(float3 p, bool addDetail){
                float3 scaled2Point = 0;
                float densityDetailPoint = 0;
                float3 densityMasks = float3(0,0,0);
                float densityMask = 0;
                float mainDensity = 0;
                float2 mainDensityValues = float2(0,0);
                float mainDensityAndMask = 0;

                float height = invLerp(_volumeBoundsMin.y, _volumeBoundsMax.y, p.y);

                float coverageHeightMult = 1;

                //p.xz / _ScaleMultipliers.x
                float2 coverageUV1 = float2(0,0);
                float2 coverageUV2 = float2(0,0);
                float2 heightTypeUV = float2(0,0);

                float2 regionUV = float2(0,0);

                float coverage1 = 0;
                float coverage2 = 0;
                float heightType = 0;

                float4 heightTypes = float4(0,0,0,0);

                float fullCoverage = 0;

                //float4 coverageTypeTex = float4(0,0,0,0);

                regionUV.x = saturate(invLerp(_volumeBoundsMin.x, _volumeBoundsMax.x, p.x));
                regionUV.y = saturate(invLerp(_volumeBoundsMin.z, _volumeBoundsMax.z, p.z));

                float circleMask = smoothstep(1,0.8, length((regionUV - float2(0.5,0.5)) * 2));

                if(circleMask > 0){
                    coverageUV1 = regionUV;
                    coverageUV1.x += _Time.y * _SpeedMultipliers.x;

                    coverageUV2 = regionUV + _SecondSampleOffset;
                    coverageUV2.x -= _Time.y * _SpeedMultipliers.x;

                    heightTypeUV = regionUV;

                    float2 coverAndHeight = tex2D(_CoverageTex, coverageUV1).xy;

                    coverage1 = coverAndHeight.x * circleMask;//tex2D(_CoverageTex, coverageUV1).x * circleMask;
                    coverage2 = tex2D(_CoverageTex, coverageUV2).z * circleMask;
                    fullCoverage = saturate(invLerp(_InvLerpCoverage.z, _InvLerpCoverage.w, coverage1 + coverage2));

                    if(fullCoverage > 0){
                        heightType = coverAndHeight.y;//tex2D(_CoverageTex, heightTypeUV).y;
                        heightTypes = tex2D(_CoverageOverHeightTex, float2(0, height));
                        
                        float heightCoverageType = saturate(smoothstep(_HeightTypeInvLerp.x, _HeightTypeInvLerp.y, heightType));
                        coverageHeightMult = lerp(heightTypes.x, heightTypes.y, 1 - heightCoverageType);
                        
                        float movementOffset = _Time.y * _TimeMul * _SpeedMultipliers.z;
                        scaled2Point = p /(float3(1,0.5,1) * _ScaleMultipliers.y) + float3(movementOffset, 0,0);
                        densityDetailPoint = tex3D(_CloudTex, scaled2Point);
                    }
                }

                float mainCoverage = fullCoverage * coverageHeightMult;
                mainCoverage = saturate(invLerp(_MainDensityInvLerpCoverage.x, _MainDensityInvLerpCoverage.y, mainCoverage));
                float densityPoint = max(0, mainCoverage - densityDetailPoint * _DetailMultiplier);
                
                
                /*densityMasks.x = smoothstep(0.25, 0.5, abs((p.x - _volumeBoundsMin.x)/(_volumeBoundsMax.x - _volumeBoundsMin.x) - 0.5));
                densityMasks.y = smoothstep(0.2, 0.5, abs((p.y - _volumeBoundsMin.y)/(_volumeBoundsMax.y - _volumeBoundsMin.y) - 0.5));
                densityMasks.z = smoothstep(0.25, 0.5, abs((p.z - _volumeBoundsMin.z)/(_volumeBoundsMax.z - _volumeBoundsMin.z) - 0.5));

                densityMask = saturate(densityMasks.x + densityMasks.y + densityMasks.z);

                if(densityMask < _InvLerpCoverage.x){
                    float3 s1p = p;
                    mainDensityValues.x = textureMainSample(s1p, _SpeedMultipliers.x, _ScaleOffsetMain.xyz,      _ScaleMultipliers.x, _CloudTex);
                    float3 s2p = p + _SecondSampleOffset;
                    mainDensityValues.y = textureMainSample(s2p, _SpeedMultipliers.y, _ScaleOffsetSecondary.xyz, _ScaleMultipliers.z, _CloudTex);

                    mainDensity = mainDensityValues.x + mainDensityValues.y;
                    mainDensityAndMask = mainDensity + densityMask;

                    if(mainDensityAndMask < _InvLerpCoverage.x){
                        scaled2Point = p /(float3(1,1,1) * _ScaleMultipliers.y) + float3(_Time.y * _TimeMul * _SpeedMultipliers.z, 0, 0);
                        densityDetailPoint = tex3D(_CloudTex, scaled2Point);//addDetail? tex3D(_CloudTex, scaled2Point) : 0;
                    }
                }

                float densityPoint = saturate(invLerp(_InvLerpCoverage.x, _InvLerpCoverage.y, (mainDensity + densityMask + densityDetailPoint * _DetailMultiplier)));*/
                
                return densityPoint * _DensityMul;
            }

            float hg(float angle) {
                float g = _ScatteringConstant;
                float g2 = g*g;
                return (1-g2) / (4*3.1415*pow(1+g2-2*g*(angle), 1.5));
            }

            float densityTowardsSun(float3 p, bool detail){
                float3 rayOrigin = p;

                float3 lightDirection = GetLightData(p).direction;
                float3 dirTowardsSun = lightDirection;
                float2 rayInfo = rayBoxDst(_volumeBoundsMin, _volumeBoundsMax, rayOrigin, dirTowardsSun);
                
                bool rayHitBox = rayInfo.y > 0;

                float density = 0;

                if(rayHitBox){
                    float currentDistance = rayInfo.x;
                    int maxSteps = floor(_DensityTowardsSunSteps);
                    
                    //float maxRayLength = length(_volumeBoundsMax - _volumeBoundsMin);
                    float stepSize = rayInfo.y / maxSteps;//maxRayLength / maxSteps;

                    [loop]
                    for (int i = 0; i < maxSteps ; i++)
                    {
                        currentDistance += stepSize;
                        float3 pointCheck = rayOrigin + dirTowardsSun * currentDistance;

                        float densityPoint = sceneDensity(pointCheck, detail);

                        density += densityPoint * _MultiplyDensityToSun;

                        if (density >= 1) {
                            density = 1;
                            break;
                        }

                        //Break if it is outside the boox
                        if (currentDistance > rayInfo.x + rayInfo.y) {
                            break;
                        }
                    }
                }

                return density;
            }

            float4 UnityObjectToClipPos(float3 pos){
                return mul(UNITY_MATRIX_MVP, float4(pos, 1.0));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                //The following calculation from the view vector was taken from Sebastian Cloud implementation https://github.com/SebLague/Clouds
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));

                return o;
            }

            float linearToEyeDepth(float z , float3 viewVector){
                float divisor = _ZBufferParams.z * z + _ZBufferParams.w;
                float depth = 1.0/(divisor);
                depth *= length(viewVector);
                return depth;
            }

            float startPositionDither(float2 uv){
                //The pattern is from http://www.alexandre-pestana.com/volumetric-lights/
                float4x4 ditherPattern = { 0.0f, 0.5f, 0.125f, 0.625f,
                                                0.75f, 0.22f, 0.875f, 0.375f,
                                                0.1875f, 0.6875f, 0.0625f, 0.5625,
                                                0.9375f, 0.4375f, 0.8125f, 0.3125};

                return ditherPattern[(uv.x * 1280) % 4][(uv.y * 720) % 4];
            }

            float4 frag (v2f i) : SV_Target
            {   
                float depth = tex2D(_CameraDepthTexture, i.uv).r;
                float2 UV = i.uv;

                float eyeDepth = linearToEyeDepth(depth, i.viewVector.xyz);

                /*
                This shader is used to create the shadows and to render the clouds, when _SHADOW_PASS is not defined then it renders the clouds
                when defined it renders the shadow.
                */
                #ifndef _SHADOW_PASS

                float4 col = float4(0,0,0,0);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);
                float2 rayInfo = rayBoxDst(_volumeBoundsMin, _volumeBoundsMax, rayOrigin, rayDir);
                float densityOverCameraRay = 0;
                float randomJitter;
                //float randomJitter2;
                //float ditheringOffset = (1 + startPositionDither(UV * _NoiseScale) * _NoiseDisplacement * _NoiseIntensity);

                int stepCount = round(_MainStepCount);
                //float stepSize = rayInfo.y / stepCount;
                //float maxRayLength = length(_volumeBoundsMax - _volumeBoundsMin);
                float maxRayLength = _CloudDistance;
                float stepSize = maxRayLength / stepCount;
                float stepsTaken = 0;

                if(eyeDepth > rayInfo.x){
                    bool rayHitBox = rayInfo.y > 0;

                    if(rayHitBox){
                        float lightEnergy = 0;

                        float lightIntensity = 1;
                        
                        float3 pointCheck;
                        float3 bentPointCheck;
                        float pointDensity;

                        float angleLightView = dot(rayDir, GetLightData(pointCheck).direction);
                        float henyeyLaw = hg(angleLightView);

                        //rayDir.xy
                        Unity_GradientNoise_float(UV, _NoiseScale, randomJitter);
                        float displacementNoise = ((randomJitter - 0.5) / 0.5) * _NoiseDisplacement * _NoiseIntensity;
                        float stepSizeMultInterpolator = 0;

                        float currentDistance = rayInfo.x + displacementNoise;

                        [loop]
                        for (int i = 0; i < stepCount; i++)
                        {
                            stepsTaken = i;
                            pointCheck = rayOrigin + mul(rayDir, currentDistance);//This is a world space position
                            
                            float2 pointPlane = (mul(rayDir, currentDistance)).xz;
                            float yOffset = (dot(pointPlane, pointPlane) * _BendDistanceMult / 1000) * (_BendingMult);
                            bentPointCheck = pointCheck + float3(0, yOffset, 0);

                            pointDensity = sceneDensity(bentPointCheck, true);

                            densityOverCameraRay += pointDensity;

                            if(pointDensity > 0 && lightEnergy < 0.9){
                                //stepSizeMultInterpolator < 0.8
                                float densityToSun = densityTowardsSun(bentPointCheck, true);

                                float expDensity = exp(-densityOverCameraRay * _DensityExpMultiplier);

                                float expDensityToSun = exp(-densityToSun * 2); //lerp(0.1,1,(1-densityToSun))
                                //This is used to shadow the cloud with it self, the idea is that as the density that the light has to pass through increases
                                //the amount of light that would be received by that point is reduced

                                

                                /*There is a problem with the shadow attenuation when using cascade 1, the value that is returned
                                when point to check position maps to a position outside of the shadow map, I am not entirely sure how to solve it yet.*/
                                float4 shadowCoord = TransformWorldToShadowCoord(pointCheck);
                                float shadowAttenuation = MainLightRealtimeShadow(shadowCoord);

                                //float beerLaw = exp(-densityToSun * _BeerMultiplier);
                                //float powderLaw = 1 - exp(-densityOverCameraRay * 2 * _PowderMultiplier);
                                //lightEnergy += beerLaw * powderLaw * lerp(0, 1, shadowAttenuation) * _BeerPowderMultiplier + max(0, (densityOverCameraRay * henyeyLaw * _HenyenLawIntensity) * shadowAttenuation);
                                //lightEnergy += beerLaw * powderLaw * lerp(0.05, 1, shadowAttenuation) * henyeyLaw * _BeerPowderMultiplier;
                                //lightEnergy += (lerp(0,0.5,beerLaw * powderLaw) + lerp(0,0.5,henyeyLaw * _HenyenLawIntensity)) * lerp(0.1, 1, shadowAttenuation) * _BeerPowderMultiplier;

                                float beerLaw = exp(-densityToSun * _BeerMultiplier);
                                float powderLaw = 1 - exp(-densityOverCameraRay * 2 * _PowderMultiplier);
                                //lightEnergy += beerLaw * powderLaw * lerp(0, 1, shadowAttenuation) * _BeerPowderMultiplier;
                                lightEnergy += beerLaw * powderLaw * lerp(0, 1, shadowAttenuation) * _BeerPowderMultiplier + max(0, (densityOverCameraRay * henyeyLaw * _HenyenLawIntensity) * shadowAttenuation);
                            }

                            //Break if it is already solid
                            if (densityOverCameraRay >= 1) {
                                densityOverCameraRay = saturate(densityOverCameraRay);
                                break;
                            }

                            //Break if it is outside the boox
                            //if (currentDistance > rayInfo.x + rayInfo.y || currentDistance > eyeDepth) {
                            //    break;
                            //}

                            if (currentDistance > eyeDepth + _DepthBias || currentDistance > rayInfo.x + rayInfo.y - 10) {
                                break;
                            }

                            stepSizeMultInterpolator = smoothstep(_IncreaseStepSizeTransition.x, _IncreaseStepSizeTransition.y, i);
                            //currentDistance += stepSize * (1 + displacementNoise) * lerp(1,2,stepSizeMultInterpolator);
                            currentDistance += stepSize * lerp(_IncreaseStepSizeTransition.z, _IncreaseStepSizeTransition.w, stepSizeMultInterpolator);
                            //currentDistance += stepSize * ditheringOffset;
                        }

                        densityOverCameraRay = clamp(invLerp(exp(_DensityMin), 1, exp(-densityOverCameraRay * 1)), 0, 1);
                        lightIntensity = clamp(lightEnergy, 0, 1);

                        float3 cloudColor = lerp(_ShadowColor, _BrightColor, lightIntensity);

                        float3 cOut = cloudColor; //(stepsTaken/_IncreaseStepSizeTransition.y);

                        float cloudAlpha = saturate(1 - densityOverCameraRay);
                        col = float4(cOut, cloudAlpha);
                    }
                }

                #else

                float4 col = float4(1,1,1,0);
                float3 worldSpacePosition = _WorldSpaceCameraPos + normalize(i.viewVector) * eyeDepth;

                float4 shadowCoord = TransformWorldToShadowCoord(worldSpacePosition);
                float shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
                CloudLight lightInfo = GetLightData(worldSpacePosition);

                float currentDensity = (1 - shadowAttenuation);
                //In this case I am using density as 1 - shadow attenuation, because a density of 1 would mean that no light can reach that point
                
                if(eyeDepth < _ShadowDistance){
                    float3 shadowRayOrigin = worldSpacePosition;

                    float3 lightDirection = lightInfo.direction;
                    float3 shadowRayDir = lightDirection;

                    float2 shadowRayInfo = rayBoxDst(_volumeBoundsMin, _volumeBoundsMax, shadowRayOrigin, shadowRayDir);
                    bool shadowRayHit = shadowRayInfo.y > 0;

                    if(shadowRayHit){
                        float currentDistance = shadowRayInfo.x;
                        int _SceneShadowStepsInt = floor(_SceneShadowSteps);
                        [loop]
                        for(int i = 0; i < _SceneShadowStepsInt; i++){
                            if(currentDistance > lightInfo.maxTravelDistance){
                                break;
                            }

                            float3 pointCheck = shadowRayOrigin + mul(shadowRayDir, currentDistance);
                            float pointDensity = sceneDensity(pointCheck, true);
                            
                            #ifndef _HARD_SHADOW
                                currentDensity += pointDensity * _MultiplyCloudDensity;
                            #else
                                currentDensity += pointDensity > _ShadowCutoffPoint? 1: 0;
                            #endif

                            if(currentDensity > 0.99){
                                break;
                            }

                            currentDistance += (shadowRayInfo.y / _SceneShadowSteps);
                        }
                        currentDensity = saturate(currentDensity);
                    }
                }
                float shadowOpacity = saturate(currentDensity);//saturate(currentDensity * _ScreenShadowOpacity);
                //col = float4(lerp(lightInfo.color,_ScreenShadowColor.rgb,shadowOpacity), shadowOpacity);
                //col = float4(_ScreenShadowColor.rgb, shadowOpacity);

                col = float4(lerp(float3(1,1,1),_ScreenShadowColor.rgb,_ScreenShadowOpacity), shadowOpacity);
                //col = float4(shadowOpacity, shadowOpacity, shadowOpacity, shadowOpacity);
                //col = float4(lerp(float3(1,1,1),lightInfo.distanceAttenuation,shadowOpacity), shadowOpacity);
                #endif
                return col;
            }
            ENDHLSL
            //ENDCG
        }
    }
}
