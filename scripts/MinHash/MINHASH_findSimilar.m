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

    allSimilarities = mean(MH == repmat(MH2, 1, size(MH, 2)), 1);

    allSimilarities(excludeIdx) = -inf;

    similarIdx = find(allSimilarities >= threshold);
    similarities = allSimilarities(similarIdx);

    [similarities, order] = sort(similarities, "descend");
    similarIdx = similarIdx(order);

end