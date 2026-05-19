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

modelPath = fullfile(projectDir, "data", "processed", "naiveBayesNBA.mat");
csvPath = fullfile(projectDir, "data", "raw", "current_players_test.csv");

if ~isfile(modelPath)
    error("Model not found. Run scripts/NB/NB_genData.m first.");
end

load(modelPath);

classes = string(classes(:));
numRepeats = 10;
trainRatio = 0.8;


%% TEST 1 - saved test set

fprintf("\n TEST 1: saved train/test split \n");

predictedLabels = strings(length(testTags), 1);

for i = 1:length(testTags)
    predictedLabels(i) = NB_classifyTags( ...
        testTags{i}, ...
        prior, ...
        vocabulary, ...
        loglikelihood, ...
        classes);
end

testLabels = string(testLabels(:));

[metrics1, confMat1] = evaluateResults(testLabels, predictedLabels, classes);

printMetrics(metrics1);
printConfusion(confMat1, classes);

%% TEST 2 - repeated random splits

fprintf("\n\n TEST 2: repeated random splits\n");

allTags = getTagsFromStats(statsMatrix, prior, vocabulary, loglikelihood, classes, tagLimits, statNames);
allLabels = string(cleanTable.Pos);

repeatResults = table();

for r = 1:numRepeats

    [trainIdx, testIdx] = stratifiedSplit(allLabels, classes, trainRatio);

    trainTags = allTags(trainIdx);
    trainLabels = allLabels(trainIdx);

    testTagsRun = allTags(testIdx);
    testLabelsRun = allLabels(testIdx);

    model = trainLocalNB(trainTags, trainLabels, classes);

    predictedRun = strings(length(testTagsRun), 1);

    for i = 1:length(testTagsRun)
        predictedRun(i) = classifyLocalNB(testTagsRun{i}, model);
    end

    [m, ~] = evaluateResults(testLabelsRun, predictedRun, classes);

    newRow = table( ...
        r, ...
        m.accuracy * 100, ...
        m.precision * 100, ...
        m.recall * 100, ...
        m.f1 * 100, ...
        'VariableNames', {'Run','Accuracy','Precision','Recall','F1'} ...
    );

    repeatResults = [repeatResults; newRow];

end

disp(repeatResults);

meanRow = table( ...
    "Mean", ...
    mean(repeatResults.Accuracy), ...
    mean(repeatResults.Precision), ...
    mean(repeatResults.Recall), ...
    mean(repeatResults.F1), ...
    'VariableNames', {'Run','Accuracy','Precision','Recall','F1'} ...
);

stdRow = table( ...
    "Std", ...
    std(repeatResults.Accuracy), ...
    std(repeatResults.Precision), ...
    std(repeatResults.Recall), ...
    std(repeatResults.F1), ...
    'VariableNames', {'Run','Accuracy','Precision','Recall','F1'} ...
);

fprintf("\nRepeated test summary:\n");
disp([meanRow; stdRow]);

%% TEST 3 - era comp

fprintf("\n TEST 3: era comp\n");

eraResults = table();

years90 = cleanTable.Year >= 1990 & cleanTable.Year <= 1999;

if sum(years90) > 0

    tags90 = allTags(years90);
    labels90 = allLabels(years90);

    [trainIdx90, testIdx90] = stratifiedSplit(labels90, classes, trainRatio);

    model90 = trainLocalNB(tags90(trainIdx90), labels90(trainIdx90), classes);

    predicted90 = strings(sum(testIdx90), 1);
    testTags90 = tags90(testIdx90);
    testLabels90 = labels90(testIdx90);

    for i = 1:length(testTags90)
        predicted90(i) = classifyLocalNB(testTags90{i}, model90);
    end

    [metrics90, confMat90] = evaluateResults(testLabels90, predicted90, classes);

    eraResults = [eraResults; makeEraRow("1990s dataset", metrics90, length(testLabels90))];

    fprintf("\n1990s dataset:\n");
    printMetrics(metrics90);
    printConfusion(confMat90, classes);

else
    fprintf("\nNo 1990s players found in cleanTable.\n");
end

if isfile(csvPath)

    T = readtable(csvPath, "TextType", "string");

    currentStats = [
        T.PTS, ...
        T.TRB, ...
        T.AST, ...
        T.STL, ...
        T.BLK, ...
        T.FGpct, ...
        T.P3pct, ...
        T.P3A, ...
        T.P2pct, ...
        T.FTpct
    ];

    currentStats = fillmissing(currentStats, "constant", 0);

    expectedCurrent = string(T.ExpectedPos);
    predictedCurrent = strings(height(T), 1);

    for i = 1:height(T)

        [predictedCurrent(i), ~, ~] = NB_classifyPlayer( ...
            currentStats(i, :), ...
            prior, ...
            vocabulary, ...
            loglikelihood, ...
            classes, ...
            tagLimits, ...
            statNames);

    end

    [metricsCurrent, confMatCurrent] = evaluateResults(expectedCurrent, predictedCurrent, classes);

    eraResults = [eraResults; makeEraRow("Current players CSV", metricsCurrent, height(T))];

    currentResults = table( ...
        T.Player, ...
        expectedCurrent, ...
        predictedCurrent, ...
        expectedCurrent == predictedCurrent, ...
        'VariableNames', {'Player','ExpectedPos','PredictedPos','Correct'} ...
    );

    fprintf("\nCurrent players CSV:\n");
    disp(currentResults);

    printMetrics(metricsCurrent);
    printConfusion(confMatCurrent, classes);

    fprintf("\nWrong current predictions:\n");
    disp(currentResults(~currentResults.Correct, :));

else
    fprintf("\nCurrent players CSV not found: %s\n", csvPath);
