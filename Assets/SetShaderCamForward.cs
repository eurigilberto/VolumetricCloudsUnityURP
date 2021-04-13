using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SetShaderCamForward : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        //Debug.Log(gameObject.transform.forward);
        Shader.SetGlobalVector("_camForward", gameObject.transform.forward);
    }
}
