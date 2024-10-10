using System.ComponentModel.DataAnnotations;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Hit : MonoBehaviour
{
    public ParticleSystem ps;
    public float clicksPerSecond = 0.1f;
    public int  AffectorAmount = 20;
    public string triggerInfo = "ForceField";


    private float clickTime;
    private ParticleSystem.Particle[] particles;
    private Vector4[] positions;
    private float[] sizes;
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        clickTime += Time.deltaTime;
        if (Input.GetMouseButton(0))
        {
            if (clickTime > clicksPerSecond)
            {
                clickTime = 0f;
                DoRayCast();
            }
        }

        var psMain = ps.main;
        psMain.maxParticles =  AffectorAmount;
        particles = new ParticleSystem.Particle[ AffectorAmount];
        positions = new Vector4[ AffectorAmount];
        sizes = new float[ AffectorAmount];
        ps.GetParticles(particles);
        for (int i = 0; i <  AffectorAmount; i++)
        {
            positions[i] = particles[i].position;
            sizes[i] = particles[i].GetCurrentSize(ps);
        }
        Shader.SetGlobalVectorArray("HitPosition", positions);
        Shader.SetGlobalFloatArray("HitSize", sizes);
        Shader.SetGlobalFloat("AffectorAmount", AffectorAmount);

    }

    private void DoRayCast()
    {
        RaycastHit hit;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(ray, out hit, 1000))
        {
            if (hit.transform.CompareTag(triggerInfo))
            {
                ps.transform.position = hit.point;
                ps.Emit(1);
            }
        }
    }
}
