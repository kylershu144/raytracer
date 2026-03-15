$ErrorActionPreference = "Stop"

$ROOT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SUBMISSION_NAME = "submission"
$DEST_DIR = Join-Path $ROOT_DIR $SUBMISSION_NAME

$FILES = @(
  "./src/cs248a_renderer/model/material.py",
  "./src/cs248a_renderer/model/bvh.py",
  "./src/cs248a_renderer/model/scene_object.py",
  "./src/cs248a_renderer/slang_shaders/math/ray.slang",
  "./src/cs248a_renderer/slang_shaders/math/bounding_box.slang",
  "./src/cs248a_renderer/slang_shaders/model/bvh.slang",
  "./src/cs248a_renderer/slang_shaders/model/camera.slang",
  "./src/cs248a_renderer/slang_shaders/primitive/triangle.slang",
  "./src/cs248a_renderer/slang_shaders/renderer/mesh_renderer/mesh_illumination.slang",
  "./src/cs248a_renderer/slang_shaders/renderer/mesh_renderer/mesh_material.slang",
  "./src/cs248a_renderer/slang_shaders/renderer/mesh_renderer/ray_mesh_intersection.slang",
  "./src/cs248a_renderer/slang_shaders/renderer/mesh_renderer.slang",
  "./src/cs248a_renderer/slang_shaders/brdf/lambertian.slang",
  "./src/cs248a_renderer/slang_shaders/brdf/mirror.slang",
  "./src/cs248a_renderer/slang_shaders/brdf/glass.slang",
  "./src/cs248a_renderer/slang_shaders/light/rect_light.slang",
  "./src/cs248a_renderer/slang_shaders/texture/diff_texture.slang",
  "./src/cs248a_renderer/slang_shaders/texture/texture.slang"
)

# Remove old submission folder
if (Test-Path $DEST_DIR) {
    Remove-Item $DEST_DIR -Recurse -Force
}

New-Item -ItemType Directory -Path $DEST_DIR | Out-Null

foreach ($rel in $FILES) {

    $src = Join-Path $ROOT_DIR $rel

    if (!(Test-Path $src)) {
        Write-Error "Missing source file: $rel"
        exit 1
    }

    $relativeDir = Split-Path $rel -Parent
    $dstDir = Join-Path $DEST_DIR $relativeDir

    if (!(Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    Copy-Item $src -Destination $dstDir
}

$ZIP_NAME = "$SUBMISSION_NAME.zip"
$ZIP_PATH = Join-Path $ROOT_DIR $ZIP_NAME

if (Test-Path $ZIP_PATH) {
    Remove-Item $ZIP_PATH -Force
}

Compress-Archive -Path $DEST_DIR -DestinationPath $ZIP_PATH

Remove-Item $DEST_DIR -Recurse -Force

Write-Host "Created $ZIP_NAME"