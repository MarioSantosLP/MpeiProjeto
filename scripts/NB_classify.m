function [res, probs] = NB_classify(lyric, prior, vocabMap, loglikelihood, classes, minSize, stopWords)

    probs = log(prior);

    % Filtrar small tokens and the stop words
     tokens = cellstr(split(string(lyric)));
    tokensStr = string(tokens);
    tokens = tokens(cellfun(@(x) strlength(x) >= minSize, tokens) & ...
        ~ismember(tokensStr, stopWords));

    tokens = tokens(isKey(vocabMap, tokens));

    if ~isempty(tokens)
        indices = cell2mat(values(vocabMap, tokens));
        probs = probs +sum(loglikelihood(:,indices), 2)';
    end

    [~, bestClass] = max(probs);
    res = classes(bestClass);

end