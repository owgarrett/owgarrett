function plot_fft(fft_accel, fft_sensor)
%PLOT_FFT Plot one-sided FFT magnitude for both channels.
figure('Name','FFT');
plot(fft_accel.f_hz, fft_accel.mag, 'DisplayName', 'Accel'); hold on;
plot(fft_sensor.f_hz, fft_sensor.mag, 'DisplayName', 'Sensor');
grid on; xlabel('Frequency (Hz)'); ylabel('Magnitude'); legend('Location','best');
end
