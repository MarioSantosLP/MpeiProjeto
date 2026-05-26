clear; clc;

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "raw")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

rawDir = fullfile(projectDir, "data", "raw");
rawPath = fullfile(rawDir, "Seasons_Stats.csv");
if ~isfolder(rawDir)
    error("prepare_dataset:ProjectRootNotFound", ...
        "Could not locate project root containing data/raw. Run this script from within the project repository.");
end
if ~isfile(rawPath)
    error("prepare_dataset:RawDatasetMissing", ...
        "Required raw dataset not found: %s", rawPath);
end
processedDir = fullfile(projectDir, "data", "processed");

if ~exist(processedDir, "dir")
    mkdir(processedDir);
end

startYear = 1985;
endYear = 2000;
minGames = 20;
minMinutesPerGame = 15;

opts = detectImportOptions(rawPath);
opts = setvartype(opts, opts.VariableNames, 'char');

rawTable = readtable(rawPath, opts);

colNames = rawTable.Properties.VariableNames;

iYear   = find(strcmp(colNames, 'Year'),  1);
iPlayer = find(strcmp(colNames, 'Player'),1);
iPos    = find(strcmp(colNames, 'Pos'),   1);
iAge    = find(strcmp(colNames, 'Age'),   1);
iTm     = find(strcmp(colNames, 'Tm'),    1);
iG      = find(strcmp(colNames, 'G'),     1);
iMP     = find(strcmp(colNames, 'MP'),    1);
iPTS    = find(strcmp(colNames, 'PTS'),   1);
iTRB    = find(strcmp(colNames, 'TRB'),   1);
iAST    = find(strcmp(colNames, 'AST'),   1);
iSTL    = find(strcmp(colNames, 'STL'),   1);
iBLK    = find(strcmp(colNames, 'BLK'),   1);
iFGp    = find(strcmp(colNames, 'FG_'),   1);
i3Pp    = find(strcmp(colNames, 'x3P_'),  1);
i3PA    = find(strcmp(colNames, 'x3PA'),  1);
i2Pp    = find(strcmp(colNames, 'x2P_'),  1);
iFTp    = find(strcmp(colNames, 'FT_'),   1);

if any([isempty(iYear), isempty(iPlayer), isempty(iPos), isempty(iAge), ...
        isempty(iTm), isempty(iG), isempty(iMP), isempty(iPTS), isempty(iTRB), ...
        isempty(iAST), isempty(iSTL), isempty(iBLK), isempty(iFGp), ...
        isempty(i3Pp), isempty(i3PA), isempty(i2Pp), isempty(iFTp)])
    error('Erro: uma ou mais colunas necessárias não foram encontradas.');
end

years = str2double(rawTable{:, iYear});
maskYears = (years >= startYear) & (years <= endYear);
data90s = rawTable(maskYears, :);

Year   = str2double(data90s{:, iYear});
Player = string(strtrim(data90s{:, iPlayer}));
Pos    = string(strtrim(data90s{:, iPos}));
Age    = str2double(data90s{:, iAge});
Tm     = string(strtrim(data90s{:, iTm}));
G      = str2double(data90s{:, iG});
MP     = str2double(data90s{:, iMP});
PTS    = str2double(data90s{:, iPTS});
TRB    = str2double(data90s{:, iTRB});
AST    = str2double(data90s{:, iAST});
STL    = str2double(data90s{:, iSTL});
BLK    = str2double(data90s{:, iBLK});
FGp    = str2double(data90s{:, iFGp});
P3p    = str2double(data90s{:, i3Pp});
P3A    = str2double(data90s{:, i3PA});
P2p    = str2double(data90s{:, i2Pp});
FTp    = str2double(data90s{:, iFTp});

Player = erase(Player, "*");

validGames = G >= minGames;

Year   = Year(validGames);
Player = Player(validGames);
Pos    = Pos(validGames);
Age    = Age(validGames);
Tm     = Tm(validGames);
G      = G(validGames);
MP     = MP(validGames);
PTS    = PTS(validGames);
TRB    = TRB(validGames);
AST    = AST(validGames);
STL    = STL(validGames);
BLK    = BLK(validGames);
FGp    = FGp(validGames);
P3p    = P3p(validGames);
P3A    = P3A(validGames);
P2p    = P2p(validGames);
FTp    = FTp(validGames);

isTOT = Tm == "TOT";

tempTable = table(Player, Year, Pos, Age, Tm, G, MP, PTS, TRB, AST, STL, BLK, ...
    FGp, P3p, P3A, P2p, FTp, isTOT);

tempTable = sortrows(tempTable, {'Year','Player','isTOT'}, ...
    {'ascend','ascend','descend'});

