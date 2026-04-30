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
        for class_i = 1:length(classes)
            probs(class_i) = probs(class_i) + sum(loglikelihood(class_i, indices));
        end
    end

    [~, bestClass] = max(probs);
    res = classes(bestClass);

end