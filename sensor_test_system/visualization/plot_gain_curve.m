function plot_gain_curve(freq_hz, gain)
%PLOT_GAIN_CURVE Plot gain vs frequency.
figure('Name','Gain Curve');
plot(freq_hz, gain, '-o'); grid on; xlabel('Frequency (Hz)'); ylabel('Gain (sensor/accel)');
end
