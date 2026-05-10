clear; clc;
tic

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(fullfile(projectDir, "scripts", "GeneralFuncs"));
addpath(fullfile(projectDir, "scripts", "NB"));

dataPath = fullfile(projectDir, "data", "processed", "nba_90s_clean.mat");
saveDir = fullfile(projectDir, "data", "processed");

if ~isfile(dataPath)
    error("Ficheiro não encontrado: %s\nCorre primeiro scripts/Prep/prepare_dataset.m", dataPath);
end

load(dataPath, "cleanTable", "statsMatrix", "positionLabels");

[playerTags, tagLimits, statNames] = NBA_generateAllTags(statsMatrix);

rng(1);

n = length(positionLabels);
idx = randperm(n);

trainRatio = 0.8;
nTrain = round(trainRatio * n);

trainIdx = idx(1:nTrain);
testIdx = idx(nTrain+1:end);

trainTags = playerTags(trainIdx);
testTags = playerTags(testIdx);

trainLabels = positionLabels(trainIdx);
testLabels = positionLabels(testIdx);

allTrainTags = [trainTags{:}];
vocabulary = unique(allTrainTags);

vocabMap = containers.Map(cellstr(vocabulary), 1:length(vocabulary));

numDocs = length(trainTags);
numFeatures = length(vocabulary);

BoW = sparse(numDocs, numFeatures);

for doc_i = 1:numDocs

    tags = unique(trainTags{doc_i});

    for tag_i = 1:length(tags)

        tag = char(tags(tag_i));

        if isKey(vocabMap, tag)
            col = vocabMap(tag);
            BoW(doc_i, col) = 1;
        end

    end

end

classes = unique(trainLabels);
numClasses = length(classes);

prior = zeros(1, numClasses);

for c = 1:numClasses
    prior(c) = sum(trainLabels == classes(c)) / length(trainLabels);
end

alpha = 1;
loglikelihood = zeros(numClasses, numFeatures);

for c = 1:numClasses

    rows = trainLabels == classes(c);

    tagCounts = full(sum(BoW(rows, :), 1));
    totalTags = sum(tagCounts);

    probs = (tagCounts + alpha) ./ (totalTags + alpha * numFeatures);

    loglikelihood(c, :) = log(probs);

end

modelPath = fullfile(saveDir, "naiveBayesNBA.mat");

save(modelPath, ...
    "vocabulary", ...
    "loglikelihood", ...
    "prior", ...
    "classes", ...
    "tagLimits", ...
    "statNames", ...
    "testTags", ...
    "testLabels", ...
    "cleanTable", ...
    "statsMatrix", ...
    "positionLabels");

fprintf("Naive Bayes NBA model saved.\n");
fprintf("Classes: ");
disp(classes');

fprintf("Vocabulary size: %d\n", length(vocabulary));
fprintf("Train players: %d\n", length(trainTags));
fprintf("Test players: %d\n", length(testTags));
fprintf("Elapsed time: %.2f seconds\n", toc);