implementing "../math.slang";

public struct BoundingBox
{
    public float3 pMin;
    public float3 pMax;

    public static BoundingBox union
    (BoundingBox a, BoundingBox b)
    {
        float3 uMin = min(a.pMin, b.pMin);
        float3 uMax = max(a.pMax, b.pMax);
        return BoundingBox(uMin, uMax);
    }

    public __init(float3 pMin, float3 pMax)
    {
        this.pMin = pMin;
        this.pMax = pMax;
    }

    public float3 centroid()
    {
        return 0.5 * (this.pMin + this.pMax);
    }

    public float3 size()
    {
        return this.pMax - this.pMin;
    }

    public float area()
    {
        float3 size = this.size();
        return 2 * (size.x * size.y + size.y * size.z + size.z * size.x);
    }

    public float bboxFaceIntersection(Ray ray, float3[4] faceVertices)
    {
        float3 diff = this.pMax - this.pMin;

        float3 ab = faceVertices[1] - faceVertices[0];
        float3 ac = faceVertices[2] - faceVertices[0];

        float3 planeNormal = normalize(cross(ab, ac));
        float c = dot(planeNormal, faceVertices[0]);

        if (dot(planeNormal, ray.direction) == 0) return -1.0;
        float t = (c - dot(planeNormal, ray.origin)) / dot(planeNormal, ray.direction);
        float3 intersect = ray.origin + t * ray.direction;

        for (int i = 0; i < 4; i++) {
            int j = (i + 1) % 4;
            float3 edge = faceVertices[j] - faceVertices[i];
            float3 edgeNormal = normalize(cross(edge, planeNormal));
            float edgeC = dot(edgeNormal, faceVertices[i]);
            if (dot(intersect, edgeNormal) > edgeC) return -1.0;
        }

        return t;
    }

    public float2 hit(Ray ray)
    {
        // TODO: Student implementation starts here.
        float tMin = float.maxValue;
        float tMax = -float.maxValue;

        float3 invDir = 1.0 / ray.direction;
        float3 t0 = (this.pMin - ray.origin) * invDir;
        float3 t1 = (this.pMax - ray.origin) * invDir;

        float3 tMinFace = min(t0, t1);
        float3 tMaxFace = max(t0, t1);

        tMin = max(tMinFace.x, max(tMinFace.y, tMinFace.z));
        tMax = min(tMaxFace.x, min(tMaxFace.y, tMaxFace.z));

        if (tMin > tMax || tMax < 0) {
            return float2(0.0, 0.0);
        }

        return float2(tMin, tMax);

        // TODO: Student implementation ends here.
    }
};

public interface IBoundingBox
{
    public BoundingBox boundingBox();
}

public void loadBoundingBoxes<T : IBoundingBox>(
    uint tid,
    uint offset,
    StructuredBuffer<T> primitives,
    RWStructuredBuffer<BoundingBox> boundingBoxes)
{
    uint idx = tid + offset;
    boundingBoxes[tid] = primitives[idx].boundingBox();
}

public void splitPrimitives<T : IBoundingBox>(
    uint tid,
    uint offset,
    StructuredBuffer<T> primitives,
    RWStructuredBuffer<uint> leftFlags,
    RWStructuredBuffer<uint> rightFlags,
    uint axis,
    float threshold)
{
    BoundingBox box = primitives[tid + offset].boundingBox();
    float3 centroid = box.centroid();
    if (centroid[uint(axis)] < threshold)
    {
        leftFlags[tid + offset] = 1;
        rightFlags[tid + offset] = 0;
    }
    else
    {
        leftFlags[tid + offset] = 0;
        rightFlags[tid + offset] = 1;
    }
}

public void reduceUnionPass(
    uint tid,
    uint numBoxes,
    StructuredBuffer<BoundingBox> inputBoxes,
    RWStructuredBuffer<BoundingBox> outputBoxes)
{
    uint idx = tid * 2;
    if (idx >= numBoxes)
        return;
    BoundingBox boxA = inputBoxes[idx];
    BoundingBox boxB = (idx + 1 < numBoxes) ? inputBoxes[idx + 1] : boxA;
    BoundingBox unionBox = BoundingBox.union
    (boxA, boxB);
    outputBoxes[tid] = unionBox;
}
