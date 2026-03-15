implementing "../texture.slang";

public struct SharedTexture2DBuffer<T>
    where T : IFloat
{
    public StructuredBuffer<T> buffer;

    T getBufferValue(SharedTexture2D tex, uint2 texelCoord)
    {
        uint2 texSize = tex.size;
        uint offset = tex.offset;
        uint index = texelCoord.y * texSize.x + texelCoord.x;
        return buffer[offset + index];
    }

    public T pointSample(SharedTexture2D tex, float2 uv)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        outV = getBufferValue(tex, uv * tex.size);
        // TODO: Student implementation ends here.
        return outV;
    }

    public T bilinearSample(SharedTexture2D tex, float2 uv)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        float2 v = (uv * tex.size) - 0.5;
        uint2 v0 = uint2(floor(v));
        uint2 v1 = min(v0 + uint2(1, 1), tex.size - 1);

        float2 t = v - float2(v0);
        T c00 = getBufferValue(tex, v0);
        T c10 = getBufferValue(tex, uint2(v1.x, v0.y));
        T c01 = getBufferValue(tex, uint2(v0.x, v1.y));
        T c11 = getBufferValue(tex, v1);
        outV = c00 * T((1 - t.x) * (1 - t.y)) + 
               c10 * T(t.x * (1 - t.y)) + 
               c01 * T((1 - t.x) * t.y) + 
               c11 * T(t.x * t.y);
        // TODO: Student implementation ends here.
        return outV;
    }

    // @param d: the mip level to sample from, where 0 is the highest resolution level.
    public T trilinearSample(SharedTexture2D[] mipmapLevels, float2 uv, float d, uint totalLevels)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        int d_min = int(floor(d));
        int d_max = min(d_min + 1, totalLevels - 1);
        float t = d - float(d_min);
        T v0 = bilinearSample(mipmapLevels[d_min], uv);
        T v1 = bilinearSample(mipmapLevels[d_max], uv);
        outV = v0 * T(1.0 - t) + v1 * T(t);
        // TODO: Student implementation ends here.
        return outV;
    }
}

public struct SharedTexture2D
{
    public uint2 size;
    public uint offset;
}

public struct SharedTexture3DBuffer<T>
    where T : IFloat
{
    public StructuredBuffer<T> buffer;

    T getBufferValue(SharedTexture3D tex, uint3 voxelCoord)
    {
        uint3 texSize = tex.size;
        uint offset = tex.offset;
        uint index = voxelCoord.z * texSize.y * texSize.x +
                     voxelCoord.y * texSize.x +
                     voxelCoord.x;
        return buffer[offset + index];
    }

    /**
     * Sample the texture at the given uvw coordinates using nearest neighbor interpolation.
     * @param tex The texture to sample.
     * @param uvw The uvw coordinates to sample the texture at.
     * @return The sampled value.
     */
    public T pointSample(SharedTexture3D tex, float3 uvw)
    {
        // TODO: Student implementation starts here.
        return getBufferValue(tex, uvw * tex.size);

        // TODO: Student implementation ends here.
    }

    /**
     * Sample the texture at the given uvw coordinates using trilinear interpolation.
     * @param tex The texture to sample.
     * @param uvw The uvw coordinates to sample the texture at.
     * @return The sampled value.
     **/
    public T trilinearSample(SharedTexture3D tex, float3 uvw)
    {
        // TODO: Student implementation starts here.
        float3 v = uvw * tex.size;
        uint3 v0 = uint3(floor(v));
        uint3 v1 = v0 + uint3(1, 1, 1);
        float3 t = v - float3(v0);
        T c000 = getBufferValue(tex, v0);
        T c100 = getBufferValue(tex, uint3(v1.x, v0.y, v0.z));
        T c010 = getBufferValue(tex, uint3(v0.x, v1.y, v0.z));
        T c110 = getBufferValue(tex, uint3(v1.x, v1.y, v0.z));
        T c001 = getBufferValue(tex, uint3(v0.x, v0.y, v1.z));
        T c101 = getBufferValue(tex, uint3(v1.x, v0.y, v1.z));
        T c011 = getBufferValue(tex, uint3(v0.x, v1.y, v1.z));
        T c111 = getBufferValue(tex, v1);

        return 
            c000.mul(T((1 - t.x) * (1 - t.y) * (1 - t.z))) +
               c100.mul(T(t.x * (1 - t.y) * (1 - t.z))) +
               c010.mul(T((1 - t.x) * t.y * (1 - t.z))) +
               c110.mul(T(t.x * t.y * (1 - t.z))) +
               c001.mul(T((1 - t.x) * (1 - t.y) * t.z)) +
               c101.mul(T(t.x * (1 - t.y) * t.z)) +
               c011.mul(T((1 - t.x) * t.y * t.z)) +
               c111.mul(T(t.x * t.y * t.z));

        // TODO: Student implementation ends here.
    }
}

public struct SharedTexture3D
{
    public uint3 size;
    public uint offset;
}

