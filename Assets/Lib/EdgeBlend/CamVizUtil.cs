using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CamVizUtil : MonoBehaviour {

    public Camera[] cams; 

    public bool showAllCams;
    bool _showAllCams;

    [Range(1,10)]
    public int columns;
    int _columns;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		if(_showAllCams != showAllCams || columns != _columns)
        {
            _showAllCams = showAllCams;
            _columns = columns;

            Rect r = new Rect(0, 0, 1, 1);
            int rows = (int)Mathf.Ceil(cams.Length*1.0f / columns);
            float rowStep = 1.0f / rows;
            float columnStep = 1.0f / columns;
            Debug.Log(rows + "/" + rowStep + "/" + columnStep);
            for(int i=0;i<cams.Length;i++)
            {
                if (_showAllCams)
                {
                    cams[i].rect = new Rect((i % columns) * columnStep, 1-rowStep- Mathf.Floor(i * 1.0f / columns) * rowStep, columnStep,rowStep);
                } else
                {
                    cams[i].rect = r;
                }
            }
        }

	}
}
