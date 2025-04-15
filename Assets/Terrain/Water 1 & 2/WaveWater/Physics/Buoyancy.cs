using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Buoyancy : MonoBehaviour
{
    public float �� = 1;
    public float g = 9.81f;
    public float SeaLevel = 3;

    private void OnTriggerStay(Collider collision)
    {
        if (collision != null)
        {
            collision.attachedRigidbody.velocity =
                new Vector3(Mathf.Lerp(collision.attachedRigidbody.velocity.x, 0, 0.005f),
                            Mathf.Lerp(collision.attachedRigidbody.velocity.y, 0, 0.01f),
                            Mathf.Lerp(collision.attachedRigidbody.velocity.z, 0, 0.005f));

            float Depth = SeaLevel - collision.transform.position.y + collision.bounds.extents.y;
            float LengthBesideWater = Mathf.Clamp(Depth, 0, collision.bounds.size.y);
            float V = collision.bounds.size.x * LengthBesideWater * collision.bounds.size.z;
            collision.attachedRigidbody.AddForce(new Vector3(0, �� * g * V, 0), ForceMode.Force);
            //print(collision.name+" ���:"+ Depth + " ˮ�²��ָ߶�:" + LengthBesideWater + " ˮ�²������:" + V + " ����:" + �� * g * V);
        }
    }
}
