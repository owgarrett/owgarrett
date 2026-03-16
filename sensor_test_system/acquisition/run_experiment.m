function outputs = run_experiment(cfg, mode)
%RUN_EXPERIMENT Entry point for acquisition modes.
if nargin < 2
    mode = "single";
end

paths = path_helpers(cfg);
dq = daq_setup(cfg);

switch string(mode)
    case "single"
        outputs = run_deep_dive(dq, cfg, cfg.freqs_hz(1), cfg.amps(1), 1, paths);
    case "frequency_sweep"
        outputs = run_frequency_sweep(dq, cfg, cfg.freqs_hz, cfg.amps(1), paths);
    case "amplitude_sweep"
        outputs = run_amplitude_sweep(dq, cfg, cfg.freqs_hz(1), cfg.amps, paths);
    case "deep_dive"
        outputs = run_deep_dive(dq, cfg, cfg.freqs_hz(1), cfg.amps(1), cfg.deep_dive_reps, paths);
    otherwise
        error('Unknown mode: %s', mode);
end
end
