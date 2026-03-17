implementing "../renderer.slang";

import math;
import texture;

public static uint MAX_STEPS = 256;
public static float EPSILON = 1e-6;

public static float STEP_SIZE = 0.01;
public static float DENSITY_SCALE = 5.0;

/**
 * Perform ray marching through the volume and accumulate color.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @param tMax The maximum t value for ray marching (usually the nearest primitive intersection t).
 * @param primColor The color of the nearest primitive intersection.
 * @return The accumulated color after ray marching through the volume.
 */
public float4 volumeSample(float2 uv, RendererUniform uniforms, float tMax, float4 primColor)
{
    // TODO: Student implementation starts here.
    Ray ray = uniforms.camera.generateRay(uv);
    ray = ray.transform(uniforms.volume.invModelMatrix);
    ray.tRange[1] = min(ray.tRange[1], tMax);
    return accumulateColor<4>(ray, uniforms.volume.bound, MAX_STEPS, STEP_SIZE, DENSITY_SCALE, primColor, uniforms.volume.tex);
    
    // TODO: Student implementation ends here.
}

/**
 * Backward pass for volumetric ray marching at a single uv.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @param outGrad The output gradient w.r.t. the sampled color.
 */
public void volumeSampleBwd(float2 uv, RendererUniform uniforms, float4 outGrad)
{
    // TODO: Student implementation starts here.
    Ray ray = uniforms.camera.generateRay(uv);
    ray = ray.transform(uniforms.volume.invModelMatrix);

    RNG rng = RNG(uint2(uv * uniforms.camera.canvasSize), (uv.y * uniforms.camera.canvasSize.x + uv.x) * 10000 + uniforms.seed);
    Optional<RayMeshSampleResult> rayMeshSampleRes = meshSample(uv, uniforms, rng, true);

    float4 primColor = uniforms.ambientColor;
    if (rayMeshSampleRes.hasValue)
    {
        primColor = rayMeshSampleRes.value.color;
        ray.tRange[1] = min(ray.tRange[1], rayMeshSampleRes.value.t);
    }
    DifferentialPtrPair<DiffTexture3D<float, 4>> diffPair = DifferentialPtrPair<DiffTexture3D<float, 4>>(uniforms.volume.tex, uniforms.volume.dTex);
    bwd_diff(accumulateColor<4>)(ray, uniforms.volume.bound, MAX_STEPS, STEP_SIZE, DENSITY_SCALE, 
        primColor, diffPair, outGrad);
    // TODO: Student implementation ends here.
}

/**
 * Ray march through the volume and accumulate color.
 * @param ray The ray in local space.
 * @param volumeBound The bounding box of the volume in local space.
 * @param maxSteps The maximum number of marching steps.
 * @param stepSize The size of each marching step.
 * @param densityScale The scale factor for the volume density (alpha channel).
 * @param backgroundColor The background color behind the volume
                          (this can be the ambient color if there's no primitive behind the volume, or the color of the primitive hit if there's one).
 * @param data The 3D texture storing the volume data (rgba).
 * @return The accumulated color after ray marching through the volume.
 */
[Differentiable]
public float4 accumulateColor<let N : uint>(
    no_diff Ray ray,
    no_diff BoundingBox volumeBound,
    no_diff uint maxSteps,
    no_diff float stepSize,
    no_diff float densityScale,
    no_diff float4 backgroundColor,
    DiffTexture3D<float, 4> data)
{
    // TODO: Student implementation starts here.
    float2 tBounds = volumeBound.hit(ray);
    if (ray.tRange[1] < tBounds[0] || ray.tRange[0] > tBounds[1]) {
        return backgroundColor;
    }

    float4 r = backgroundColor;

    // iterate backwards?
    [MaxIters(256)]
    for (int i = 0; i < maxSteps; i++) {
        float t = tBounds[1] - i * stepSize;
        if (t < tBounds[0] || t < ray.tRange[0]) break;

        float3 pos = ray.origin + t * ray.direction;
        float3 uvw = (pos - volumeBound.pMin) / (volumeBound.pMax - volumeBound.pMin);

        float4 sample = sampleTrilinear(data, uvw);
        float a = sample.a * densityScale * stepSize;

        r.a = r.a * (1 - a) + a;
        r.rgb = r.rgb * (1 - a) + sample.rgb * a;
        // r = r * (1 - a);
    }
    return r;
    // return float4(r.a, r.a, r.a, 1.0);

    // TODO: Student implementation ends here.
}
