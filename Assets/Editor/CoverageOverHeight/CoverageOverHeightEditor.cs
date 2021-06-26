using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(CoverageOverHeight))]
public class CoverageOverHeightEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Create Coverage Texture")) 
        {
            Debug.Log("Coverage over height begins");
            var heightCoverage = (target as CoverageOverHeight).CreateCoverageTexture();
            AssetDatabase.CreateAsset(heightCoverage, "Assets/CoverageOverHeight.asset");
            Debug.Log("CREATED");
        }
    }
}
