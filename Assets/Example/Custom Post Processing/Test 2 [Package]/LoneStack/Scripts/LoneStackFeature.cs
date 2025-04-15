using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace LoneStack
{
    /// <summary>
    /// LoneStack Context<br/>
    /// Used to know the source and destination texture.<br/>
    /// Make sure that the destination is the last thing you draw into.
    /// </summary>
    public class LSContext
    {
        public RenderTargetIdentifier source;
        public RenderTargetIdentifier destination;
        public RenderTextureDescriptor textureDescriptor;
        public Vector3 volumeTrigger;

        public LSContext(RenderTargetIdentifier src, RenderTargetIdentifier dst)
        {
            source = src;
            destination = dst;
        }

        public void SwapSrcDst()
        {
            var tmp = source;
            source = destination;
            destination = tmp;
        }
    }

    /// <summary>
    /// LoneStack RenderFeature<br/>
    /// That's the Feature you add in your RenderPipeline's Renderer's Renderer features.
    /// </summary>
    public class LoneStackFeature : ScriptableRendererFeature
    {
        public const string profilerTag = "LoneStack_cmdBuffer";

        public static readonly List<LSVolume> volumesBuffer = new List<LSVolume>();

        /// <summary>
        /// The FeaturePass<br/>
        /// Basically what is used to actually execute the feature.
        /// </summary>
        public class StackFeaturePass : ScriptableRenderPass
        {
            public enum RenderTarget
            {
                Color,
                RenderTexture,
            }

            public FilterMode filterMode { get; set; }

            RenderTargetIdentifier source = default;
            RenderTargetHandle destination = default;

            RenderTargetHandle temporaty_a = default;
            RenderTargetHandle temporaty_b = default;

            readonly LSContext lsContext = new LSContext(0, 0);

            public StackFeaturePass(RenderPassEvent renderPassEvent)
            {
                this.renderPassEvent = renderPassEvent;
                temporaty_a.Init("_LoneStack_Temporary_a");
                temporaty_b.Init("_LoneStack_Temporary_b");
            }

            public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
            {
                this.source = source;
                this.destination = destination;
            }

            /// <summary>
            /// -- THE EXECUTION --
            /// </summary>
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                // init execution
                volumesBuffer.Clear();
                CommandBuffer buffer = CommandBufferPool.Get(profilerTag);
                lsContext.textureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                lsContext.textureDescriptor.msaaSamples = 1; // oh my, this bad boy would have destroyed your framerate, we don't want an anti-aliasing event for every blit!
                lsContext.textureDescriptor.depthBufferBits = 0; // no need for depth for post processing Blit calls.
                lsContext.source = temporaty_a.Identifier();
                lsContext.destination = temporaty_b.Identifier();

                // init temporary targets
                buffer.GetTemporaryRT(temporaty_a.id, lsContext.textureDescriptor);
                buffer.GetTemporaryRT(temporaty_b.id, lsContext.textureDescriptor);

                buffer.Blit(source, lsContext.source);

                // Populating the command buffer [camera->volumes->profile->effects]
                if(renderingData.cameraData.isSceneViewCamera)
                {
                    volumesBuffer.Clear();
                    lsContext.volumeTrigger = renderingData.cameraData.camera.transform.position;
                    LSVolume.SelectVolumes(v => v.VisibleInSceneView, volumesBuffer);
                    foreach (var vol in volumesBuffer)
                        vol.EnqueueToBuffer(buffer, lsContext, ref renderingData);
                }
                else renderingData.cameraData.camera.EnqueueLoneStackBuffer(buffer, lsContext, ref renderingData);

                // Final blit
                if (destination == RenderTargetHandle.CameraTarget) buffer.Blit(lsContext.source, source);
                else buffer.Blit(lsContext.source, destination.Identifier());

                // release tempTargets
                buffer.ReleaseTemporaryRT(temporaty_a.id);
                buffer.ReleaseTemporaryRT(temporaty_b.id);

                // execute
                context.ExecuteCommandBuffer(buffer);
                CommandBufferPool.Release(buffer);
            }
        }

        [System.Serializable]
        public class StackFeatureSettings
        {
            public RenderPassEvent Event = RenderPassEvent.BeforeRenderingPostProcessing;
            public Target destination = Target.Color;
            public string textureId = "_LoneStackOutput";
        }

        public enum Target
        {
            Color,
            Texture
        }

        public StackFeatureSettings settings = new StackFeatureSettings();
        RenderTargetHandle m_RenderTextureHandle;

        StackFeaturePass blitPass;

        public override void Create()
        {
            blitPass = new StackFeaturePass(settings.Event);
            m_RenderTextureHandle.Init(settings.textureId);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var src = renderer.cameraColorTarget;
            var dest = (settings.destination == Target.Color) ? RenderTargetHandle.CameraTarget : m_RenderTextureHandle;

            blitPass.Setup(src, dest);
            renderer.EnqueuePass(blitPass);
        }
    }
}