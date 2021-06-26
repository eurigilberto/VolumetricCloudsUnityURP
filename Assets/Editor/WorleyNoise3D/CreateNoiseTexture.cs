using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

[ExecuteAlways]
public class CreateNoiseTexture : MonoBehaviour
{
    const int cellCount = 8; //It is a cube (the same count for width, height, and depth). Should be a power of 2
    int cellSize = 0;

    private int WrapCellAxis(int axisVal)
    {
        return axisVal >= 0 ? axisVal % cellCount : axisVal + cellCount;
    }

    private Vector3Int WrapCellPosition(Vector3Int cellPosition)
    {
        Vector3Int newCellPosition = Vector3Int.zero;
        newCellPosition.x = WrapCellAxis(cellPosition.x);
        newCellPosition.y = WrapCellAxis(cellPosition.y);
        newCellPosition.z = WrapCellAxis(cellPosition.z);
        return newCellPosition;
    }

    private int CellPositionToIndex(Vector3Int cellPosition)
    {
        return cellPosition.x + cellPosition.y * cellCount + cellPosition.z * cellCount * cellCount;
    }

    private int distanceToClosest(Vector3Int position, Vector3Int[] points)
    {
        int smallestDistance = 2 * cellSize;
        for (int i = 0; i < points.Length; i++)
        {
            int distance = Mathf.FloorToInt((position - points[i]).magnitude);
            if(distance < smallestDistance)
            {
                smallestDistance = distance;
            }
        }
        return smallestDistance;
    }

    public void CreateNoise()
    {
        int textureSize = 64;
        TextureFormat textureFormat = TextureFormat.R8;
        TextureWrapMode wrapMode = TextureWrapMode.Repeat;

        Texture3D texture = new Texture3D(textureSize, textureSize, textureSize, textureFormat, false);
        texture.wrapMode = wrapMode;

        Vector3Int[] cellPoints = new Vector3Int[cellCount * cellCount * cellCount];
        cellSize = textureSize / cellCount;
        for (int i = 0; i < cellPoints.Length; i++)
        {
            Vector3Int newCellPoint = Vector3Int.zero;
            newCellPoint.x = Mathf.FloorToInt(UnityEngine.Random.value * cellSize);
            newCellPoint.y = Mathf.FloorToInt(UnityEngine.Random.value * cellSize);
            newCellPoint.z = Mathf.FloorToInt(UnityEngine.Random.value * cellSize);
            cellPoints[i] = newCellPoint;
        }

        for (int i = 0; i < textureSize; i++)
        {
            for (int j = 0; j < textureSize; j++)
            {
                for (int k = 0; k < textureSize; k++)
                {
                    Vector3Int textureTexel = new Vector3Int(i, j, k);
                    
                    Vector3Int cellPosition = new Vector3Int(
                        Mathf.FloorToInt((float)textureTexel.x / (float)cellSize), 
                        Mathf.FloorToInt((float)textureTexel.y / (float)cellSize), 
                        Mathf.FloorToInt((float)textureTexel.z / (float)cellSize)
                    );

                    Vector3Int[] cellComparisonPoints = new Vector3Int[27];
                    for (int ni = 0; ni < 3; ni++)
                    {
                        for (int nj = 0; nj < 3; nj++)
                        {
                            for (int nk = 0; nk < 3; nk++)
                            {
                                Vector3Int positionOffset = new Vector3Int(ni - 1, nj - 1, nk - 1);
                                int comparisonPointsIndex = ni + nj * 3 + nk * 3 * 3;
                                Vector3Int cellPositionOffseted = cellPosition + positionOffset;
                                Vector3Int cellPositionWrapped = WrapCellPosition(cellPositionOffseted);
                                int cellPointIndex = CellPositionToIndex(cellPositionWrapped);
                                Vector3Int cellPoint = cellPoints[cellPointIndex];
                                cellComparisonPoints[comparisonPointsIndex] = (cellPositionOffseted * cellSize) + cellPoint;
                            }
                        }
                    }

                    int distToClosest = distanceToClosest(textureTexel, cellComparisonPoints);
                    float clampMax = (float)cellSize;
                    float distToClosestNormalized = (Mathf.Clamp(distToClosest, 0, clampMax))/ clampMax;
                    texture.SetPixel(textureTexel.x, textureTexel.y, textureTexel.z, new Color(distToClosestNormalized, distToClosestNormalized, distToClosestNormalized));
                }
            }
        }
        texture.Apply();
        AssetDatabase.CreateAsset(texture, "Assets/Cloud3dTexture.asset");

        //noiseTexture.SetPixel(0, 0, 0, Color.white);
    }

}
