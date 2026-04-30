clear
clc
tic

%% DATA
scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);

dataPath = fullfile(projectDir, "data", "processed", "songs_dataset.mat");
if ~isfile(dataPath)
    error("Dataset file not found %s \n Run prepare_dataset.m first", dataPath);
end
load(dataPath, "nbText", "nbLabels");

nbText = string(nbText);
nbLabels = string(nbLabels);

%% PARAMETERS
minSize = 3;
minWordFrequency = 15;

% numGenresToUse = 5; % only used if genres are selected automatically
maxSongsPerGenre = 2000; 
trainRatio = 0.8;
useBinary = true; % true = Binary, false = TF-IDF

%% STOP WORDS
stopWords = ["the","and","you","that","was","for","are","with","his","her", ...
             "they","this","have","from","one","had","but","not","what","all", ...
             "were","when","there","can","said","each","she","which","their", ...
             "will","other","about","out","many","then","them","these","some", ...
             "would","into","has","more","two","like","him","how","its","our", ...
             "your","just","now","come","here","know","make","take","could", ...
             "back","than","been","who","did","get","may","way","use","also", ...
             "any","see","day","boy","girl","man","got","let","put","say","too", ...
             "yeah","ooh","ohh","aint","gonna","wanna","gotta","dont","cant", ...
             "para","que","com","uma","por","isso","mais","mas","não","como", ...
             "você","seu","sua","ele","ela","nos","sem","bem","vai","ser"];

%% SELECT DATA

% Hard-coded on purpose for controlled testing.
selectedGenres = ["gospel", "heavy metal", "sertanejo", "country", "j-pop"];

% Automatic version, not being used for now:
% [genres, ~, genreIdx] = unique(nbLabels);
% genreCounts = accumarray(genreIdx, 1);
% genreStats = table(genres, genreCounts, ...
%     'VariableNames', {'Genre', 'SongCount'});
% genreStats = sortrows(genreStats, "SongCount", "descend");
% numGenresToUse = 5;
% selectedGenres = genreStats.Genre(1:min(numGenresToUse, height(genreStats)));

validGenres = ismember(selectedGenres, unique(nbLabels));
fprintf("Géneros encontrados: %d/%d\n", sum(validGenres), length(selectedGenres));

selectedGenres = selectedGenres(validGenres);
numGenresToUse = length(selectedGenres);

if isempty(selectedGenres)
    error("None of the selected genres were found in the dataset.");
end

rng(1)
selectedRowsParts = cell(length(selectedGenres),1) ;

for i = 1:length(selectedGenres)
    rows = find(nbLabels == selectedGenres(i));
    rows = rows(randperm(length(rows)));
    rows = rows(1:min(maxSongsPerGenre, length(rows)));
    selectedRowsParts{i} =rows(:);
end

selectedRows= vertcat(selectedRowsParts{:}); %changed to accumulate in vertcat instead of repeated allocs in loop
lyrics = nbText(selectedRows);
labels = nbLabels(selectedRows);

%% SPLIT DATA
n = numel(lyrics);
splitIdx = randperm(n);

nTrain = round(trainRatio * n);

trainIdx = splitIdx(1:nTrain);
testIdx  = splitIdx(nTrain+1:end);

trainText   = lyrics(trainIdx);
trainLabels = labels(trainIdx);
testText    = lyrics(testIdx);
testLabels  = labels(testIdx);

%% VOCAB
tokenCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');
h = waitbar(0, 'Vocabulary...');

for i = 1:length(trainText)

    lyricTokens = cellstr(split(trainText(i)));
    lyricTokens = lyricTokens(~cellfun('isempty', lyricTokens));

    lyricTokensStr = string(lyricTokens);

    validTokens = strlength(lyricTokensStr) >= minSize & ...
                  ~ismember(lyricTokensStr, stopWords);

    lyricTokens = lyricTokens(validTokens);

    if isempty(lyricTokens)
        continue;
    end

    [uniqueTokens, ~, tokenIdx] = unique(lyricTokens);
    tokenFreq = accumarray(tokenIdx, 1);

    for j = 1:numel(uniqueTokens)

        token = uniqueTokens{j};

        if isKey(tokenCounts, token)
            tokenCounts(token) = tokenCounts(token) + tokenFreq(j);
        else
            tokenCounts(token) = tokenFreq(j);
        end

    end

    if mod(i, 100) == 0
        waitbar(i / length(trainText), h);
    end

end

close(h);

allWords = keys(tokenCounts);
allCounts = cell2mat(values(tokenCounts, allWords));

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
    tokensStr = string(tokens);

    tokens = tokens(cellfun(@(x) strlength(x) >= minSize, tokens) & ...
        ~ismember(tokensStr, stopWords));

    tokens = tokens(isKey(vocabMap, tokens));

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

%% FINAL BOW
h = waitbar(0, 'Representação final...');

if useBinary
    finalBoW = double(BoW > 0);
else
    rowSums = sum(BoW, 2);
    rowSums(rowSums == 0) = 1;
    TF = BoW ./ rowSums;

    df = sum(BoW > 0, 1);
    df(df == 0) = 1;
    IDF = log(numLyrics ./ df);

    finalBoW = TF .* IDF;
end

waitbar(1, h);
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

    wordsInClass = full(sum(finalBoW(classRows, :), 1));
    totalWeight  = sum(wordsInClass);

    likelihood = (wordsInClass + 1) ./ (totalWeight + szVocab);
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
    "useBinary", ...
    "selectedGenres", ...
    "stopWords", ...
    "testText", ...
    "testLabels");

fprintf("\nNaive Bayes model saved.\n");

if useBinary
    modeName = "Binary";
else
    modeName = "TF-IDF";
end

% fprintf("Mode: %s\n", string(useBinary).replace("true","Binary").replace("false","TF-IDF"));
fprintf("Mode: %s\n", modeName);
fprintf("Genres used: %d\n", length(classes));
fprintf("Vocabulary size: %d\n", length(vocabulary));
fprintf("Train songs: %d\n", length(trainText));
fprintf("Test songs: %d\n", length(testText));

toc