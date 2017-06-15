using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamBlendRender : MonoBehaviour {

    public EdgeBlend edgeBlend;
    Camera cam;

	// Use this for initialization
	void Start () {
        cam = GetComponent<Camera>();
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    void OnPreRender()
    {
        edgeBlend.setTargetCam(cam);
    }

    private void OnPostRender()
    {
        edgeBlend.setTargetCam(null);
    }
}
