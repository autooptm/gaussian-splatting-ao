#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/submodules/diff-gaussian-rasterization"

pip uninstall diff-gaussian-rasterization -y || true
rm -rf build
git checkout 3dgs_accel
git submodule update --init --recursive

SHIM='struct AoCubMax { template <class T> __host__ __device__ __forceinline__ T operator()(const T \&a, const T \&b) const { return a > b ? a : b; } };\nstruct AoCubMin { template <class T> __host__ __device__ __forceinline__ T operator()(const T \&a, const T \&b) const { return a < b ? a : b; } };'
for f in $(grep -rl "cub::Max()\|cub::Min()" cuda_rasterizer 2>/dev/null); do
    echo "   CUDA 13 shim -> $f"
    sed -i "0,/^#include.*$/s//&\n$SHIM/" "$f"      # after the first #include
    sed -i 's/cub::Max()/AoCubMax()/g; s/cub::Min()/AoCubMin()/g' "$f"
done

pip install .
python -c "from diff_gaussian_rasterization import SparseGaussianAdam; print('rasterizer installed')"
