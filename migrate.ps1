param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRepoPath
)

$Destination = "."

$Files = @(
    "src/cs248a_renderer/model/bvh.py"
    "src/cs248a_renderer/model/scene_object.py"
    "src/cs248a_renderer/slang_shaders/math/ray.slang"
    "src/cs248a_renderer/slang_shaders/math/bounding_box.slang"
    "src/cs248a_renderer/slang_shaders/model/bvh.slang"
    "src/cs248a_renderer/slang_shaders/model/camera.slang"
    "src/cs248a_renderer/slang_shaders/primitive/triangle.slang"
    "src/cs248a_renderer/slang_shaders/primitive/sdf.slang"
    "src/cs248a_renderer/slang_shaders/primitive/volume.slang"
    "src/cs248a_renderer/slang_shaders/renderer/volume_renderer.slang"
    "src/cs248a_renderer/slang_shaders/texture/diff_texture.slang"
    "src/cs248a_renderer/slang_shaders/texture/texture.slang"
)

foreach ($file in $Files) {
    $destinationDir = Join-Path $Destination (Split-Path $file)

    if (!(Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    Copy-Item -Path (Join-Path $SourceRepoPath $file) `
              -Destination (Join-Path $Destination $file) `
              -Force

    Write-Host "Copied $file"
}

Write-Host "Done."