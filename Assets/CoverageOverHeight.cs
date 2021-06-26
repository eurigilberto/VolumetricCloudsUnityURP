using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CoverageOverHeight : MonoBehaviour
{
    public AnimationCurve heightCoverType1;
    public AnimationCurve heightCoverType2;
    public int samplesCount = 512;

    public Texture2D CreateCoverageTexture()
    {
        TextureFormat textureFormat = TextureFormat.RGBA32;
        TextureWrapMode wrapMode = TextureWrapMode.Repeat;
        
        Texture2D heightCoverage = new Texture2D(1, samplesCount, textureFormat, false);
        heightCoverage.wrapMode = wrapMode;
        heightCoverage.filterMode = FilterMode.Bilinear;

        for (int i = 0; i < samplesCount; i++)
        {
            float sampleTime = ((float)i / samplesCount);
            float type1Sample = heightCoverType1.Evaluate(sampleTime);
            float type2Sample = heightCoverType2.Evaluate(sampleTime);

            //Debug.Log("Sample 1 : " + type1Sample.ToString());
            //Debug.Log("Sample 2 : " + type2Sample.ToString());
            heightCoverage.SetPixel(1, i, new Color(type1Sample, type2Sample, 0, 0));
        }

        heightCoverage.Apply();

        return heightCoverage;
    }
}