key = tempTable.Player + "_" + string(tempTable.Year);
[~, uniqueIdx] = unique(key, 'stable');

tempTable = tempTable(uniqueIdx, :);

Player = tempTable.Player;
Year   = tempTable.Year;
Pos    = tempTable.Pos;
Age    = tempTable.Age;
Tm     = tempTable.Tm;
G      = tempTable.G;
MP     = tempTable.MP;
PTS    = tempTable.PTS;
TRB    = tempTable.TRB;
AST    = tempTable.AST;
STL    = tempTable.STL;
BLK    = tempTable.BLK;
FGp    = tempTable.FGp;
P3p    = tempTable.P3p;
P3A    = tempTable.P3A;
P2p    = tempTable.P2p;
FTp    = tempTable.FTp;

P3p(isnan(P3p)) = 0;
P3A(isnan(P3A)) = 0;

medFGp = median(FGp(~isnan(FGp)));
medP2p = median(P2p(~isnan(P2p)));
medFTp = median(FTp(~isnan(FTp)));

FGp(isnan(FGp)) = medFGp;
P2p(isnan(P2p)) = medP2p;
FTp(isnan(FTp)) = medFTp;

posMap = {
    'G',   'SG';
    'F-G', 'SG';
    'G-F', 'SG';
    'F',   'SF';
    'F-C', 'PF';
    'C-F', 'PF';
};

for i = 1:size(posMap, 1)
    Pos(Pos == string(posMap{i,1})) = string(posMap{i,2});
end

validPos = ismember(Pos, ["PG","SG","SF","PF","C"]);

Year   = Year(validPos);
Player = Player(validPos);
Pos    = Pos(validPos);
Age    = Age(validPos);
Tm     = Tm(validPos);
G      = G(validPos);
MP     = MP(validPos);
PTS    = PTS(validPos);
TRB    = TRB(validPos);
AST    = AST(validPos);
STL    = STL(validPos);
BLK    = BLK(validPos);
FGp    = FGp(validPos);
P3p    = P3p(validPos);
P3A    = P3A(validPos);
P2p    = P2p(validPos);
FTp    = FTp(validPos);

MPG = MP ./ G;
validMinutes = MPG >= minMinutesPerGame;

Year   = Year(validMinutes);
Player = Player(validMinutes);
Pos    = Pos(validMinutes);
Age    = Age(validMinutes);
Tm     = Tm(validMinutes);
G      = G(validMinutes);
MP     = MP(validMinutes);
PTS    = PTS(validMinutes);
TRB    = TRB(validMinutes);
AST    = AST(validMinutes);
STL    = STL(validMinutes);
BLK    = BLK(validMinutes);
FGp    = FGp(validMinutes);
P3p    = P3p(validMinutes);
P3A    = P3A(validMinutes);
P2p    = P2p(validMinutes);
FTp    = FTp(validMinutes);

MPG = round(MP ./ G, 2);

PTS = round(PTS ./ G, 2);
TRB = round(TRB ./ G, 2);
AST = round(AST ./ G, 2);
STL = round(STL ./ G, 2);
BLK = round(BLK ./ G, 2);
P3A = round(P3A ./ G, 2);

FGp = round(FGp * 100, 2);
P3p = round(P3p * 100, 2);
P2p = round(P2p * 100, 2);
FTp = round(FTp * 100, 2);

cleanTable = table(Player, Year, Pos, Age, Tm, G, MPG, PTS, TRB, AST, STL, BLK, ...
    FGp, P3p, P3A, P2p, FTp, ...
    'VariableNames', {'Player','Year','Pos','Age','Tm','G','MPG', ...
                      'PTS','TRB','AST','STL','BLK', ...
                      'FGpct','P3pct','P3A','P2pct','FTpct'});

statsMatrix = [PTS, TRB, AST, STL, BLK, FGp, P3p, P3A, P2p, FTp];
positionLabels = Pos;
bloomKeys = lower(Player + "_" + string(Year));

csvPath = fullfile(processedDir, "nba_90s_clean.csv");
matPath = fullfile(processedDir, "nba_90s_clean.mat");

writetable(cleanTable, csvPath);

save(matPath, ...
    'cleanTable', ...
    'statsMatrix', ...
    'positionLabels', ...
    'bloomKeys', ...
    'startYear', ...
    'endYear', ...
    'minGames', ...
    'minMinutesPerGame');

nRegistos = height(cleanTable);
nJogadoresUnicos = numel(unique(cleanTable.Player));

fprintf('\nRegistos finais: %d\n', nRegistos);
fprintf('Jogadores únicos finais: %d\n', nJogadoresUnicos);
fprintf('CSV guardado em: %s\n', csvPath);
fprintf('MAT guardado em: %s\n', matPath);
fprintf('done\n');