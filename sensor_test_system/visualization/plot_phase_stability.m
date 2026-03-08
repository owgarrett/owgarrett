function plot_phase_stability(phase_deg)
%PLOT_PHASE_STABILITY Histogram and trend of phase values.
figure('Name','Phase Stability');
subplot(1,2,1); histogram(phase_deg); grid on; xlabel('Phase (deg)'); ylabel('Count');
subplot(1,2,2); plot(phase_deg, '-o'); grid on; xlabel('Replicate'); ylabel('Phase (deg)');
end
