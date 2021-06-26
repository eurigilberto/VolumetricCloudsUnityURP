using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricRendering : ScriptableRendererFeature
{
    class CloudShadowRenderPass : ScriptableRenderPass
    {
        private Material cloudRenderer;
        private int materialPassIndex;
        private RenderTargetHandle cloudShadowTexture;

        public CloudShadowRenderPass(Material cloudRenderer, int materialPassIndex) : base()
        {
            this.materialPassIndex = materialPassIndex;
            this.cloudRenderer = cloudRenderer;
            cloudShadowTexture.Init("_TempCloudShadowTexture");
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RenderCloudShadow");

            RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDesc.depthBufferBits = 0;

            cmd.GetTemporaryRT(cloudShadowTexture.id, Mathf.RoundToInt((float)cameraTextureDesc.width / 1.0f), Mathf.RoundToInt((float)cameraTextureDesc.height / 1.0f), 0, FilterMode.Bilinear);

            cmd.EnableShaderKeyword("_SHADOW_PASS");
            Blit(cmd, cloudShadowTexture.Identifier(), cloudShadowTexture.Identifier(), cloudRenderer, this.materialPassIndex);
            cmd.SetGlobalTexture("_ShadowPassTexture", cloudShadowTexture.Identifier());

            //Execute and release commands
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //Release any temporary textures
            cmd.ReleaseTemporaryRT(cloudShadowTexture.id);
        }
    }

    class CloudsPass : ScriptableRenderPass
    {
        private Material cloudRenderer;
        private Material denoiseMaterial;
        private Material combineTextureMaterial;
        private int materialPassIndex;
        private RenderTargetIdentifier _source;
        public RenderTargetIdentifier source
        {
            set
            {
                _source = value;
            }
        }
        private RenderTargetHandle cloudTexture;
        private RenderTargetHandle denoisedCloudTexture;
        private RenderTargetHandle sourceCopy;

        public CloudsPass(Material cloudRenderer, int materialPassIndex, Material combineTextureMat, Material denoiseMaterial) : base()
        {
            this.materialPassIndex = materialPassIndex;
            this.cloudRenderer = cloudRenderer;
            this.denoiseMaterial = denoiseMaterial;
            this.combineTextureMaterial = combineTextureMat;
            cloudTexture.Init("_TempVolumetricTexture");
            denoisedCloudTexture.Init("_TempDenoisedCloudTexture");
            sourceCopy.Init("_TempSourceCopy");
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("RenderClouds");

            RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDesc.depthBufferBits = 0;

            int width = Mathf.RoundToInt((float)cameraTextureDesc.width / 2.0f);
            int height = Mathf.RoundToInt((float)cameraTextureDesc.height / 2.0f);

            cmd.GetTemporaryRT(cloudTexture.id, width, height, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(denoisedCloudTexture.id, width, height, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(sourceCopy.id, cameraTextureDesc, FilterMode.Bilinear);

            cmd.DisableShaderKeyword("_SHADOW_PASS");
            Blit(cmd, _source, cloudTexture.Identifier(), cloudRenderer, this.materialPassIndex);
            cmd.SetGlobalVector("_ImageSize", new Vector4(width, height, 0, 0));
            
            Blit(cmd, cloudTexture.Identifier(), denoisedCloudTexture.Identifier(), denoiseMaterial, this.materialPassIndex);
            //Blit(cmd, denoisedCloudTexture.Identifier(), cloudTexture.Identifier(), denoiseMaterial, this.materialPassIndex);
            //Blit(cmd, cloudTexture.Identifier(), denoisedCloudTexture.Identifier(), denoiseMaterial, this.materialPassIndex);
            //Blit(cmd, denoisedCloudTexture.Identifier(), cloudTexture.Identifier(), denoiseMaterial, this.materialPassIndex);
            
            cmd.SetGlobalTexture("_CloudTex", denoisedCloudTexture.Identifier());

            Blit(cmd, _source, sourceCopy.Identifier(), combineTextureMaterial, this.materialPassIndex);
            Blit(cmd, sourceCopy.Identifier(), _source);

            //Execute and release commands
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //Release any temporary textures
            cmd.ReleaseTemporaryRT(cloudTexture.id);
            cmd.ReleaseTemporaryRT(sourceCopy.id);
        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material cloudRenderer;
        public Material denoiseMaterial;
        public Material combineTexture;
        public int materialPassIndex = -1;
    }

    [SerializeField]
    public Settings settings = new Settings();

    CloudShadowRenderPass cloudShadowRenderPass;
    CloudsPass cloudsPass;

    /// <inheritdoc/>
    public override void Create()
    {
        cloudShadowRenderPass = new CloudShadowRenderPass(settings.cloudRenderer, settings.materialPassIndex);
        cloudsPass = new CloudsPass(settings.cloudRenderer, settings.materialPassIndex, settings.combineTexture, settings.denoiseMaterial);

        // Configures where the render pass should be injected.
        cloudShadowRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
        cloudsPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        cloudsPass.source = renderer.cameraColorTarget;
        renderer.EnqueuePass(cloudShadowRenderPass);
        renderer.EnqueuePass(cloudsPass);
    }
}


