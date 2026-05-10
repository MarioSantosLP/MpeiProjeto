function [similarIdx, similarities] = MINHASH_findSimilar(itemTags, MH, threshold, R, excludeIdx)

    if nargin < 5
        excludeIdx = [];
    end

    if nargin < 3 || isempty(threshold)
        threshold = 0.6;
    end

    itemTags = unique(string(itemTags));

    if isempty(itemTags)
        error("Não existem tags suficientes para calcular similaridade.");
    end

    MH2 = MINHASH_genMH({itemTags}, R, false);
    allSimilarities = zeros(1, size(MH, 2));

    for column_i = 1:size(MH, 2)
        allSimilarities(column_i) = sum(MH2(:) == MH(:, column_i)) / R.k;
    end

    allSimilarities(excludeIdx) = -inf;

    similarIdx = find(allSimilarities >= threshold);
    similarities = allSimilarities(similarIdx);

    [similarities, order] = sort(similarities, "descend");
    similarIdx = similarIdx(order);

end
