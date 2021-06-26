using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class FloatingCube : MonoBehaviour
{
    public Vector3 floatingCenter;
    public float floatSpeed = 0.5f;
    public float floatingAmplitude = 20;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float offset = Mathf.Sin(Time.time * floatSpeed) * floatingAmplitude;
        transform.position = floatingCenter + Vector3.up * offset;
    }
}
