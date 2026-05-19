function MH = MINHASH_genMH(Set, R, showWaitbar)

    if nargin < 3
        showWaitbar = false;
    end

    MH = inf(R.k, length(Set));

    if showWaitbar
        h = waitbar(0, 'MinHash...');
    end

    for row_i = 1:length(Set)

        row = unique(string(Set{row_i}));

        for elem_i = 1:length(row)

            elem = row(elem_i);

            for hf = 1:R.k
                hc = MINHASH_hashFunctions(elem, R, hf);

                if MH(hf, row_i) > hc
                    MH(hf, row_i) = hc;
                end
            end
        end

        if showWaitbar && (mod(row_i, 100) == 0 || row_i == length(Set))
            waitbar(row_i / length(Set), h);
        end
    end

    if showWaitbar
        close(h);
    end

end
