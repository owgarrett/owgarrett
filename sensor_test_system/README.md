# Sensor Test System (MATLAB)

This folder contains a runnable MATLAB framework for NI DAQ acquisition, signal analysis, and quantitative verification outputs.

## Quick start
1. Open MATLAB.
2. `cd` into `sensor_test_system`.
3. Run:
   ```matlab
   addpath(genpath(pwd));
   sensor_test_gui
   ```

## No-hardware test
Run the synthetic end-to-end demo:
```matlab
run('examples/demo_end_to_end.m')
```

## Core entry points
- GUI: `gui/sensor_test_gui.m`
- Acquisition orchestration: `acquisition/run_experiment.m`
- Config defaults: `config/default_config.m`

## Quantitative outputs (auto-generated)
For each session, outputs are written to:
- `data/raw/<sensor_id>/<date>/<session_id>/`
- `data/processed/<sensor_id>/<date>/<session_id>/`
- `data/sessions/<sensor_id>/<date>/<session_id>/`

Key files:
- Raw trial data: `*.csv`
- Per-trial metadata + metrics: `*.json`
- Per-trial quantitative summary: `summary.csv`
- Aggregated validation report: `verification_report.csv`
- Session manifest: `session_manifest.json`

`summary.csv` includes metrics such as:
- clean fraction after blip detection
- SNR at drive tone
- gain and phase
- 60 Hz noise ratio
- displacement amplitude estimate
- sensitivity estimate (`ohm/um`)
- minimum detectable displacement estimate (`3-sigma`, um)
- per-trial PASS/FAIL flag

## Notes
- Uses MATLAB Data Acquisition Toolbox (`daq("ni")`).
- Update `default_config.m` with your hardware channel names and calibration constants.
- PASS/FAIL thresholds are configured in `cfg.vv.*` in `default_config.m`.
