function tagLimits = NBA_getTagLimits(~, ~)

    tagLimits = struct();

    tagLimits.points         = [8, 15, 25];
    tagLimits.rebounds       = [3, 6, 9];
    tagLimits.assists        = [2, 4.5, 7];
    tagLimits.steals         = [0.7, 1.2, 1.8];
    tagLimits.blocks         = [0.3, 0.8, 1.5];
    tagLimits.fg             = [43, 47, 51];
    tagLimits.three_point    = [20, 30, 36];
    tagLimits.three_attempts = [0.5, 2, 5];
    tagLimits.two_point      = [44, 48, 52];
    tagLimits.ft             = [65, 75, 82];

end