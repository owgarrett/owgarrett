function plot_path = create_verification_summary_plot(R, proc_dir)
%CREATE_VERIFICATION_SUMMARY_PLOT Render readable verification summary plots.

fig = figure('Name', 'Verification Summary', 'Color', 'w');
tiledlayout(2,2, 'TileSpacing', 'compact');

if height(R) == 1
    % Single-condition run: emphasize metric values directly.
    nexttile;
    draw_single_metric('Gain', R.gain_mean, '', '');

    nexttile;
    draw_single_phase('Phase', R.phase_mean_deg, R.phase_std_deg);

    nexttile;
    draw_single_metric('Mean SNR', R.snr_mean_db, 'dB', 'higher is better');

    nexttile;
    draw_single_metric('Min Detectable Disp', R.min_detect_disp_um_mean, 'um', 'lower is better');
else
    % Multi-frequency run: trend plots.
    nexttile;
    plot(R.freq_hz, R.gain_mean, '-o', 'LineWidth', 1.4); grid on;
    title('Gain vs Frequency'); xlabel('Hz'); ylabel('Gain');

    nexttile;
    errorbar(R.freq_hz, R.phase_mean_deg, R.phase_std_deg, '-o', 'LineWidth', 1.2); grid on;
    title('Phase vs Frequency'); xlabel('Hz'); ylabel('deg');

    nexttile;
    plot(R.freq_hz, R.snr_mean_db, '-o', 'LineWidth', 1.4); grid on;
    title('Mean SNR vs Frequency'); xlabel('Hz'); ylabel('dB');

    nexttile;
    plot(R.freq_hz, R.min_detect_disp_um_mean, '-o', 'LineWidth', 1.4); grid on;
    title('Min Detectable Disp vs Frequency'); xlabel('Hz'); ylabel('um');
end

plot_path = fullfile(proc_dir, 'verification_summary.png');
saveas(fig, plot_path);
end

function draw_single_metric(name, value, unit, subtitle)
bar(1, value, 0.5); grid on;
xticks(1); xticklabels({'Run'});
ylabel(unit_if(unit));
title(name);
set_reasonable_ylim(value);
text(1, value, sprintf('  %.4g %s', value, unit), 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
if ~isempty(subtitle)
    text(1, mean(ylim), subtitle, 'HorizontalAlignment', 'center', 'FontAngle', 'italic');
end
end

function draw_single_phase(name, mean_val, std_val)
errorbar(1, mean_val, std_val, 'o', 'LineWidth', 1.6, 'MarkerSize', 8); grid on;
xticks(1); xticklabels({'Run'});
ylabel('deg'); title(name);
margin = max([abs(std_val)*3, abs(mean_val)*0.2, 0.5]);
ylim([mean_val - margin, mean_val + margin]);
text(1, mean_val, sprintf('  %.3f ± %.3f deg', mean_val, std_val), 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end

function set_reasonable_ylim(v)
if v >= 0
    ymax = max(v*1.25, 1e-6);
    ylim([0, ymax]);
else
    ymin = min(v*1.25, -1e-6);
    ylim([ymin, 0]);
end
end

function y = unit_if(u)
if isempty(u)
    y = '';
else
    y = u;
end
end
