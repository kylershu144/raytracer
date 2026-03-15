implementing "../brdf.slang";

public struct GlassBRDF
{
    public float3 albedo;
    public float ior;

    public float3 evaluate()
    {
        return albedo;
    }

    public float3 sample(float3 rayOut, float3 normal)
    {

        float3 sampleDirection = rayOut;
        float3x3 worldToLocalMatrix = getWorldToLocalMatrix(normal, rayOut);
        float3x3 localToWorldMatrix = transposeMatrix(worldToLocalMatrix);

        // TODO: Student implementation starts here.
        float3 rayLocal = normalize(mul(worldToLocalMatrix, rayOut));
        float3 normalLocal = normalize(mul(worldToLocalMatrix, normal));

        float cosTheta1 = dot(rayLocal, normalLocal);

        float eta1 = 1.0; // air
        float eta2 = ior;

        if (cosTheta1 < 0.0) // exiting
        {
            float temp = eta1;
            eta1 = eta2;
            eta2 = temp;
            normalLocal = -normalLocal;
            cosTheta1 = dot(rayLocal, normalLocal);
        }

        float eta = eta1 / eta2;

        float sin2ThetaT = eta * eta * (1.0 - cosTheta1 * cosTheta1);

        // total internal reflection
        if (sin2ThetaT > 1.0)
        {
            float3 reflDir = rayLocal - 2.0 * dot(rayLocal, normalLocal) * normalLocal;
            return mul(localToWorldMatrix, normalize(reflDir));
        }

        float cosThetaT = sqrt(1.0 - sin2ThetaT);

        float3 refrDir =
            eta * (-rayLocal) +
            (eta * cosTheta1 - cosThetaT) * normalLocal;

        return mul(localToWorldMatrix, normalize(refrDir));

        // TODO: Student implementation ends here.

        return sampleDirection;
    }

    public float pdf(float3 rayIn, float3 rayOut, float3 normal)
    {
        // For dielectric materials, the PDF is 1.0 for the single direction
        // (either refracted or reflected due to total internal reflection)
        return 1.0;
    }
}
