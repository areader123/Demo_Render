using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace LoneStack
{
    [RequireComponent(typeof(Camera))]
    [DisallowMultipleComponent]
    public sealed class LSLayer : MonoBehaviour
    {
        [SerializeField]
        LayerMask volumeLayers = 0;
        [Tooltip("What will determine the distance to a volume for effect blending. (This camera's position if null)")]
        public Transform volumeTrigger = null;
        public LayerMask VolumeLayers => volumeLayers; 
    }

    public static class LoneStackFromCam
    {
        public static bool EnqueueLoneStackBuffer(this Camera cam, CommandBuffer buffer, LSContext context, ref RenderingData renderingData)
        {
            LSLayer lsl = cam.GetComponent<LSLayer>();
            if (!lsl) return false;
            LoneStackFeature.volumesBuffer.Clear();
            LSVolume.SelectVolumes(vol => ((1 << vol.gameObject.layer) & lsl.VolumeLayers) != 0, LoneStackFeature.volumesBuffer);
            if (LoneStackFeature.volumesBuffer.Count == 0) return false;
            context.volumeTrigger = lsl.volumeTrigger ? lsl.volumeTrigger.position : cam.transform.position;
            bool hasWritten = false;
            foreach (LSVolume vol in LoneStackFeature.volumesBuffer)
                hasWritten |= vol.EnqueueToBuffer(buffer, context, ref renderingData);
            return hasWritten;
        }
    }
}