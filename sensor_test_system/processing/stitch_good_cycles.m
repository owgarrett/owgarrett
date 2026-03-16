function stitched = stitch_good_cycles(t_s, x, clean_mask)
%STITCH_GOOD_CYCLES Return contiguous clean-only signal vectors.
stitched = struct();
stitched.t_s = t_s(clean_mask);
stitched.x = x(clean_mask);
stitched.n_samples = numel(stitched.t_s);
if stitched.n_samples == 0
    warning('No clean samples found; returning empty stitched signal.');
end
end
