function stats = phase_stability_stats(phase_deg)
%PHASE_STABILITY_STATS Summarize replicate phase stability.
p = phase_deg(:);
stats = struct();
stats.mean_deg = mean(p, 'omitnan');
stats.std_deg = std(p, 'omitnan');
stats.min_deg = min(p);
stats.max_deg = max(p);
stats.n = numel(p);
end