end

fprintf("\nEra comparison summary:\n");
disp(eraResults);

fprintf("\nDone in %.2f seconds.\n", toc);

%% functions

function tagsCell = getTagsFromStats(statsMatrix, prior, vocabulary, loglikelihood, classes, tagLimits, statNames)

    tagsCell = cell(size(statsMatrix, 1), 1);

    for i = 1:size(statsMatrix, 1)

        [~, tags, ~] = NB_classifyPlayer( ...
            statsMatrix(i, :), ...
            prior, ...
            vocabulary, ...
            loglikelihood, ...
            classes, ...
            tagLimits, ...
            statNames);

        tagsCell{i} = string(tags(:))';

    end

end

function [trainIdx, testIdx] = stratifiedSplit(labels, classes, trainRatio)

    labels = string(labels(:));
    classes = string(classes(:));

    trainIdx = false(length(labels), 1);
    testIdx = false(length(labels), 1);

    for c = 1:length(classes)

        idx = find(labels == classes(c));
        idx = idx(randperm(length(idx)));

        if length(idx) <= 1
            trainIdx(idx) = true;
            continue;
        end

        nTrain = round(trainRatio * length(idx));
        nTrain = max(1, min(nTrain, length(idx) - 1));

        trainIdx(idx(1:nTrain)) = true;
        testIdx(idx(nTrain + 1:end)) = true;

    end

end

function model = trainLocalNB(tagsCell, labels, classes)

    labels = string(labels(:));
    classes = string(classes(:));

    vocabulary = strings(0, 1);

    for i = 1:length(tagsCell)
        vocabulary = [vocabulary; string(tagsCell{i}(:))];
    end

    vocabulary = unique(vocabulary);
    vocabulary(vocabulary == "") = [];

    numClasses = length(classes);
    numWords = length(vocabulary);

    prior = zeros(numClasses, 1);
    loglikelihood = zeros(numClasses, numWords);

    for c = 1:numClasses

        classIdx = labels == classes(c);
        classTags = tagsCell(classIdx);

        prior(c) = sum(classIdx) / length(labels);

        counts = zeros(1, numWords);
        totalWords = 0;

        for i = 1:length(classTags)

            tags = string(classTags{i}(:));

            for t = 1:length(tags)
                wordIdx = find(vocabulary == tags(t), 1);

                if ~isempty(wordIdx)
                    counts(wordIdx) = counts(wordIdx) + 1;
                    totalWords = totalWords + 1;
                end
            end

        end

        probs = (counts + 1) ./ (totalWords + numWords);
        loglikelihood(c, :) = log(probs);

        if prior(c) == 0
            prior(c) = eps;
        end

    end

    model.classes = classes;
    model.vocabulary = vocabulary;
    model.prior = prior;
    model.loglikelihood = loglikelihood;

end

function predicted = classifyLocalNB(tags, model)

    tags = string(tags(:));
    scores = log(model.prior);

    for c = 1:length(model.classes)

        for i = 1:length(tags)

            wordIdx = find(model.vocabulary == tags(i), 1);

            if ~isempty(wordIdx)
                scores(c) = scores(c) + model.loglikelihood(c, wordIdx);
            end

        end

    end

    [~, bestIdx] = max(scores);
    predicted = model.classes(bestIdx);

end

function [metrics, confMat] = evaluateResults(realLabels, predictedLabels, classes)

    realLabels = string(realLabels(:));
    predictedLabels = string(predictedLabels(:));
    classes = string(classes(:));

    confMat = zeros(length(classes), length(classes));

    for i = 1:length(realLabels)

        realIdx = find(classes == realLabels(i), 1);
        predIdx = find(classes == predictedLabels(i), 1);

        if ~isempty(realIdx) && ~isempty(predIdx)
            confMat(realIdx, predIdx) = confMat(realIdx, predIdx) + 1;
        end

    end

    total = sum(confMat, "all");

    TP = diag(confMat);
    FP = sum(confMat, 1)' - TP;
    FN = sum(confMat, 2) - TP;
    support = sum(confMat, 2);

    precision = safeDivide(TP, TP + FP);
    recall = safeDivide(TP, TP + FN);
    f1 = safeDivide(2 .* precision .* recall, precision + recall);

    metrics.accuracy = sum(TP) / total;
    metrics.precision = sum(precision .* support) / sum(support);
    metrics.recall = sum(recall .* support) / sum(support);
    metrics.f1 = sum(f1 .* support) / sum(support);

end

function result = safeDivide(a, b)

    result = zeros(size(a));
    valid = b ~= 0;
    result(valid) = a(valid) ./ b(valid);

end

function printMetrics(metrics)

    fprintf("\nAccuracy: %.2f%%\n", metrics.accuracy * 100);
    fprintf("Precision: %.2f%%\n", metrics.precision * 100);
    fprintf("Recall: %.2f%%\n", metrics.recall * 100);
    fprintf("F1: %.2f%%\n", metrics.f1 * 100);

end

function printConfusion(confMat, classes)

    rowNames = "Real_" + classes;
    colNames = "Pred_" + classes;

    confTable = array2table(confMat, ...
        'RowNames', cellstr(rowNames), ...
        'VariableNames', cellstr(colNames));

    fprintf("\nConfusion Matrix:\n");
    disp(confTable);

end

function row = makeEraRow(name, metrics, n)

    row = table( ...
        string(name), ...
        n, ...
        metrics.accuracy * 100, ...
        metrics.precision * 100, ...
        metrics.recall * 100, ...
        metrics.f1 * 100, ...
        'VariableNames', {'Era','N','Accuracy','Precision','Recall','F1'} ...
    );

end