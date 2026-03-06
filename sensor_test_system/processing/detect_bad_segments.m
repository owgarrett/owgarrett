function seg = detect_bad_segments(t_s, signal, cfg)
%DETECT_BAD_SEGMENTS Identify blips/dropouts using derivative and envelope.

x = signal(:) - mean(signal);
dx = [0; diff(x)];
med_abs_dx = median(abs(dx));
thr_dx = cfg.segment.derivative_sigma * max(med_abs_dx, eps);

env = abs(hilbert(x));
env_n = env / max(env + eps);

clean = ~(abs(dx) > thr_dx | env_n < cfg.segment.envelope_floor);

% Remove clean runs shorter than minimum duration (toolbox-free)
min_samples = max(1, round(cfg.segment.min_clean_duration_s / mean(diff(t_s))));
clean = enforce_min_run(clean, min_samples);

seg = struct();
seg.clean_mask = clean;
seg.bad_mask = ~clean;
seg.clean_fraction = mean(clean);
seg.confidence = max(0, min(1, seg.clean_fraction));
end

function mask_out = enforce_min_run(mask_in, min_len)
mask_out = false(size(mask_in));
starts = find(diff([false; mask_in]) == 1);
stops = find(diff([mask_in; false]) == -1);
for k = 1:numel(starts)
    if (stops(k) - starts(k) + 1) >= min_len
        mask_out(starts(k):stops(k)) = true;
    end
end
end
