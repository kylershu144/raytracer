implementing "../renderer.slang";

import utils;

public float2 getShiftedTexUV(float2 uv, RendererUniform uniforms, Triangle triangle, float2 delta, float2 tex_uv)
{
    float2 shifted_uv = uv + delta;
    Ray ray = uniforms.camera.generateRay(shifted_uv);
    Optional<RayHitResult> hitResult = triangle.hit(ray);
    float2 result = tex_uv;
    if (hitResult.hasValue)
    {
        float3 hitPoint = ray.origin + hitResult.value.t * ray.direction;
        float3 barycentricCoord = triangle.calculateBarycentricCoord(hitPoint);
        return triangle.getUV(barycentricCoord);
    }

    Optional<RayMeshIntersectionResult> rayMeshIntersectionResult_dx = rayMeshIntersection(ray, uniforms);
    if (rayMeshIntersectionResult_dx.hasValue)
    {
        Triangle hitTriangle = rayMeshIntersectionResult_dx.value.hitTriangle;
        if (hitTriangle.getMaterialId() == triangle.getMaterialId())
        {
            float3 hitPoint = ray.origin + rayMeshIntersectionResult_dx.value.closestHit.t * ray.direction;
            float3 barycentricCoord = hitTriangle.calculateBarycentricCoord(hitPoint);
            return hitTriangle.getUV(barycentricCoord);
        }
    }

    return tex_uv;
}

public float getLevel(float2 uv, RendererUniform uniforms, Triangle triangle, float2 tex_uv)
{
    float level = 0.0;

    // TODO: Student implementation starts here.
    float eps = 1e-6;

    Ray dx_pos_ray = uniforms.camera.generateRay(uv + float2(eps, 0));
    Ray dy_pos_ray = uniforms.camera.generateRay(uv + float2(0, eps));
    Ray dx_neg_ray = uniforms.camera.generateRay(uv - float2(eps, 0));
    Ray dy_neg_ray = uniforms.camera.generateRay(uv - float2(0, eps));
    Optional<RayMeshIntersectionResult> dx_pos = rayMeshIntersection(dx_pos_ray, uniforms);
    Optional<RayMeshIntersectionResult> dy_pos = rayMeshIntersection(dy_pos_ray, uniforms);
    Optional<RayMeshIntersectionResult> dx_neg = rayMeshIntersection(dx_neg_ray, uniforms);
    Optional<RayMeshIntersectionResult> dy_neg = rayMeshIntersection(dy_neg_ray, uniforms);

    float2 dudx = (dx_pos.value.hitTriangle.getUV(dx_pos.value.hitTriangle.calculateBarycentricCoord(dx_pos_ray.origin + dx_pos.value.closestHit.t * dx_pos_ray.direction)) 
                    - dx_neg.value.hitTriangle.getUV(dx_neg.value.hitTriangle.calculateBarycentricCoord(dx_neg_ray.origin + dx_neg.value.closestHit.t * dx_neg_ray.direction))) / (2.0 * eps);
    float2 dudy = (dy_pos.value.hitTriangle.getUV(dy_pos.value.hitTriangle.calculateBarycentricCoord(dy_pos_ray.origin + dy_pos.value.closestHit.t * dy_pos_ray.direction)) 
                    - dy_neg.value.hitTriangle.getUV(dy_neg.value.hitTriangle.calculateBarycentricCoord(dy_neg_ray.origin + dy_neg.value.closestHit.t * dy_neg_ray.direction))) / (2.0 * eps);

    float rho_x = length(dudx);
    float rho_y = length(dudy);

    level = log2(max(rho_x, rho_y));
    // TODO: Student implementation ends here.

    return level;
}

public PhysicsBasedParameters getHitPointParameters(float2 uv, RendererUniform uniforms, Triangle triangle, float3 normal, float3 barycentricCoord, float3 hitPoint)
{
    float2 tex_uv = triangle.getUV(barycentricCoord);
    float level = getLevel(uv, uniforms, triangle, tex_uv);
    uint materialId = triangle.materialId + triangle.offset;
    PhysicsBasedMaterial physicsBasedMaterial = uniforms.physicsBasedMaterialBuf[materialId];
    PhysicsBasedParameters parameters = sampleMaterial(physicsBasedMaterial, uniforms.physicsBasedMaterialTextureBuf, tex_uv, level, uniforms.visualizeLevelOfDetail);
    if (uniforms.visualizeBarycentricCoords)
    {
        parameters.albedo = barycentricCoord;
    }
    if (uniforms.visualizeTexUV)
    {
        parameters.albedo = float3(tex_uv, 0.0);
    }
    return parameters;
}
