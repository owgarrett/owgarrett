function plot_qc_dashboard(qc)
%PLOT_QC_DASHBOARD Display QC status text panel.
figure('Name','QC Dashboard'); axis off;
status = "PASS";
if ~qc.pass
    status = "CHECK WARNINGS";
end
lines = {
    ['Status: ' char(status)]
    sprintf('dt_mean: %.6g s', qc.dt_mean)
    sprintf('dt_std: %.6g s', qc.dt_std)
    sprintf('Irregular timing: %d', qc.irregular_timing)
    sprintf('NaN/Inf present: %d', qc.has_nan_inf)
    sprintf('Clipping: %d', qc.clipping)
    };
text(0.1,0.8, strjoin(lines, '\n'), 'FontName','Courier', 'FontSize', 11);
end
