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

void VolumetricRendering_float(UnityTexture2D _mainTex, float2 uv, float3 camForward, float3 cameraPositionWS, out float4 col){
    col = tex2D(_mainTex, uv);
    float3 rayOrigin = cameraPositionWS;
    
    //float3 forwardCam = UNITY_MATRIX_IT_MV[2].xyz;
    //float3 forward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
    float3 forward = UNITY_MATRIX_IT_MV[2].xyz;
    forward = normalize(forward);
    float forwardDistance = 0.49;//(0.5625 / tan(radians(60)));
    float3 right = normalize(cross(float3(0,1,0), forward));
    float3 up = normalize(cross(forward, right));

    float2 uvOffset = uv - 0.5;

    float3 viewDirection = forward * forwardDistance + right * uvOffset.x + up * uvOffset.y;
    float3 rayDir = normalize(viewDirection);

    float3 boundsMin = float3(-0.5,0,-0.5);
    float3 boundsMax = float3(0.5,2,0.5);
    float2 rayInfo = rayBoxDst(boundsMin, boundsMax, rayOrigin, rayDir);

    bool rayHitBox = rayInfo.y > 0;
    if(rayHitBox){
        col = 1;
    }
}