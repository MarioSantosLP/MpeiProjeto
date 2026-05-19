classdef BloomFilter


    properties
        array_size   % number of positions in the bit array
        num_hashes   % number of hash functions to use
        bits         % bit array (0 or 1)
        num_elements % number of elements inserted
    end

    methods

        function bf = BloomFilter(array_size, num_hashes)
            bf.array_size   = array_size;
            bf.num_hashes   = num_hashes;
            bf.bits         = zeros(1, array_size, 'uint8');
            bf.num_elements = 0;
        end

        function bf = add(bf, key)
            indices = bf.getIndices(key);
            bf.bits(indices) = 1;
            bf.num_elements  = bf.num_elements + 1;
        end

        function result = exists(bf, key)
            indices = bf.getIndices(key);
            result  = all(bf.bits(indices) == 1);
        end

        function rate = falsePositiveRate(bf)
            k    = bf.num_hashes;
            n    = bf.num_elements;
            m    = bf.array_size;
            rate = (1 - exp(-k * n / m)) ^ k; % Formula slide 62
        end

        function printStats(bf)
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
            % computes the bit array positions for a given key.
            % uses two hash funcs (djb2 + sdbm) 
            h1 = BF_hash(char(key), 'djb2');
            h2 = BF_hash(char(key), 'sdbm');
            indices = zeros(1, bf.num_hashes);
            for i = 1:bf.num_hashes
                indices(i) = mod(h1 + i * h2, bf.array_size) + 1;
            end
        end

    end

end
