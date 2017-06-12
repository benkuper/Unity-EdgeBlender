// This script should be attached to a Camera object 
// in Unity. Once a Plane object is specified as the 
// "projectionScreen", the script computes a suitable
// view and projection matrix for the camera.
// The code is based on Robert Kooima's publication  
// "Generalized Perspective Projection," 2009, 
// http://csc.lsu.edu/~kooima/pdfs/gen-perspective.pdf 

// Use the following line to apply the script in the editor:
@script ExecuteInEditMode()

#pragma strict


public var projectionScreen : GameObject;
public var screenWidth : float;
public var screenHeight : float;

public var estimateViewFrustum : boolean = true;
public var setNearClipPlane : boolean = false;
public var nearClipDistanceOffset : float = -0.01;

private var cameraComponent : Camera;

function LateUpdate() {
    cameraComponent = GetComponent(Camera);
    if (null != projectionScreen && null != cameraComponent)
    {
        var pa : Vector3 =  
           projectionScreen.transform.TransformPoint(
           Vector3(-screenWidth/2, -screenHeight/2, 0.0));
        // lower left corner in world coordinates
        var pb : Vector3 = 
           projectionScreen.transform.TransformPoint(
           Vector3(screenWidth/2, -screenHeight/2, 0.0));
        // lower right corner
        var pc : Vector3 = 
           projectionScreen.transform.TransformPoint(
           Vector3(-screenWidth/2,  screenHeight/2,0));
        // upper left corner
        var pe : Vector3 = transform.position;
        // eye position
        var n : float = cameraComponent.nearClipPlane;
        // distance of near clipping plane
        var f : float = cameraComponent.farClipPlane;
        // distance of far clipping plane

        var va : Vector3; // from pe to pa
        var vb : Vector3; // from pe to pb
        var vc : Vector3; // from pe to pc
        var vr : Vector3; // right axis of screen
        var vu : Vector3; // up axis of screen
        var vn : Vector3; // normal vector of screen
		
        var l : float; // distance to left screen edge
        var r : float; // distance to right screen edge
        var b : float; // distance to bottom screen edge
        var t : float; // distance to top screen edge
        var d : float; // distance from eye to screen 

        vr = pb - pa;
        vu = pc - pa;
        va = pa - pe;
        vb = pb - pe;
        vc = pc - pe;

        // are we looking at the backface of the plane object?
        if (Vector3.Dot(-Vector3.Cross(va, vc), vb) < 0.0)
        {
            // mirror points along the z axis (most users 
            // probably expect the x axis to stay fixed)
            vu = -vu;
            pa = pc;
            pb = pa + vr;
            pc = pa + vu;
            va = pa - pe;
            vb = pb - pe;
            vc = pc - pe;
        }

        vr.Normalize();
        vu.Normalize();
        vn = -Vector3.Cross(vr, vu); 
        // we need the minus sign because Unity 
        // uses a left-handed coordinate system
        vn.Normalize();
			
        d = -Vector3.Dot(va, vn);
        if (setNearClipPlane)
        {
            n = d + nearClipDistanceOffset;
            cameraComponent.nearClipPlane = n;
        }
        l = Vector3.Dot(vr, va) * n / d;
        r = Vector3.Dot(vr, vb) * n / d;
        b = Vector3.Dot(vu, va) * n / d;
        t = Vector3.Dot(vu, vc) * n / d;

        var p : Matrix4x4; // projection matrix 
        p[0,0] = 2.0*n/(r-l); 
        p[0,1] = 0.0; 
        p[0,2] = (r+l)/(r-l); 
        p[0,3] = 0.0;

        p[1,0] = 0.0; 
        p[1,1] = 2.0*n/(t-b); 
        p[1,2] = (t+b)/(t-b); 
        p[1,3] = 0.0;

        p[2,0] = 0.0;         
        p[2,1] = 0.0; 
        p[2,2] = (f+n)/(n-f); 
        p[2,3] = 2.0*f*n/(n-f);

        p[3,0] = 0.0;         
        p[3,1] = 0.0; 
        p[3,2] = -1.0;        
        p[3,3] = 0.0;		

        var rm : Matrix4x4; // rotation matrix;
        rm[0,0] = vr.x; 
        rm[0,1] = vr.y; 
        rm[0,2] = vr.z; 
        rm[0,3] = 0.0;	
	
        rm[1,0] = vu.x; 
        rm[1,1] = vu.y; 
        rm[1,2] = vu.z; 
        rm[1,3] = 0.0;	
	
        rm[2,0] = vn.x; 
        rm[2,1] = vn.y; 
        rm[2,2] = vn.z; 
        rm[2,3] = 0.0;	
	
        rm[3,0] = 0.0;  
        rm[3,1] = 0.0;  
        rm[3,2] = 0.0;  
        rm[3,3] = 1.0;		

        var tm : Matrix4x4; // translation matrix;
        tm[0,0] = 1.0; 
        tm[0,1] = 0.0; 
        tm[0,2] = 0.0; 
        tm[0,3] = -pe.x;	
	
        tm[1,0] = 0.0; 
        tm[1,1] = 1.0; 
        tm[1,2] = 0.0; 
        tm[1,3] = -pe.y;	
	
        tm[2,0] = 0.0; 
        tm[2,1] = 0.0; 
        tm[2,2] = 1.0; 
        tm[2,3] = -pe.z;	
	
        tm[3,0] = 0.0; 
        tm[3,1] = 0.0; 
        tm[3,2] = 0.0; 
        tm[3,3] = 1.0;		

        // set matrices
        cameraComponent.projectionMatrix = p;
        cameraComponent.worldToCameraMatrix = rm * tm; 
        // The original paper puts everything into the projection 
        // matrix (i.e. sets it to p * rm * tm and the other 
        // matrix to the identity), but this doesn't appear to 
        // work with Unity's shadow maps.

        if (estimateViewFrustum)
        {
            // rotate camera to screen for culling to work
            var q : Quaternion;
            q.SetLookRotation((0.5 * (pb + pc) - pe), vu); 
            // look at center of screen
            cameraComponent.transform.rotation = q;

            // set fieldOfView to a conservative estimate 
            // to make frustum tall enough
            if (cameraComponent.aspect >= 1.0)
            { 
                cameraComponent.fieldOfView = Mathf.Rad2Deg * 
                   Mathf.Atan(((pb-pa).magnitude + (pc-pa).magnitude) 
                   / va.magnitude);
            }
            else 
            {
                // take the camera aspect into account to 
                // make the frustum wide enough 
                cameraComponent.fieldOfView = 
                   Mathf.Rad2Deg / cameraComponent.aspect *
                   Mathf.Atan(((pb-pa).magnitude + (pc-pa).magnitude) 
                   / va.magnitude);
            }	
        }
    }
}