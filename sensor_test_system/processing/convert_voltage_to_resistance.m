function rs_ohm = convert_voltage_to_resistance(sensor_v, vin_v, r_ref_ohm)
%CONVERT_VOLTAGE_TO_RESISTANCE Convert divider Vout to Rsensor.
% Vout = Vin * Rs/(Rref + Rs) => Rs = (Vout*Rref)/(Vin - Vout)

den = (vin_v - sensor_v);
den(abs(den) < eps) = NaN;
rs_ohm = (sensor_v .* r_ref_ohm) ./ den;
end
