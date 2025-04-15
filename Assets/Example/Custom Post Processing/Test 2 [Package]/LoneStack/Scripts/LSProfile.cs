using System;
using UnityEngine;
using System.Linq;
using System.Collections.Generic;

namespace LoneStack
{
    [CreateAssetMenu(fileName = "StackProfile", menuName = "LoneStack/StackProfile")]
    [Serializable]
    public class LSProfile : ScriptableObject
    {
        [SerializeField]
        LoneStackEffectBlueprint[] blueprints = new LoneStackEffectBlueprint[0];

        public IEnumerable<LSEffect> InstantiateBlueprints() => blueprints.Select(bp => bp.Instantiate());
    }
}