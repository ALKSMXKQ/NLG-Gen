# Reproducing NLG-Gen

This guide covers the paper pipeline from source scenario caches to evaluated, simulator-ready critical scenarios. Commands use environment variables so that experiments remain portable across machines.

## 1. Configure paths

```bash
export NUPLAN_DATA_ROOT=/path/to/nuplan
export NUPLAN_MAPS_ROOT=/path/to/nuplan/maps
export SLEDGE_DEVKIT_ROOT=/path/to/sledge0421
export SLEDGE_EXP_ROOT=/path/to/sledge_workspace/exp

export NLG_GEN_CONFIG=/path/to/semantic_img2img_cfg.yaml
export RVAE_CHECKPOINT=/path/to/rvae.ckpt
export DIFFUSION_CHECKPOINT=/path/to/diffusion/checkpoint
```

The commands below assume that the SLEDGE autoencoder cache already exists at `$SLEDGE_EXP_ROOT/caches/autoencoder_cache`.

## 2. Build the edited scenario cache

```bash
python sledge/script/build_multiscenario_raw_cache.py \
  --input-dir "$SLEDGE_EXP_ROOT/caches/autoencoder_cache" \
  --output-root "$SLEDGE_EXP_ROOT/exp/nlg_gen/raw_cache" \
  --config "$NLG_GEN_CONFIG" \
  --glob-pattern "**/sledge_raw.gz" \
  --crossing-ratio 0.20 \
  --cut-in-ratio 0.30 \
  --hard-brake-ratio 0.50 \
  --mild-ratio 0.50 \
  --moderate-ratio 0.35 \
  --aggressive-ratio 0.15 \
  --max-scenes 500
```

This stage writes the edited B1 cache and a manifest that records each source scenario, structured hazard specification, and editing outcome.

## 3. Run constraint-preserving diffusion inpainting

```bash
python sledge/script/run_half_denoise_from_tiered_cache.py \
  --original-dir "$SLEDGE_EXP_ROOT/caches/autoencoder_cache" \
  --edited-dir "$SLEDGE_EXP_ROOT/exp/nlg_gen/raw_cache" \
  --output "$SLEDGE_EXP_ROOT/exp/nlg_gen/refinement" \
  --scenario-cache-root "$SLEDGE_EXP_ROOT/caches/nlg_gen_scenarios" \
  --config "$NLG_GEN_CONFIG" \
  --autoencoder-checkpoint "$RVAE_CHECKPOINT" \
  --diffusion-checkpoint "$DIFFUSION_CHECKPOINT" \
  --guidance-scale 4.0 \
  --low-noise-start-step-seq 10,12,14 \
  --repair-attempts 6 \
  --save-visuals \
  --save-latents
```

The output contains B2 vector scenarios, candidate diagnostics, and optional latent and visualization artifacts.

## 4. Evaluate generated scenarios

```bash
python sledge/script/evaluate/evaluate_main_table.py \
  --mode manifest \
  --method-name NLG_GEN \
  --manifest "$SLEDGE_EXP_ROOT/exp/nlg_gen/raw_cache/scenario_manifest_B2_eval.csv" \
  --which generated \
  --generated-root "$SLEDGE_EXP_ROOT/caches/nlg_gen_scenarios" \
  --reference-cache "$SLEDGE_EXP_ROOT/caches/nlg_gen_scenarios" \
  --accepted-only \
  --output "$SLEDGE_EXP_ROOT/exp/nlg_gen/evaluation"
```

Reported metrics include semantic alignment (MPA), compliance rate (CR), scenario quality (SQS), drivable route length (DRL), interaction strength, contextual change (CTC), and repaint success rate (RSR).

## 5. Run the stage-wise ablation

Use `evaluate_manifest_baseline.py` with the same manifest and configuration:

- `--which original` evaluates B0 without semantic control.
- `--which edited` evaluates B1 after semantic editing.
- `--which generated` evaluates B2 after diffusion inpainting.
- `--which compare` reports paired B1/B2 changes.

Keep the manifest, accepted-sample filter, random seeds, and metric thresholds fixed across variants.

## Output contract

| Artifact | Purpose |
| --- | --- |
| `scenario_manifest.csv` | Source-to-edit mapping and hazard specification |
| `scenario_manifest_B2_eval.csv` | Accepted candidates and generation diagnostics |
| `sledge_raw.gz` | Editable structured scenario representation |
| `sledge_vector.gz` | Simulator-ready vector scenario |
| Evaluation tables | Paper metrics and stage-wise comparisons |

## Notes

- Do not commit nuPlan data, caches, checkpoints, or machine-specific paths.
- Validate semantic alignment and compliance before closed-loop simulation.
- Forced cut-in uses a hazardous state proxy because surrounding agents are lane-regularized during rollout.
