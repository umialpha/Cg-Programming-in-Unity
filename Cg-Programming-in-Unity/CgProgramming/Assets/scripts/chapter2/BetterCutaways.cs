using UnityEngine;
using System.Collections;

public class BetterCutaways : MonoBehaviour {
    public Transform obj;
	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        var renderer = GetComponent<Renderer>();
        GetComponent<Renderer>().sharedMaterial.SetMatrix("_Matrix", obj.GetComponent<Renderer>().localToWorldMatrix.inverse);
       
    }
}
