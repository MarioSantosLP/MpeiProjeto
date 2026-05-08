function [res, tags, scores] = NB_classifyPlayer(statsRow, prior, vocabulary, loglikelihood, classes, tagLimits, statNames)

    tags = NBA_statsToTags(statsRow, tagLimits, statNames);

    [res, scores] = NB_classifyTags(tags, prior, vocabulary, loglikelihood, classes);

end