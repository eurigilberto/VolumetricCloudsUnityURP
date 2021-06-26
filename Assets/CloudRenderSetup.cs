using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class CloudRenderSetup : MonoBehaviour
{
    public Material cloudRenderer;
    public Material combineCloudToScene;
    public ForwardRendererData renderData;
    private void OnEnable()
    {
        var renderFeatures = renderData.rendererFeatures;
        var volumeRenderer = (VolumetricRendering)renderFeatures[0];
        volumeRenderer.settings.cloudRenderer = cloudRenderer;
        volumeRenderer.Create();
        //Debug.Log("Called");
    }

    private void OnValidate()
    {
        var renderFeatures = renderData.rendererFeatures;
        var volumeRenderer = (VolumetricRendering)renderFeatures[0];
        volumeRenderer.settings.cloudRenderer = cloudRenderer;
        volumeRenderer.Create();
        //Debug.Log("Called");
    }
}
