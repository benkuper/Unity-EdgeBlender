using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class EdgeBlend : MonoBehaviour {

    public Camera[] cams;
    public Matrix4x4[] matrices;

    Material mat;

	// Use this for initialization
	void Start () {
        mat = GetComponent<Renderer>().sharedMaterial;
        matrices = new Matrix4x4[cams.Length];
	}
	
	// Update is called once per frame
	void Update () {
        for(int i=0;i<cams.Length;i++)
        {
            bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1; 
            Matrix4x4 M = transform.localToWorldMatrix;
            Matrix4x4 V = cams[i].worldToCameraMatrix;
            Matrix4x4 P = cams[i].projectionMatrix;

            
            if (d3d)
            {
                // Invert Y for rendering to a render texture
                for (int j = 0; j < 4; j++)
                {
                    P[1, j] = -P[1, j];
                }
                // Scale and bias from OpenGL -> D3D depth range
                for (int j = 0; j < 4; j++)
                {
                    P[2, j] = P[2,j] * 0.5f + P[3, j] * 0.5f;
                }
            }
            
            if(i >= matrices.Length)
                matrices = new Matrix4x4[cams.Length];

            matrices[i] = P * V * M; 
            
            mat.SetMatrix("_Cam" + (i+1) + "Matrix", matrices[i]);
        }
        
    }

    private void OnDrawGizmos()
    {
        int i = 0;
        foreach (Camera c in cams)
        {
            //Gizmos.matrix = Matrix4x4.TRS(c.transform.position, c.transform.rotation, new Vector3(1.0f, 1.0f, 1.0f));
            //Gizmos.DrawFrustum(Vector3.zero, c.fieldOfView, c.farClipPlane, c.nearClipPlane, c.aspect);
            i++;
        }
    }
}
