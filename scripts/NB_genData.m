clear
clc
tic

%% DATA
scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);

dataPath = fullfile(projectDir, "data", "processed", "songs_dataset.mat");
load(dataPath, "nbText", "nbLabels");

nbText = string(nbText);
nbLabels = string(nbLabels);

%% PARAMETERS
minSize = 3;
minWordFrequency = 20;
numGenresToUse = 5;
maxSongsPerGenre = 1000;
trainRatio = 0.8;

%% SELECT DATA
[genres, ~, genreIdx] = unique(nbLabels);
genreCounts = accumarray(genreIdx, 1);

genreStats = table(genres, genreCounts, ...
    'VariableNames', {'Genre', 'SongCount'});

genreStats = sortrows(genreStats, "SongCount", "descend");

selectedGenres = genreStats.Genre(1:min(numGenresToUse, height(genreStats)));

rng(1)
selectedRows = [];

for i = 1:length(selectedGenres)

    rows = find(nbLabels == selectedGenres(i));
    rows = rows(randperm(length(rows)));
    rows = rows(1:min(maxSongsPerGenre, length(rows)));

    selectedRows = [selectedRows; rows(:)];

end

lyrics = nbText(selectedRows);
labels = nbLabels(selectedRows);

%% SPLIT DATA
n = numel(lyrics);
idx = randperm(n);

nTrain = round(trainRatio * n);

trainIdx = idx(1:nTrain);
testIdx = idx(nTrain+1:end);

trainText = lyrics(trainIdx);
trainLabels = labels(trainIdx);

testText = lyrics(testIdx);
testLabels = labels(testIdx);

%% VOCABULARY
wordCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');

h = waitbar(0, 'Vocabulary...');

for lyric_i = 1:length(trainText)

    tokens = cellstr(split(trainText(lyric_i)));
    tokens = tokens(cellfun(@(x) strlength(x) >= minSize, tokens));

    for token_i = 1:length(tokens)

        word = tokens{token_i};

        if isKey(wordCounts, word)
            wordCounts(word) = wordCounts(word) + 1;
        else
            wordCounts(word) = 1;
        end

    end

    if mod(lyric_i, 100) == 0
        waitbar(lyric_i / length(trainText), h);
    end

end

close(h);

allWords = keys(wordCounts);
allCounts = cell2mat(values(wordCounts));

vocabulary = allWords(allCounts >= minWordFrequency);
vocabulary = vocabulary(:);

vocabMap = containers.Map(vocabulary, 1:numel(vocabulary));

szVocab = length(vocabulary);
numLyrics = length(trainText);

%% BOW
BoW = sparse(numLyrics, szVocab);

h = waitbar(0, 'BoW...');

for lyric_i = 1:numLyrics

    tokens = cellstr(split(trainText(lyric_i)));
    tokens = tokens(cellfun(@(x) strlength(x) >= minSize, tokens));

    validTokens = isKey(vocabMap, tokens);
    tokens = tokens(validTokens);

    if isempty(tokens)
        continue
    end

    indices = cell2mat(values(vocabMap, tokens));

    BoW(lyric_i, :) = accumarray(indices(:), 1, [szVocab, 1])';

    if mod(lyric_i, 100) == 0
        waitbar(lyric_i / numLyrics, h);
    end

end

close(h);

%% PRIOR
classes = unique(trainLabels);
prior = zeros(1, length(classes));

for class_i = 1:length(classes)
    prior(class_i) = sum(trainLabels == classes(class_i)) / length(trainLabels);
end

%% LIKELIHOOD
loglikelihood = zeros(length(classes), szVocab);

h = waitbar(0, 'Likelihood...');

for class_i = 1:length(classes)

    classRows = trainLabels == classes(class_i);

    wordsInClass = sum(BoW(classRows, :), 1);
    totalWords = full(sum(wordsInClass));

    likelihood = (wordsInClass + 1) ./ (totalWords + szVocab);

    loglikelihood(class_i, :) = log(likelihood);

    waitbar(class_i / length(classes), h);

end

close(h);

%% SAVE
savePath = fullfile(projectDir, "data", "processed", "naiveBayesGenre.mat");

save(savePath, ...
    "vocabulary", ...
    "loglikelihood", ...
    "prior", ...
    "classes", ...
    "minSize", ...
    "minWordFrequency", ...
    "numGenresToUse", ...
    "maxSongsPerGenre", ...
    "trainRatio", ...
    "selectedGenres", ...
    "testText", ...
    "testLabels");

fprintf("\nNaive Bayes model saved.\n");
fprintf("Genres used: %d\n", length(classes));
fprintf("Vocabulary size: %d\n", length(vocabulary));
fprintf("Train songs: %d\n", length(trainText));
fprintf("Test songs: %d\n", length(testText));

toc