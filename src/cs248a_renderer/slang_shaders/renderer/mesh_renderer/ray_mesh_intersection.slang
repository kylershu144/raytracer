implementing "../renderer.slang";

import light;

public struct RayMeshIntersectionResult
{
    public RayHitResult closestHit;
    public Triangle hitTriangle;
}

public Optional<RectangularLight.LightHitResult> rayRectangularLightIntersection(Ray ray, RendererUniform uniforms)
{
    Optional<RectangularLight.LightHitResult> closestLightHitResult = Optional<RectangularLight.LightHitResult>();
    for (int i = 0; i < uniforms.rectangularLightCount; i++)
    {
        Optional<RectangularLight.LightHitResult> lightHitResult = uniforms.rectangularLightBuf[i].hit(ray);
        if (lightHitResult.hasValue)
        {
            if (!closestLightHitResult.hasValue || lightHitResult.value.t < closestLightHitResult.value.t)
            {
                closestLightHitResult = lightHitResult;
            }
        }
    }
    return closestLightHitResult;
}

public Optional<RayMeshIntersectionResult> rayMeshIntersection(Ray ray, RendererUniform uniforms, bool occlusionTest = false)
{
    Optional<RayHitResult> result = Optional<RayHitResult>();
    Optional<RayMeshIntersectionResult> allResult = Optional<RayMeshIntersectionResult>();
    Optional<Triangle> hitTriangle = Optional<Triangle>();

    // IMPORTANT NOTE: Check the modified signature of `rayMeshIntersection` function in ray_mesh_intersection.slang.
    // Can you modify your existing code to make use of this flag? This is helpful in `isLightOccluded` function.

    // TODO: Student implementation starts here.
    float minT = float.maxValue;
    if (uniforms.useBVH) {
        Optional<BVH<Triangle>.HitResult> hitResultOptional = uniforms.bvh.hit(ray);
        if (hitResultOptional.hasValue && hitResultOptional.value.rayHitResult.t < minT)
        {
            minT = hitResultOptional.value.rayHitResult.t;
            result = hitResultOptional.value.rayHitResult;
            hitTriangle = hitResultOptional.value.primitive;

            if (occlusionTest) {
                return Optional<RayMeshIntersectionResult>(RayMeshIntersectionResult(result.value, hitTriangle.value));
            }
        }
    }
    else {
        for (int i = 0; i < uniforms.triangleCount; i++)
        {
            Optional<RayHitResult> resultOptional = uniforms.triangleBuf[i].hit(ray);
            if (resultOptional.hasValue && resultOptional.value.t < minT)
            {
                minT = resultOptional.value.t;
                result = resultOptional.value;
                hitTriangle = Optional<Triangle>(uniforms.triangleBuf[i]);
                
                if (occlusionTest) {
                    return Optional<RayMeshIntersectionResult>(RayMeshIntersectionResult(result.value, hitTriangle.value));
                }
            }
        }
    }
        
    // TODO: Student implementation ends here.

    if (result.hasValue && hitTriangle.hasValue)
    {
        allResult = Optional<RayMeshIntersectionResult>(RayMeshIntersectionResult(result.value, hitTriangle.value));
    }

    return allResult;
}
