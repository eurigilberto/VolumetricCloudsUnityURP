#ifndef CUSTOM_SPECULAR
#define CUSTOM_SPECULAR

float anisotropicSpecular(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity){
    float3 L = lightDir;
    float3 V = viewDir;

    float3 H = normalize(L+V);
    float dotTH = dot(normal, H);
    float sinTH = sqrt(1.0 - dotTH * dotTH);
    float dirAtten = smoothstep(-1, 0, dotTH);
    return dirAtten * pow(sinTH, specularPower) * specularIntensity;
}

float specular(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity, float3 offsetVector){
    normal *= offsetVector;
    normal = normalize(normal);
    // Calculate the reflection vector: 
    float3 R = normalize(2 * dot(normal, -lightDir) * normal + lightDir); 
    // Calculate the speculate component: 
    float s = pow(saturate(dot(R, normalize(viewDir))), specularPower) * specularIntensity;
    return s;
}

void SpecularShaderGraph_float(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity, out float s){
    s = specular(lightDir, normal, viewDir, specularPower, specularIntensity, float3(0,0,0));
}

#endif