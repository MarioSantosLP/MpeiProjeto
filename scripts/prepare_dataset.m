clear;
clc;

% This script creates:
%   songs       -> full clean table
%   nbText      -> clean lyrics for Naive Bayes
%   nbLabels    -> genres for Naive Bayes
%   bloomKeys   -> artist-title keys for Bloom Filter
%   minhashText -> clean lyrics for MinHash

scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);

lyricsFile = fullfile(projectDir, "data", "raw", "lyrics-data.csv");
artistsFile = fullfile(projectDir, "data", "raw", "artists-data.csv");

processedDir = fullfile(projectDir, "data", "processed");

if ~exist(processedDir, "dir")
    mkdir(processedDir);
end

if ~isfile(lyricsFile)
    error("Missing file: %s", lyricsFile);
end

if ~isfile(artistsFile)
    error("Missing file: %s", artistsFile);
end

optsLyrics = detectImportOptions(lyricsFile, ...
    "Encoding", "UTF-8");

lyricsALinkCol = getVarName(optsLyrics.VariableNames, "ALink");
lyricsSNameCol = getVarName(optsLyrics.VariableNames, "SName");
lyricsLyricCol = getVarName(optsLyrics.VariableNames, "Lyric");

optsLyrics.SelectedVariableNames = {lyricsALinkCol, lyricsSNameCol, lyricsLyricCol};

lyrics = readtable(lyricsFile, optsLyrics);

lyrics.Properties.VariableNames = {'ALink', 'SName', 'Lyric'};

lyrics.ALink = string(lyrics.ALink);
lyrics.SName = string(lyrics.SName);
lyrics.Lyric = string(lyrics.Lyric);

fprintf("Lyrics loaded: %d rows\n", height(lyrics));

optsArtists = detectImportOptions(artistsFile, ...
    "Encoding", "UTF-8");

artistsLinkCol = getVarName(optsArtists.VariableNames, "Link");
artistsArtistCol = getVarName(optsArtists.VariableNames, "Artist");
artistsGenresCol = getVarName(optsArtists.VariableNames, "Genres");

optsArtists.SelectedVariableNames = {artistsLinkCol, artistsArtistCol, artistsGenresCol};

artists = readtable(artistsFile, optsArtists);

artists.Properties.VariableNames = {'Link', 'Artist', 'Genres'};

artists.Link = string(artists.Link);
artists.Artist = string(artists.Artist);
artists.Genres = string(artists.Genres);

fprintf("Artists loaded: %d rows\n", height(artists));

lyrics.ALink = normalizeKey(lyrics.ALink);
artists.Link = normalizeKey(artists.Link);

data = innerjoin(lyrics, artists, ...
    "LeftKeys", "ALink", ...
    "RightKeys", "Link");

fprintf("Rows after join: %d\n", height(data));

songs = table();

songs.songId = (1:height(data))';
songs.title = string(data.SName);
songs.artist = string(data.Artist);
songs.genres = string(data.Genres);
songs.genre = extractMainGenre(songs.genres);
songs.lyric = string(data.Lyric);
songs.artistLink = string(data.ALink);

songs = rmmissing(songs, "DataVariables", ["title", "artist", "genre", "lyric"]);

validRows = ...
    strlength(strtrim(songs.title)) > 0 & ...
    strlength(strtrim(songs.artist)) > 0 & ...
    strlength(strtrim(songs.genre)) > 0 & ...
    strlength(strtrim(songs.lyric)) > 0;

songs = songs(validRows, :);

fprintf("Rows after removing empty values: %d\n", height(songs));

songs.songKey = normalizeText(songs.artist + " - " + songs.title);
songs.lyricClean = normalizeText(songs.lyric);

[~, uniqueIdx] = unique(songs.songKey, "stable");
songs = songs(uniqueIdx, :);

fprintf("Rows after removing duplicates: %d\n", height(songs));

nbText = songs.lyricClean;
nbLabels = string(songs.genre); %fix store as string

bloomKeys = songs.songKey;

minhashText = songs.lyricClean;

save(fullfile(processedDir, "songs_dataset.mat"), ...
    "songs", ...
    "nbText", ...
    "nbLabels", ...
    "bloomKeys", ...
    "minhashText", ...
    "-v7.3");

writetable(songs, fullfile(processedDir, "songs_clean.csv"), ...
    "Encoding", "UTF-8");

fprintf("\nDataset prepared successfully.\n");
fprintf("Final number of songs: %d\n", height(songs));
fprintf("Number of genres: %d\n", numel(unique(nbLabels)));
fprintf("Saved MAT file: %s\n", fullfile(processedDir, "songs_dataset.mat"));
fprintf("Saved CSV file: %s\n", fullfile(processedDir, "songs_clean.csv"));

function name = getVarName(varNames, target)
    idx = strcmpi(varNames, target);

    if ~any(idx)
        disp("Columns found:");
        disp(varNames');
        error("Missing required column: %s", target);
    end

    name = varNames{find(idx, 1)};
end

function out = normalizeKey(text)
    out = string(text);
    out = lower(strtrim(out));
    out = regexprep(out, "\s+", " ");
end

function out = normalizeText(text)
    out = string(text);
    out = lower(out);
    out = regexprep(out, "[^a-zA-Z0-9à-ÿ\s]", " ");
    out = regexprep(out, "\s+", " ");
    out = strtrim(out);
end

function mainGenre = extractMainGenre(genres) %to get only one genre for the naive bayes
    genres = string(genres);
    mainGenre = strings(size(genres));

    for i = 1:length(genres)
        g = genres(i);
        g = erase(g, "[");
        g = erase(g, "]");
        g = erase(g, "'");
        g = erase(g, """");
        g = strtrim(g);

        parts = regexp(g, "[,;/|]", "split");

        if isempty(parts)
            mainGenre(i) = g;
        else
            mainGenre(i) = strtrim(string(parts{1}));
        end
    end

    mainGenre = lower(mainGenre);
end


% The .mat file is saved so we do not need to load and process the large CSV files every time.
% It already contains the cleaned and prepared variables used by the project.
% After running this script once, we can simply use:
%
%   load("data/processed/songs_dataset.mat")
%
% This is faster and easier for Naive Bayes, Bloom Filter and MinHash.