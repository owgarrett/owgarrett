# Sensor Test System (MATLAB)

This project provides NI DAQ acquisition + automated verification outputs focused on plots and concise CSV tables.

## Quick start
1. Open MATLAB.
2. `cd` into `sensor_test_system`.
3. Run:
   ```matlab
   addpath(genpath(pwd));
   sensor_test_gui
   ```

## What gets auto-generated after each run
Session outputs are written to:
- `data/raw/<sensor_id>/<date>/<session_id>/`
- `data/processed/<sensor_id>/<date>/<session_id>/`

### Raw data
- `*.csv` files with `time_s`, `accel_v`, `sensor_v`.

### Processed + verification outputs
- `summary.csv` (per-trial metrics)
- `verification_report.csv` (aggregate by frequency)
- `verification_summary.png` (clean, presentation-ready gain/phase/SNR/min-detect summary plots)
- `<trial>_overlay.png` (sensor+accelerometer normalized overlay, zoomed to ~2 cycles, filtered and clean-only)
- `<trial>_fft.png` (FFT raw vs clean+filtered)
- `<trial>_trial_results.csv` (single-trial concise results table)

## Key metrics
- clean fraction after blip removal
- SNR at drive tone
- gain and phase (from clean filtered sinusoidal segments)
- 60 Hz noise ratio
- displacement amplitude estimate
- sensitivity (`ohm/um`)
- minimum detectable displacement estimate (`3-sigma`, `um`)
- per-trial PASS/FAIL

## Notes
- JSON output files were intentionally removed from acquisition outputs.
- PASS/FAIL thresholds are configured in `config/default_config.m` (`cfg.vv.*`).


- Amp list values are interpreted as direct function-generator Vpp setpoints (e.g., `[1 2 4 8 12 16 20]`).
