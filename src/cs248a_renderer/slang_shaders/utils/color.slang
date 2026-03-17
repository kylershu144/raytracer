implementing "../utils.slang";

public float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

    float4 p = (c.g < c.b)
                   ? float4(c.bg, K.wz)
                   : float4(c.gb, K.xy);

    float4 q = (c.r < p.x)
                   ? float4(p.xyw, c.r)
                   : float4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;

    float h = abs(q.z + (q.w - q.y) / (6.0 * d + e));
    float s = d / (q.x + e);
    float v = q.x;

    return float3(h, s, v);
}

public float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);

    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}