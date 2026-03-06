# Sensor Test System (MATLAB)

This folder contains a runnable MATLAB framework for NI DAQ acquisition and signal analysis.

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

## Notes
- Uses MATLAB Data Acquisition Toolbox (`daq("ni")`).
- Update `default_config.m` with your hardware channel names and calibration constants.
- Data is written to `sensor_test_system/data/` with session-based folders.
