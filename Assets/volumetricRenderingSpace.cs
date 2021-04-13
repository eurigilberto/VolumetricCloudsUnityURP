using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class volumetricRenderingSpace : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 boundsMin = transform.position - transform.localScale / 2;
        Vector3 boundsMax = transform.position + transform.localScale / 2;

        Shader.SetGlobalVector("_volumeBoundsMin", boundsMin);
        Shader.SetGlobalVector("_volumeBoundsMax", boundsMax);
    }
}
