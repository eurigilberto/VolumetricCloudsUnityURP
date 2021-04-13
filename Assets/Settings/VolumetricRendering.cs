using UnityEditor.ShaderGraph.Drawing.Inspector.PropertyDrawers;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricRendering : ScriptableRendererFeature
{
    class VolumetricRenderPass : ScriptableRenderPass
    {
        private Material material;
        private int materialPassIndex;
        private RenderTargetIdentifier _source;
        public RenderTargetIdentifier source
        {
            set
            {
                _source = value;
            }
        }
        private RenderTargetHandle tempTexture;

        public VolumetricRenderPass(Material material, int materialPassIndex) : base()
        {
            this.materialPassIndex = materialPassIndex;
            this.material = material;
            tempTexture.Init("_TempVolumetricTexture");
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
            CommandBuffer cmd = CommandBufferPool.Get("VolumetricRenderCommands");

            RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDesc, FilterMode.Bilinear);

            Blit(cmd, _source, tempTexture.Identifier(), material, this.materialPassIndex);
            Blit(cmd, tempTexture.Identifier(), _source);

            //Execute and release commands
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //Release any temporary textures
            cmd.ReleaseTemporaryRT(tempTexture.id);
        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material material;
        public int materialPassIndex = -1;
    }

    [SerializeField]
    private Settings settings = new Settings();

    VolumetricRenderPass volumetricRenderPass;

    /// <inheritdoc/>
    public override void Create()
    {

        volumetricRenderPass = new VolumetricRenderPass(settings.material, settings.materialPassIndex);

        // Configures where the render pass should be injected.
        volumetricRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        volumetricRenderPass.source = renderer.cameraColorTarget;
        renderer.EnqueuePass(volumetricRenderPass);
    }
}


