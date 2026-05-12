classdef BloomFilter
    % BloomFilter
    % Probabilistic data structure for fast membership testing.
    % Uses multiple hash functions and a bit array.
    % Supports insertion and membership queries.
    %
    % NOTE: may produce false positives, but never false negatives.
    %   - "definitely not present" -> guaranteed result
    %   - "probably present"       -> may be a false positive

    properties
        array_size   % number of positions in the bit array
        num_hashes   % number of hash functions to use
        bits         % bit array (0 or 1)
        num_elements % number of elements inserted
    end

    methods

        function bf = BloomFilter(array_size, num_hashes)
            % BloomFilter(array_size, num_hashes)
            % Creates a Bloom Filter with array_size bits and num_hashes hash functions.
            %
            % Guidelines for choosing values:
            %   array_size  = ~10x the expected number of elements
            %   num_hashes  = 3 is a good general-purpose value
            bf.array_size   = array_size;
            bf.num_hashes   = num_hashes;
            bf.bits         = zeros(1, array_size, 'uint8');
            bf.num_elements = 0;
        end

        function bf = add(bf, key)
            % add(key)
            % Inserts a key into the filter by setting the bits at the computed positions.
            %
            % Example: bf = bf.add("michael jordan_1991")
            indices = bf.getIndices(key);
            bf.bits(indices) = 1;
            bf.num_elements  = bf.num_elements + 1;
        end

        function result = exists(bf, key)
            % exists(key)
            % Checks whether a key is probably in the filter.
            % Returns false if the key is definitely not present.
            % Returns true if the key is probably present (may be a false positive).
            %
            % Example: bf.exists("michael jordan_1991") -> true/false
            indices = bf.getIndices(key);
            result  = all(bf.bits(indices) == 1);
        end

        function rate = falsePositiveRate(bf)
            % falsePositiveRate()
            % Estimates the false positive rate using the theoretical formula:
            %   (1 - e^(-k*n/m))^k
            % where k = num_hashes, n = num_elements, m = array_size
            k    = bf.num_hashes;
            n    = bf.num_elements;
            m    = bf.array_size;
            rate = (1 - exp(-k * n / m)) ^ k; % Formula from lecture slides, page 62 (MPEI 2025/2026)
        end

        function printStats(bf)
            % printStats()
            % Displays filter statistics: elements inserted,
            % active bits, and estimated false positive rate.
            activeBits = sum(bf.bits);
            fprintf("=== Bloom Filter Stats ===\n");
            fprintf("Array size   : %d bits\n",  bf.array_size);
            fprintf("Num hashes   : %d\n",        bf.num_hashes);
            fprintf("Elements     : %d\n",        bf.num_elements);
            fprintf("Active bits  : %d (%.1f%%)\n", activeBits, activeBits / bf.array_size * 100);
            fprintf("Est. FP rate : %.4f%%\n",    bf.falsePositiveRate() * 100);
        end

    end

    methods (Access = private)

        function indices = getIndices(bf, key)
            % getIndices(key)
            % Computes the bit array positions for a given key.
            % Uses two hash functions (djb2 + sdbm) combined as:
            %   index_i = (djb2 + i * sdbm) mod array_size + 1
            h1 = BF_hash(char(key), 'djb2');
            h2 = BF_hash(char(key), 'sdbm');
            indices = zeros(1, bf.num_hashes);
            for i = 1:bf.num_hashes
                indices(i) = mod(h1 + i * h2, bf.array_size) + 1;
            end
        end

    end

end
