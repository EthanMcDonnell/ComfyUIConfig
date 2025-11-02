# ComfyUIConfig
Scripts and other things to initialise and setup ComfyUI


## Workflow info

Dataset gen workflow:
https://www.youtube.com/watch?v=jtwzVMV1quc

qwen edit
https://github.com/dci05049/Comfyui-workflows/tree/main/Qwen%20Image%20Edit

qwen image
https://docs.comfy.org/tutorials/image/qwen/qwen-image

instareal
https://civitai.com/models/1822984/instagirl-wan-22

instareal lenovo wan 2.2
https://www.reddit.com/r/civitai/comments/1n0vhc1/wan_22_realism_workflow_results_instareal_lenovo/

qwen edit
Can do carasaeul images

qwen image with load image
Can be used to replicate similar image
https://www.youtube.com/watch?v=McI8Z9lCahk

Information from author:\
I'd be happy to explain.
I start by doing the regular image generation, that uses the high noise model, then the low noise model.
I then take that and upscale it with 4xLSDIR, then downscale by half, effectively making it a 2xLSDIR upscale.
Then I encode the image back to latent space with a VAE encode and run it through a KSampler (using low noise model) and a low denoise value of 0.30. I only use 3 steps for this. The idea of this is to try and eliminate or reduce weird artefacts produced by the upscaling process.
Finally, I do a 1x upscale using a skin texture 'upscaler.' (1x ITF SkinDiffDetail Lite v1) This adds some more realism to the skin rather than that glossy awful AI skin. Then, I add some noise to try and simulate some distortion that you would experience on a regular phone.
Hope this helps, happy to answer any more questions.