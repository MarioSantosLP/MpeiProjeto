clear
clc
tic

%% LOAD MODEL
scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);

modelPath = fullfile(projectDir, "data", "processed", "naiveBayesGenre.mat");
load(modelPath);

%% BUILD VOCAB MAP (once)
vocabMap = containers.Map(vocabulary, 1:numel(vocabulary));

%% TEST
numLyrics = length(testText);
predictedLabels = strings(numLyrics, 1);

h = waitbar(0, 'Naive Bayes...');

for lyric_i = 1:numLyrics

    predictedLabels(lyric_i) = NB_classify( ...
        testText(lyric_i), ...
        prior, ...
        vocabMap, ...
        loglikelihood, ...
        classes, ...
        minSize, ...
        stopWords);

    if mod(lyric_i, 100) == 0
        waitbar(lyric_i / numLyrics, h);
    end

end

close(h);

%% RESULTS
accuracy = sum(predictedLabels == testLabels) / numLyrics;
fprintf("Accuracy: %.2f%%\n", accuracy * 100);

[confMat, order] = confusionmat(testLabels, predictedLabels);

nClasses = length(order);
precision = zeros(nClasses, 1);
recall    = zeros(nClasses, 1);
f1        = zeros(nClasses, 1);
classAcc  = zeros(nClasses, 1);

for i = 1:nClasses
    TP = confMat(i, i);
    FP = sum(confMat(:, i)) - TP;
    FN = sum(confMat(i, :)) - TP;

    classAcc(i)  = TP / (sum(confMat(i, :)) + eps);
    precision(i) = TP / (TP + FP + eps);
    recall(i)    = TP / (TP + FN + eps);
    f1(i)        = 2 * precision(i) * recall(i) / (precision(i) + recall(i) + eps);
end

classStats = table(string(order), classAcc, precision, recall, f1, ...
    'VariableNames', {'Genre', 'Accuracy', 'Precision', 'Recall', 'F1'});
classStats = sortrows(classStats, "F1", "descend");

disp("=== Per-class metrics ===");
disp(classStats);

fprintf("\n=== Macro Averages ===\n");
fprintf("Macro Precision : %.2f%%\n", mean(precision) * 100);
fprintf("Macro Recall    : %.2f%%\n", mean(recall)    * 100);
fprintf("Macro F1        : %.2f%%\n", mean(f1)        * 100);

disp("=== Confusion Matrix ===");
disp(array2table(confMat, ...
    "RowNames",      cellstr(order), ...
    "VariableNames", matlab.lang.makeValidName(cellstr("pred_" + string(order)))));

%% SAVE RESULTS
savePath = fullfile(projectDir, "data", "processed", "nb_results.mat");

save(savePath, ...
    "predictedLabels", ...
    "testLabels", ...
    "accuracy", ...
    "confMat", ...
    "order");

fprintf("\nResults saved to: %s\n", savePath);

toc