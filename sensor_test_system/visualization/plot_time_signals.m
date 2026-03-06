function plot_time_signals(t_s, accel_v, sensor_v)
%PLOT_TIME_SIGNALS Plot accelerometer and sensor voltage vs time.
figure('Name','Time Signals');
subplot(2,1,1); plot(t_s, accel_v); grid on; ylabel('Accel (V)');
subplot(2,1,2); plot(t_s, sensor_v); grid on; ylabel('Sensor (V)'); xlabel('Time (s)');
end
