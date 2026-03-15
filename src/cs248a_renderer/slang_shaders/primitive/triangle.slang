implementing "../primitive.slang";
import math;

public struct Triangle : IBoundingBox, IRayCastable
{
    public float3[3] vertices;
    public float3[3] normals;
    public float2[3] uvs;
    public float3[3] colors;
    public uint materialId;
    public uint offset;

    public BoundingBox boundingBox()
    {
        return BoundingBox(float3(0.0), float3(0.0));
    }

    /* Returns the average color of the triangle. */
    public float3 averageColor()
    {
        return (this.colors[0] + this.colors[1] + this.colors[2]) / 3.0;
    }

    public float area(float3 a, float3 b, float3 c) {
        return length(cross(b - a, c - a));
    }

    /**
     * Calculates the barycentric coordinates of a point on the triangle.
     * @param p The point on the triangle to calculate the barycentric coordinates for.
     * @return The barycentric coordinates of the point.
     */
    public float3 calculateBarycentricCoord(float3 p)
    {
        const float EPSILON = 1e-6;
        float u = 0.0;
        float v = 0.0;
        float w = 0.0;

        // TODO: Student implementation starts here.
        float abc = area(vertices[0], vertices[1], vertices[2]);
        float abp = area(vertices[0], vertices[1], p);
        float bcp = area(vertices[1], vertices[2], p);
        w = abp / abc;
        u = bcp / abc;
        v = 1 - w - u;
        // TODO: Student implementation ends here.

        return float3(u, v, w);
    }

    public float2 getUV(float3 barycentricCoord)
    {
        float2 uv = float2(0.0);

        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        uv = u * this.uvs[0] + v * this.uvs[1] + w * this.uvs[2];
        
        return uv;
    }

    public float3 getColor(float3 barycentricCoord)
    {
        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        float3 color = u * this.colors[0] + v * this.colors[1] + w * this.colors[2];
        return color;
    }

    public float3 getNormal(float3 barycentricCoord)
    {
        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        float3 normal = u * this.normals[0] + v * this.normals[1] + w * this.normals[2];
        return normalize(normal);
    }

    /**
     * Test ray-triangle intersection.
     * @param ray The ray to test against the triangle.
     * @return An Optional containing RayHitResult if the ray hits the triangle, otherwise an empty Optional.
     */
    public Optional<RayHitResult> hit(Ray ray)
    {
        // TODO: Student implementation starts here.
        float3 ab = vertices[1] - vertices[0];
        float3 ac = vertices[2] - vertices[0];

        float3 planeNormal = normalize(cross(ab, ac));
        float c = dot(planeNormal, vertices[0]);

        if (abs(dot(planeNormal, ray.direction)) < 1e-6) return Optional<RayHitResult>();
        float t = (c - dot(planeNormal, ray.origin)) / dot(planeNormal, ray.direction);
        if (t < ray.tRange[0] || t > ray.tRange[1]) return Optional<RayHitResult>();
        float3 intersect = ray.origin + t * ray.direction;

        for (int i = 0; i < 3; i++) {
            int j = (i + 1) % 3;
            float3 edge = vertices[j] - vertices[i];
            float3 edgeNormal = normalize(cross(edge, planeNormal));
            float edgeC = dot(edgeNormal, vertices[i]);
            if (dot(intersect, edgeNormal) > edgeC) return Optional<RayHitResult>();
        }

        return RayHitResult(t, planeNormal);

        // TODO: Student implementation ends here.
    }

    public uint getMaterialId()
    {
        return this.materialId + this.offset;
    }
}
