# Codex Master Prompt — Senior Design Sensor Pipeline (MATLAB + NI DAQ)

You are my technical build partner. Create a production-ready, modular MATLAB project that unifies **data acquisition, processing, analysis, and reporting** for a shaker-driven sensor validation workflow.

## 1) Context and outcome
I am an undergraduate mechanical engineering senior design student. My team is validating a custom strain-sensitive sensor under dynamic excitation.

I need one MATLAB system that:
1. Runs repeatable DAQ experiments.
2. Auto-saves raw + metadata in a clean session structure.
3. Auto-processes noisy signals (including blip/dropout handling).
4. Extracts robust metrics (amplitude, gain, phase, noise).
5. Produces publication-ready plots and summary tables.
6. Supports quick operator use with minimal code edits.

The final output must be a maintainable MATLAB codebase with clear function boundaries, examples, and a GUI entrypoint.

## 2) Hardware and signals
- DAQ: National Instruments USB-6218 (MATLAB Data Acquisition Toolbox + NI-DAQmx).
- Typical channels:
  - `AI0`: accelerometer voltage (reference motion).
  - `AI1`: sensor divider voltage.
- Typical sample rate: `fs = 50,000 Hz` (minimum acceptable for primary tests).
- Typical acquisition durations: `2–60 s`.
- Frequency region of primary interest: `1000–1200 Hz`.
- Broader sweep range: `100–1500 Hz`.

### Voltage divider model
- Excitation: `Vin = 5 V`
- Divider relation: `Vout = Vin * (Rsensor / (Rref + Rsensor))`
- Use this to back-calculate `Rsensor(t)` and then derive `ΔR` and sensitivity.

## 3) Known experimental pain points
Your pipeline must explicitly handle these:
- Increased broadband noise at lower excitation amplitudes.
- Intermittent signal “blips” / dropouts / dead spots.
- Occasional mechanical artifacts from fixture/slack/friction.
- Confusion from relying only on time-domain p2p metrics.

## 4) Meeting-driven engineering requirements
Design the workflow around the following decisions:
1. **Use FFT/correlation-based tone extraction** for amplitude and phase at drive frequency `f0`.
2. **Do not rely on detrending alone** to solve non-DC noise.
3. Include **time-domain diagnostics** to visually confirm clean vs bad segments.
4. Include **noise analysis** beyond narrow plots (inspect broad spectrum + harmonics).
5. Enable **long-window filtered analysis** (e.g., bandpass around `f0 ± 100 Hz`) and compare stability.
6. Verify **phase consistency** across replicates and windows.

## 5) Integrate and improve these script concepts
I currently have two script styles that should be merged into one clean architecture:
- Frequency sweep acquisition with CSV + JSON + manifest + timing diagnostics.
- Test-suite style runner (bandwidth sweep, amplitude sweep, deep-dive replicates) with summary metrics.

Preserve strengths from both:
- Session manifests and metadata-rich files.
- Per-test summary table.
- Operator prompts for manual shaker settings.
- Timing diagnostics (`dt_mean`, `dt_std`, dropout flags).

## 6) Required project structure
Build this MATLAB project layout:

```text
sensor_test_system/
  acquisition/
    run_experiment.m
    daq_setup.m
    acquire_trial.m
    run_frequency_sweep.m
    run_amplitude_sweep.m
    run_deep_dive.m

  processing/
    load_raw_data.m
    convert_voltage_to_resistance.m
    accel_to_displacement.m
    detect_bad_segments.m
    stitch_good_cycles.m
    quality_checks.m

  analysis/
    compute_fft.m
    extract_tone_amplitude.m
    compute_gain_phase.m
    noise_analysis.m
    phase_stability_stats.m

  visualization/
    plot_time_signals.m
    plot_fft.m
    plot_noise_spectrum.m
    plot_gain_curve.m
    plot_phase_stability.m
    plot_qc_dashboard.m

  gui/
    sensor_test_gui.m

  config/
    default_config.m

  utils/
    io_helpers.m
    path_helpers.m
    table_helpers.m

  data/
    raw/
    processed/
    sessions/

  examples/
    demo_end_to_end.m

  README.md
```

