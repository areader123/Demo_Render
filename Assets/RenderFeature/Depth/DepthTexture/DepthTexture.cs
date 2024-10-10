using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthTexture : PostEffectsBase
{


   private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, material);
    }

    
}
