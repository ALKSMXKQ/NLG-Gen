#!/usr/bin/env bash
set -euo pipefail

: "${SLEDGE_DEVKIT_ROOT:?Set SLEDGE_DEVKIT_ROOT}"
: "${SLEDGE_EXP_ROOT:?Set SLEDGE_EXP_ROOT}"
: "${NLG_GEN_CONFIG:?Set NLG_GEN_CONFIG}"
: "${RVAE_CHECKPOINT:?Set RVAE_CHECKPOINT}"
: "${DIFFUSION_CHECKPOINT:?Set DIFFUSION_CHECKPOINT}"

ORIGINAL_DIR="${ORIGINAL_DIR:-$SLEDGE_EXP_ROOT/caches/autoencoder_cache}"
EDITED_DIR="${EDITED_DIR:-$SLEDGE_EXP_ROOT/exp/nlg_gen/raw_cache}"
OUTPUT_DIR="${OUTPUT_DIR:-$SLEDGE_EXP_ROOT/exp/nlg_gen/refinement}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"

python "$SLEDGE_DEVKIT_ROOT/sledge/script/run_half_denoise_from_tiered_cache.py" \
  --original-dir "$ORIGINAL_DIR" \
  --edited-dir "$EDITED_DIR" \
  --output "$OUTPUT_DIR" \
  --config "$NLG_GEN_CONFIG" \
  --autoencoder-checkpoint "$RVAE_CHECKPOINT" \
  --diffusion-checkpoint "$DIFFUSION_CHECKPOINT" \
  --num-inference-timesteps 24 \
  --guidance-scale 4.0 \
  --round-start-step-seq 14,10,6 \
  --repair-attempts 4 \
  --alignment-threshold 0.70 \
  --min-preservation-ratio 0.93 \
  --diff-threshold 1e-4 \
  --diff-mask-dilation 3 \
  --roi-mask-dilation 2 \
  --pedestrian-roi-strength 1.0 \
  --roadside-anchor-strength 1.0 \
  --lane-anchor-strength 1.0 \
  --crossing-corridor-strength 0.95 \
  --generic-roi-strength 0.90 \
  --projection-inner-iters 2 \
  --projection-x-alpha 0.35 \
  --projection-y-alpha 0.55 \
  --projection-heading-alpha 0.55 \
  --projection-velocity-alpha 0.55 \
  --projection-size-alpha 0.20 \
  --projection-max-pos-shift-m 1.50 \
  --projection-max-heading-shift-rad 0.70 \
  --projection-max-speed-delta 0.80 \
  --projection-match-max-dist 6.0 \
  --seed 0 \
  --save-visuals \
  --save-latents
