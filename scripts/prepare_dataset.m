clear; clc;



startYear = 1988;
endYear   = 1995;
minGames  = 20;


opts = detectImportOptions('Seasons_Stats.csv');
opts = setvartype(opts, opts.VariableNames, 'char');
rawTable = readtable('Seasons_Stats.csv', opts);


%apanhar as cols necessarias
colNames = rawTable.Properties.VariableNames;

iYear   = find(strcmp(colNames, 'Year'),  1);
iPlayer = find(strcmp(colNames, 'Player'),1);
iPos    = find(strcmp(colNames, 'Pos'),   1);
iAge    = find(strcmp(colNames, 'Age'),   1);
iTm     = find(strcmp(colNames, 'Tm'),    1);
iG      = find(strcmp(colNames, 'G'),     1);
iPTS    = find(strcmp(colNames, 'PTS'),   1);
iTRB    = find(strcmp(colNames, 'TRB'),   1);
iAST    = find(strcmp(colNames, 'AST'),   1);
iSTL    = find(strcmp(colNames, 'STL'),   1);
iBLK    = find(strcmp(colNames, 'BLK'),   1);
iFGp    = find(strcmp(colNames, 'FG_'),   1);
i3Pp    = find(strcmp(colNames, 'x3P_'), 1);
i2Pp    = find(strcmp(colNames, 'x2P_'), 1);
iFTp    = find(strcmp(colNames, 'FT_'),   1);

if any([isempty(iYear), isempty(iPlayer), isempty(iPos), isempty(iAge), ...
        isempty(iTm), isempty(iG), isempty(iPTS), isempty(iTRB), ...
        isempty(iAST), isempty(iSTL), isempty(iBLK), isempty(iFGp), ...
        isempty(i3Pp), isempty(i2Pp), isempty(iFTp)])
    error('Erro: uma ou mais colunas necessárias não foram encontradas.');
end


years     = str2double(rawTable{:, iYear});
maskYears = (years >= startYear) & (years <= endYear);
data90s   = rawTable(maskYears, :);

%converter tudo
Year   = str2double(data90s{:, iYear});
Player = string(strtrim(data90s{:, iPlayer}));
Pos    = string(strtrim(data90s{:, iPos}));
Age    = str2double(data90s{:, iAge});
Tm     = string(strtrim(data90s{:, iTm}));
G      = str2double(data90s{:, iG});
PTS    = str2double(data90s{:, iPTS});
TRB    = str2double(data90s{:, iTRB});
AST    = str2double(data90s{:, iAST});
STL    = str2double(data90s{:, iSTL});
BLK    = str2double(data90s{:, iBLK});
FGp    = str2double(data90s{:, iFGp});
P3p    = str2double(data90s{:, i3Pp});
P2p    = str2double(data90s{:, i2Pp});
FTp    = str2double(data90s{:, iFTp});

Player = erase(Player, "*");

%filtrar por min jogos
validGames = G >= minGames;
Year   = Year(validGames);   Player = Player(validGames);
Pos    = Pos(validGames);    Age    = Age(validGames);
Tm     = Tm(validGames);     G      = G(validGames);
PTS    = PTS(validGames);    TRB    = TRB(validGames);
AST    = AST(validGames);    STL    = STL(validGames);
BLK    = BLK(validGames);    FGp    = FGp(validGames);
P3p    = P3p(validGames);    P2p    = P2p(validGames);
FTp    = FTp(validGames);


% Jogadores que jogaram em vários clubes têm uma linha com Tm="TOT" (totais)
% e linhas individuais por clube. Ficamos sempre com a linha TOT. 
isTOT = Tm == "TOT";
tempTable = table(Player, Year, Pos, Age, Tm, G, PTS, TRB, AST, STL, BLK, ...
    FGp, P3p, P2p, FTp, isTOT);
tempTable = sortrows(tempTable, {'Year','Player','isTOT'}, {'ascend','ascend','descend'});
key = tempTable.Player + "_" + string(tempTable.Year);
[~, uniqueIdx] = unique(key, 'stable');
tempTable = tempTable(uniqueIdx, :);

Player = tempTable.Player;  Year = tempTable.Year;
Pos    = tempTable.Pos;     Age  = tempTable.Age;
Tm     = tempTable.Tm;      G    = tempTable.G;
PTS    = tempTable.PTS;     TRB  = tempTable.TRB;
AST    = tempTable.AST;     STL  = tempTable.STL;
BLK    = tempTable.BLK;     FGp  = tempTable.FGp;
P3p    = tempTable.P3p;     P2p  = tempTable.P2p;
FTp    = tempTable.FTp;


P3p(isnan(P3p)) = 0;
medFGp = median(FGp(~isnan(FGp)));
medP2p = median(P2p(~isnan(P2p)));
medFTp = median(FTp(~isnan(FTp)));
FGp(isnan(FGp)) = medFGp;
P2p(isnan(P2p)) = medP2p;
FTp(isnan(FTp)) = medFTp;




%mapear as pos antigas
posMap = {
    'G',   'SG';
    'F-G', 'SG';
    'F',   'SF';
    'F-C', 'PF';
};

for i = 1:size(posMap, 1)
    Pos(Pos == posMap{i,1}) = string(posMap{i,2});
end

validPos = ismember(Pos, ["PG","SG","SF","PF","C"]);
Year   = Year(validPos);   Player = Player(validPos);
Pos    = Pos(validPos);    Age    = Age(validPos);
Tm     = Tm(validPos);     G      = G(validPos);
PTS    = PTS(validPos);    TRB    = TRB(validPos);
AST    = AST(validPos);    STL    = STL(validPos);
BLK    = BLK(validPos);    FGp    = FGp(validPos);
P3p    = P3p(validPos);    P2p    = P2p(validPos);
FTp    = FTp(validPos);
fprintf('    Após limpeza de posições: %d registos\n', length(Player));

PTS = round(PTS ./ G, 2);
TRB = round(TRB ./ G, 2);
AST = round(AST ./ G, 2);
STL = round(STL ./ G, 2);
BLK = round(BLK ./ G, 2);

%para a app final queremos usar numeros inteiros 
FGp = round(FGp * 100, 2);
P3p = round(P3p * 100, 2);
P2p = round(P2p * 100, 2);
FTp = round(FTp * 100, 2);


cleanTable = table(Player, Year, Pos, Age, Tm, PTS, TRB, AST, STL, BLK, ...
    FGp, P3p, P2p, FTp, ...
    'VariableNames', {'Player','Year','Pos','Age','Tm', ...
                      'PTS','TRB','AST','STL','BLK', ...
                      'FGpct','P3pct','P2pct','FTpct'});

writetable(cleanTable, 'nba_90s_clean.csv');

statsMatrix    = [PTS, TRB, AST, STL, BLK, FGp, P3p, P2p, FTp];
positionLabels = Pos;
bloomKeys      = lower(Player + "_" + string(Year) + "_" + Tm);

save('nba_90s_clean.mat', ...
    'cleanTable', 'statsMatrix', 'positionLabels', 'bloomKeys', ...
    'startYear', 'endYear', 'minGames');

