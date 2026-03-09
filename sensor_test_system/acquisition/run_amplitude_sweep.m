function out = run_amplitude_sweep(dq, cfg, f0_hz, amps, paths)
%RUN_AMPLITUDE_SWEEP Acquire one run per amplitude.
freqs_hz = f0_hz * ones(size(amps));
out = run_frequency_sweep(dq, cfg, freqs_hz, amps, paths);
end
