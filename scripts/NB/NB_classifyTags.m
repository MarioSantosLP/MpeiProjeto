function [res, scores] = NB_classifyTags(tags, prior, vocabulary, loglikelihood, classes)

    vocabMap = containers.Map(cellstr(vocabulary), 1:length(vocabulary));

    scores = log(prior);

    tags = unique(string(tags));

    for tag_i = 1:length(tags)

        tag = char(tags(tag_i));

        if isKey(vocabMap, tag)

            feature_i = vocabMap(tag);

            for class_i = 1:length(classes)
                scores(class_i) = scores(class_i) + loglikelihood(class_i, feature_i);
            end

        end

    end

    [~, bestIdx] = max(scores);
    res = classes(bestIdx);

end