## 7) Signal-processing requirements
Implement robust defaults with user-overrides.

### 7.1 Preprocessing
- Remove DC bias (`detrend` or mean subtraction).
- Optional windowing before FFT.
- Flag clipping/saturation.
- Validate sample timing regularity and missing data.

### 7.2 Bad-segment handling
- Detect dropouts/blips using amplitude continuity, derivative spikes, and/or envelope thresholds.
- Return segment masks + confidence scores.
- Allow two modes:
  1. Analyze best continuous clean window.
  2. Stitch multiple clean windows (with clear provenance metadata).

### 7.3 Frequency-domain analysis
- Compute one-sided spectrum/PSD.
- Identify dominant peaks and harmonics.
- Estimate 60 Hz contamination metric.
- Extract tone amplitude and phase at `f0` using complex correlation or narrow-bin interpolation.

### 7.4 Gain and phase metrics
Compute at least:
- `sensor_amp_at_f0`
- `accel_amp_at_f0`
- `gain = sensor_amp / accel_amp`
- `phase_deg = phase(sensor) - phase(accel)` wrapped to `[-180, 180]`

### 7.5 Physical-unit conversion
- Convert sensor voltage to resistance over time.
- Convert accelerometer channel toward displacement estimate (document assumptions/calibration inputs).
- Compute sensitivity in `Ω/µm` where feasible.

## 8) Experiment modes
Include these operator workflows:
1. **Bandwidth sweep** (fixed amplitude, multiple frequencies).
2. **Amplitude sweep** (fixed frequency, multiple amplitudes).
3. **Deep-dive replicates** (fixed f and amp, N repeats).
4. **Single run with immediate QC**.

Each run should create:
- Raw CSV (`time_s`, `accel_v`, `sensor_v`).
- Per-run JSON metadata.
- Session manifest JSON.
- Updated processed summary CSV.

## 9) GUI requirements (practical, not flashy)
Build a MATLAB app/function GUI (`sensor_test_gui`) with:
- Inputs: device, channels, fs, duration, frequency list, amplitude list, sensor ID, session ID.
- Buttons:
  - Start Single Test
  - Run Frequency Sweep
  - Run Amplitude Sweep
  - Run Deep Dive
  - Reprocess Existing Session
- Live/near-live panels:
  - Time traces
  - FFT preview
  - QC status (dropout, clipping, timing)
- Post-run panel:
  - gain/phase summary + links to saved artifacts.

## 10) Data and naming conventions
Enforce deterministic folder naming:

```text
data/raw/<sensor_id>/<date>/<session_id>/
```

Use sortable timestamps in filenames. Include `f0`, amplitude, and replicate index where relevant.

## 11) Quality checks and warnings
Auto-check and warn (do not silently fail):
- Irregular sample intervals.
- Missing channels.
- NaN/Inf values.
- Clipped signals.
- Too-low SNR at `f0`.
- Excessive phase variance across replicates.

## 12) Deliverables
Produce:
1. Full MATLAB source for the structure above.
2. Clear top-level README with setup + run instructions.
3. Example script (`examples/demo_end_to_end.m`) demonstrating full acquisition→analysis flow.
4. A concise assumptions section (calibrations, units, expected hardware settings).
5. Suggested next experiments to reduce uncertainty (noise characterization, fixture validation).

## 13) Code quality constraints
- Modular functions with single responsibilities.
- Consistent function headers and input/output validation.
- Inline comments where decisions are non-obvious.
- Avoid hard-coded user-specific paths.
- Use configuration structs + defaults.
- Graceful errors with actionable messages.

## 14) Output format I want from you
When you respond, provide:
1. **Project tree**.
2. **Complete MATLAB code files** (not pseudocode).
3. **Step-by-step run instructions**.
4. **Example expected outputs/plots**.
5. **Checklist for validating my first real test session**.

If any assumption is uncertain, choose a sensible default and clearly label it.
