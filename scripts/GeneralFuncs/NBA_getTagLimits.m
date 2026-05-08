function tagLimits = NBA_getTagLimits(statsMatrix, statNames)

    tagLimits = struct();

    for i = 1:length(statNames)

        values = statsMatrix(:, i);
        values = values(~isnan(values));
        values = sort(values);

        n = length(values);

        idxQ1 = max(1, ceil(0.25 * n));
        idxQ2 = max(1, ceil(0.50 * n));
        idxQ3 = max(1, ceil(0.75 * n));

        limits = [values(idxQ1), values(idxQ2), values(idxQ3)];

        tagLimits.(char(statNames(i))) = limits;

    end

end