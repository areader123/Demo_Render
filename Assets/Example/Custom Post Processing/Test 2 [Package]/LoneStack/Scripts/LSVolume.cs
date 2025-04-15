using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace LoneStack
{
    [ExecuteInEditMode]
    public class LSVolume : MonoBehaviour
    {
        readonly static List<LSVolume> activeVolumes = new List<LSVolume>();

        [SerializeField]
        LSProfile profile = null;
        public LSProfile Profile => profile;

        [SerializeField]
        bool visibleInSceneView = true;
        public bool VisibleInSceneView => visibleInSceneView;

        [SerializeField]
        [Tooltip("The lower, the earlier")]
        int order = 0;

        [SerializeField]
        [Tooltip("Is the effect affected by the distance of the camera to colliders? or is it global?")]
        bool isGlobal = true;
        [SerializeField]
        bool isGlobalInSceneView = false;

        [Range(0f, 1f)]
        public float blend = 1f;
        [Tooltip("When the volume isn't global, how far from the colliders should the trigger be to start blending effects?")]
        [Min(0)]
        public float blendDistance = 5f;

        Collider[] managedColliders;
        public Collider[] ManagedColliders => managedColliders;

        readonly List<LSEffect> effects = new List<LSEffect>();

        [SerializeField]
        bool changesToEffects = false;
        public bool ChangesToEffects => changesToEffects;

        ////////////////// ACCESSING EFFECTS //////////////////

        public List<LSEffect> Effects => effects;
        public T FindEffect<T>() where T : LSEffect
        {
            foreach (var e in effects) if (e is T) return e as T;
            return null;
        }
        public IEnumerable<T> FindEffects<T>() where T : LSEffect
            => effects.Where(e => e is T).Select(e => e as T);
        public LSEffect GetEffect(int id)
            => id >= 0 && id < effects.Count ? effects[id] : null;

        ////////////////// UTILITY //////////////////

        /// <summary>
        /// Resets the current effects list to match the profile's default.<br/>
        /// Of course, it will just clear the effects if there's no active profile.<br/>
        /// You will lose modifications made to these effects at runtime.
        /// </summary>
        public void ResetEffectList()
        {
            effects.Clear();
            if (profile)
                effects.AddRange(profile.InstantiateBlueprints());
            changesToEffects = false;
        }

        /// <summary>
        /// Changes this volume's profile.
        /// </summary>
        /// <param name="newProfile">new profile, can also be null, if you want.</param>
        /// <param name="resetEffects">Reset the volume's effects to match the new profile's default?</param>
        public void SetProfile(LSProfile newProfile, bool resetEffects = true)
        {
            profile = newProfile;
            if (resetEffects)
                ResetEffectList();
        }

        /// <summary>
        /// You can enqueue this volume's effects to pretty much any CommandBuffer. Neat!
        /// </summary>
        /// <returns>Has any instruction been enqueued?</returns>
        public bool EnqueueToBuffer(CommandBuffer buffer, LSContext context, ref RenderingData renderingData)
        {
            if (effects.Count == 0) return false;

            float currBlend = blend;
            if(!(isGlobal || isGlobalInSceneView && renderingData.cameraData.isSceneViewCamera))
            {
                // calculating blending based on distance to colliders
                float distToVolume = float.MaxValue;
                managedColliders = GetComponentsInChildren<Collider>();
                foreach (Collider c in managedColliders)
                {
                    if ((c is MeshCollider mc) && !mc.convex) continue;
                    distToVolume = Mathf.Min(distToVolume, Vector3.Distance(context.volumeTrigger, c.ClosestPoint(context.volumeTrigger)));
                }
                if (blendDistance != 0f) currBlend *= Mathf.Max(0f, 1f - distToVolume / blendDistance);
                else currBlend *= distToVolume == 0 ? 1f : 0f;
            }

            if (currBlend <= 0f) return false;

            foreach (LSEffect effect in effects)
            {
                if (!effect.Enabled) continue;
                effect.Blend = currBlend;
                effect.EnqueueToBuffer(buffer, context, ref renderingData);
                context.SwapSrcDst();
            }

            return true;
        }

        ////////////////// INTERNAL //////////////////

        private void OnEnable()
        {
            activeVolumes.Add(this);
        }

        private void OnDisable()
        {
            activeVolumes.Remove(this);
        }

        private void Awake()
        {
            ResetEffectList();
        }

        private void Update()
        {
            foreach (var effect in effects)
                effect.Update();
        }

        public static void SelectVolumes(System.Func<LSVolume, bool> selector, List<LSVolume> buffer)
        {
            foreach (LSVolume v in activeVolumes)
                if (selector(v))
                    buffer.Add(v);
            buffer.Sort((v0, v1) => v0.order - v1.order);
        }
    }
}