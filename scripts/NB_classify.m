function [res, probs] = NB_classify(lyric, prior, vocabulary, loglikelihood, classes, minSize)

    vocabMap = containers.Map(vocabulary, 1:numel(vocabulary));

    probs = log(prior);

    tokens = cellstr(split(string(lyric)));
    tokens = tokens(cellfun(@(x) length(x) >= minSize, tokens));

    validTokens = isKey(vocabMap, tokens);
    tokens = tokens(validTokens);

    if ~isempty(tokens)

        indices = cell2mat(values(vocabMap, tokens));

        for class_i = 1:length(classes)
            probs(class_i) = probs(class_i) + sum(loglikelihood(class_i, indices));
        end

    end

    [~, bestClass] = max(probs);
    res = classes(bestClass);

end