implementing "../brdf.slang";

import utils;

public struct LambertianBRDF
{
    public float3 albedo;
    public bool useCosineWeightedSampling;

    public float3 evaluate()
    {
        float3 fr = this.albedo;

        fr = this.albedo * INV_PI;

        return fr;
    }

    public float3 sample(float3 rayOut, float3 normal, float2 randomEpsilon)
    {
        float3 sampleDirection = rayOut;
        float3x3 worldToLocalMatrix = getWorldToLocalMatrix(normal, rayOut);
        float3x3 localToWorldMatrix = transposeMatrix(worldToLocalMatrix);

        // HINT: First convert the reflected ray direction to the local space,
        // then compute the incident ray direction in the local space,
        // and finally convert it to the world space.

        if (this.useCosineWeightedSampling)
        {
            // TODO: Student implementation starts here.

            float r = sqrt(randomEpsilon.x);
            float phi = 2.0 * PI * randomEpsilon.y;

            float x = r * cos(phi);
            float y = r * sin(phi);
            float z = sqrt(1.0 - randomEpsilon.x);

            float3 localDir = float3(x, z, y);

            // Transform to world space
            sampleDirection = normalize(mul(localToWorldMatrix, localDir));

            // TODO: Student implementation ends here.
        }
        else // uniform sampling, use uniform sampling by default
        {
            // TODO: Student implementation starts here.
            float z = randomEpsilon.x;
            float r = sqrt(max(0.0, 1 - z * z));
            float phi = 2 * PI * randomEpsilon.y;
            sampleDirection = mul(localToWorldMatrix, normalize(float3(r * cos(phi), z, r * sin(phi))));

            // TODO: Student implementation ends here.
        }

        return sampleDirection;
    }

    public float pdf(float3 rayIn, float3 rayOut, float3 normal)
    {
        float EPSILON = 1e-6;
        float pdf = all(abs(rayIn - rayOut) < EPSILON) ? 1.0 : 0.0;

        if (this.useCosineWeightedSampling)
        {
            // TODO: Student implementation starts here.
            float cosTheta = max(dot(normalize(normal), normalize(rayIn)), 0.0);
            pdf = cosTheta * INV_PI;

            // TODO: Student implementation ends here.
        }
        else // uniform sampling, use uniform sampling by default
        {
            // TODO: Student implementation starts here.
            pdf = INV_TWO_PI;

            // TODO: Student implementation ends here.
        }

        return pdf;
    }
}
