Shader "Unlit/UnlitShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _CloudTex("Cloud Texture", 3D) = "white" {}
        
        _CloudOffset("Cloud Offset Texture", 2D) = "white" {}
        _CloudOffsetMult("Cloud offset multiplier", float) = 0.0

        _SecondSampleOffset("Second Sample Offset", vector) = (0,0,0)
        
        _DensityMul("Density Multiplier", float) = 0.01
        
        _InvLerpAB("InvLerpAB", vector) = (0.1,1,1,1)
        
        _TimeMul("Time Multiplier", float) = 1.0

        _ScaleOffsetMain("Scale Offset Main", vector) = (1,1,1,0)
        _ScaleVec("Scale vector 1", vector) = (1,1,1,1)

        _DetailMultiplier("Detail Multiplier", float) = 0.1

        _DensityExpMultiplier("Density Exponential Multiplier", float) = 4
        _ScatteringConstant("Scattering Constant", float) = 1
        _BeerMultiplier("Beer Multiplier", float) = 1
        _PowderMultiplier("Powder Multiplier", float) = 1
        _HenyenLawIntensity("HenyenLawIntensity", float) = 1

        _BrightColor("Bright Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,0)

        _SideLinearMultiplier("Side Linear Multiplier", vector) = (1,1,1,1)
        _TopInvLerpVal("Top Inverse Lerp Value", float) = 1

        _InvLerpMaxSides("Inverse Lerp Max Sides", float) = 1
        _TaperValues("Taper Values", vector) = (1,1,1,1)
        _GroundCutOffpoint("Ground Cutoff Point", float) = 1

        _GroundBrightColor("Bright Color", Color) = (1,1,1,1)
        _GroundShadowColor("Shadow Color", Color) = (0,0,0,0)

        _MainStepCount("Main Step Count", Range(40, 128)) = 50
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            sampler3D _CloudTex;
            sampler2D _CameraDepthTexture;
            sampler2D _CloudOffset;

            float _CloudOffsetMult;

            float3 _SecondSampleOffset;

            float4 _MainTex_ST;
            float3 _volumeBoundsMin;
            float3 _volumeBoundsMax;

            float _DetailMultiplier;

            float _DensityMul;
            float2 _InvLerpAB;
            float3 _ScaleOffsetMain;
            float3 _ScaleVec;
            float _TimeMul;
            float _ScatteringConstant;
            float _BeerMultiplier;

            float _DensityExpMultiplier;

            float3 _BrightColor;
            float3 _ShadowColor;

            float3 _GroundBrightColor;
            float3 _GroundShadowColor;

            float _InvLerpMaxSides;
            float2 _TaperValues;
            float4 _SideLinearMultiplier;
            float _PowderMultiplier;

            float _HenyenLawIntensity;
            float _TopInvLerpVal;
            float _GroundCutOffpoint;

            float _MainStepCount;

            //#define CLOUD_RIVER

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir)
            {
                float3 t0 = (boundsMin - rayOrigin) / rayDir;
                float3 t1 = (boundsMax - rayOrigin) / rayDir;

                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0,dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float sdfSphere(float3 pos, float3 center, float innerRadius, float outerRadius){
                float fromCenter = length(pos - center);
                //float rawClampedDistance = min(max(fromCenter, innerRadius), outerRadius) - innerRadius;
                //float nClampedDistance = 1 - (rawClampedDistance / (outerRadius - innerRadius));
                //return nClampedDistance;

                return fromCenter - innerRadius;
            }

            float opSmoothUnion( float d1, float d2, float k )
            {
                float h = max(k-abs(d1-d2),0.0);
                return min(d1, d2) - h*h*0.25/k;
            }

            float invLerp(float from, float to, float value) {
                return (value - from) / (to - from);
            }

            float textureMainSample(float3 p){
                float3 movementOffset = float3(_Time.y * _TimeMul, 0, 0);
                float3 scaledPoint = p/(_ScaleOffsetMain.xyz * _ScaleVec.x) + movementOffset; //+ cloudOffset;
                return tex3Dlod(_CloudTex, float4(scaledPoint, 0));
            }

            float sampleWaterHeight(float3 p){
                float cloudTexOffset = tex2D(_CloudOffset, p.xz / _ScaleVec.z);
                return cloudTexOffset;
            }


            //Cloud river
            float sceneDensity(float3 p, bool addDetail){
            #ifndef CLOUD_RIVER
                
                float densityMainPoint = textureMainSample(p);
                float densityMainPointOffset = textureMainSample(p + _SecondSampleOffset);

                float3 scaled2Point = p / _ScaleVec.y;

                float densityDetailPoint = addDetail? tex3Dlod(_CloudTex, float4(scaled2Point, 0)) : 0;

                float mainDensity = clamp(densityMainPoint + densityMainPointOffset, 0, 1.2);

                float densityMaskY = smoothstep(0.2, 0.5, abs((p.y - _volumeBoundsMin.y)/(_volumeBoundsMax.y - _volumeBoundsMin.y) - 0.5));
                float densityMaskX = smoothstep(0.4, 0.5, abs((p.x - _volumeBoundsMin.x)/(_volumeBoundsMax.x - _volumeBoundsMin.x) - 0.5));
                float densityMaskZ = smoothstep(0.4, 0.5, abs((p.z - _volumeBoundsMin.z)/(_volumeBoundsMax.z - _volumeBoundsMin.z) - 0.5));
                float densityMask = saturate(densityMaskX + densityMaskY + densityMaskZ);

                float densityPoint = saturate(invLerp(_InvLerpAB.x, _InvLerpAB.y, (mainDensity + densityMask  + densityDetailPoint * _DetailMultiplier)));
                
                return densityPoint * _DensityMul;

            #else

                float densityMainPoint = textureMainSample(p);
                float densityMainPointOffset = textureMainSample(p + _SecondSampleOffset);

                float3 scaled2Point = ((p / _ScaleVec.y) * float3(0.25,1,1)) + float3(0, 0, sin((_Time.y * 0.5 + p.x/ _ScaleVec.y) * -4) * 0.25);
                float densityDetailPoint = tex3D(_CloudTex, scaled2Point);

                float mainDensity = clamp(densityMainPoint + densityMainPointOffset, 0, 1.2);

                float linearYSide2 = clamp(invLerp(_volumeBoundsMax.y, _volumeBoundsMin.y, p.y), 0, 1);
                float yInvLerp = clamp(invLerp(1, _TopInvLerpVal, linearYSide2), 0, 1);

                float topMask = step(_TopInvLerpVal, linearYSide2);

                float taperLerpCloudOffset = tex2D(_CloudOffset, p.xz / _ScaleVec.z + float2(_Time.y * - 0.075, 0));
                float taperThing = lerp(_TaperValues.x, _TaperValues.y, taperLerpCloudOffset);

                float topTaperLerp = invLerp(0, taperThing /*_InvLerpMaxSides*/, linearYSide2);

                float taperMaxValue = sampleWaterHeight(p);

                float taperValues = lerp(1, taperMaxValue, sin((topTaperLerp * 3.14) / 2));

                float yLerpMul = lerp(taperValues, 1, topMask); //clamp(linearYSide2 * _TopInvLerpVal, 0, 1);
                float mainDensityMultiplied = yLerpMul * mainDensity;

                float densityPoint = saturate(invLerp(_InvLerpAB.x, _InvLerpAB.y, (mainDensityMultiplied + densityDetailPoint * _DetailMultiplier)));

                float linearXSide = abs(clamp(invLerp(_volumeBoundsMin.x, _volumeBoundsMax.x, p.x), 0, 1) - 0.5) * 2;
                float xLerpWeight = saturate((1 - linearXSide) * _SideLinearMultiplier.x);
                xLerpWeight = pow(xLerpWeight, _SideLinearMultiplier.w);

                /*float linearYSide = clamp(invLerp(_volumeBoundsMin.y, _volumeBoundsMax.y, p.y), 0, 1);
                float yLerpWeight = clamp(invLerp(0, _SideLinearMultiplier.y, linearYSide), 0, 1) * clamp(invLerp(1, _SideLinearMultiplier.w, linearYSide), 0, 1);*/

                float linearYSide = abs(clamp(invLerp(_volumeBoundsMin.y, _volumeBoundsMax.y, p.y), 0, 1) - 0.5) * 2;
                float yLerpWeight = saturate((1 - linearYSide) * _SideLinearMultiplier.y);
                yLerpWeight = pow(yLerpWeight, _SideLinearMultiplier.w);

                float linearZSide = abs(clamp(invLerp(_volumeBoundsMin.z, _volumeBoundsMax.z, p.z), 0, 1) - 0.5) * 2;
                float zLerpWeight = saturate((1 - linearZSide) * _SideLinearMultiplier.z);
                zLerpWeight = pow(zLerpWeight, _SideLinearMultiplier.w);

                return densityPoint * _DensityMul * xLerpWeight * zLerpWeight * yLerpWeight;
            #endif
            }

            float hg(float angle) {
                float g2 = _ScatteringConstant*_ScatteringConstant;
                return (1-g2) / (4*3.1415*pow(1+g2-2*_ScatteringConstant*(angle), 1.5));
            }

            float densityTowardsSun(float3 p, float currentDensity){
                float3 rayOrigin = p;

                float3 lightDirection = _WorldSpaceLightPos0.xyz;
                float3 dirTowardsSun = lightDirection;
                float2 rayInfo = rayBoxDst(_volumeBoundsMin, _volumeBoundsMax, rayOrigin, dirTowardsSun);
                
                bool rayHitBox = rayInfo.y > 0;

                float density = currentDensity;

                if(rayHitBox){
                    float currentDistance = rayInfo.x;
                    int maxSteps = 8;/*20*/

                    for (int i = 0; i < maxSteps ; i++)
                    {
                        currentDistance += clamp(rayInfo.y / maxSteps, 0.05, 100);

                        float3 pointCheck = rayOrigin + dirTowardsSun * currentDistance;

                        float densityPoint = sceneDensity(pointCheck, false);

                        density += densityPoint;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 texColor = tex2D(_MainTex, i.uv);
                float depth = tex2D(_CameraDepthTexture, i.uv).r;
                fixed4 col = texColor;

                
                //dstToBox

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);
                float2 rayInfo = rayBoxDst(_volumeBoundsMin, _volumeBoundsMax, rayOrigin, rayDir);

                float eyeDepth = LinearEyeDepth(depth);
                if(eyeDepth > rayInfo.x){
                    bool rayHitBox = rayInfo.y > 0;

                    if(rayHitBox){
                        float densityOverCameraRay = 0;
                        float lightEnergy = 0;

                        float lightIntensity = 1;
                        float currentDistance = rayInfo.x;
                        float solidDepth = 0;

                        int stepCount = round(_MainStepCount);
                        [loop]
                        for (int i = 0; i < stepCount; i++)
                        {
                            float3 pointCheck = rayOrigin + mul(rayDir, currentDistance);
                            float pointDensity = sceneDensity(pointCheck, true);
                            densityOverCameraRay += pointDensity;

                            if(pointDensity > 0 && lightEnergy < 0.95){
                                float densityToSun = densityTowardsSun(pointCheck, pointDensity);
                                float beerLaw = exp(- densityToSun * _BeerMultiplier);

                                float3 lightDirection = _WorldSpaceLightPos0.xyz;
                                float angleLightView = dot(rayDir, lightDirection);

                                float henyenLaw = hg(angleLightView);

                                float powderLaw = 1 - exp(- densityToSun * 2 * _PowderMultiplier);
                                float transmitance = (clamp(invLerp(exp(-1), 1, exp(-densityOverCameraRay * _DensityExpMultiplier)), 0, 1));

                                lightEnergy += transmitance * beerLaw * powderLaw + pointDensity * henyenLaw * _HenyenLawIntensity;//transmitance * pointDensity;
                            }

                            //If the alpha increase then this is the depth of the current cloud point
                            if (densityOverCameraRay > 0) {
                                if (solidDepth == 0) {
                                    solidDepth = currentDistance;
                                }
                            }

                            //Break if it is already solid
                            if (densityOverCameraRay >= 1) {
                                densityOverCameraRay = saturate(densityOverCameraRay);
                                break;
                            }

                            //Break if it is outside the boox
                            if (currentDistance > rayInfo.x + rayInfo.y) {
                                break;
                            }

                            currentDistance += clamp(rayInfo.y / stepCount, 0.05, 100);
                        }

                        densityOverCameraRay = clamp(invLerp(exp(-1), 1, exp(-densityOverCameraRay * _DensityExpMultiplier)), 0, 1);
                        lightIntensity = clamp(lightEnergy, 0, 1);

                        float3 cloudColor = lerp(_ShadowColor, _BrightColor, lightIntensity);
                        float3 groundColor = lerp(_GroundShadowColor, _GroundBrightColor, lightIntensity);

                        float3 pixelPoint = rayOrigin + mul(rayDir, solidDepth);

                        float3 cOut = cloudColor; //lerp(cloudColor, groundColor, clamp(invLerp(_GroundCutOffpoint, _GroundCutOffpoint + 2, pixelPoint.y), 0, 1));


                        if(eyeDepth > solidDepth){
                            col = lerp(float4(cOut, 1), texColor, densityOverCameraRay);
                        }else{
                            col = texColor;
                        }
                        
                        //col = alpha;
                    }
                }
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
