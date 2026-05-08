function tags = NBA_statsToTags(statsRow, tagLimits, statNames)

    tags = strings(1, length(statNames));

    for i = 1:length(statNames)

        statName = statNames(i);
        limits = tagLimits.(char(statName));
        value = statsRow(i);

        if value <= limits(1)
            level = "low";
        elseif value <= limits(2)
            level = "medium_low";
        elseif value <= limits(3)
            level = "medium_high";
        else
            level = "high";
        end

        tags(i) = statName + "_" + level;

    end

end