classdef CountingBloomFilter
    % CountingBloomFilter
    % A probabilistic data structure that allows fast membership testing.
    % Uses multiple hash functions and a counter array to track elements.
    % Supports insertion, removal, and membership queries.
    % NOTE: may produce false positives, but never false negatives.
    
    properties
        array_size   % number of slots in the counter array
        num_hashes   % number of hash functions to use
        counters     % counter array
    end
    
    methods
        function cbf = CountingBloomFilter(array_size, num_hashes)
            % Constructor
            % Creates a Counting Bloom Filter with array_size slots
            % and num_hashes hash functions
            cbf.array_size = array_size;
            cbf.num_hashes = num_hashes;
            cbf.counters = zeros(1, array_size);
        end
        
        function cbf = add(cbf, key)
            % add(key)
            % Inserts a key into the filter by incrementing
            % the counters at the hashed positions
            hash_djb2 = string2hash(char(key), 'djb2');
            hash_sdbm = string2hash(char(key), 'sdbm');
            for i = 1:cbf.num_hashes
                index = mod(hash_djb2 + i * hash_sdbm, cbf.array_size) + 1;
                cbf.counters(index) = cbf.counters(index) + 1;
            end
        end
        
        function cbf = remove(cbf, key)
            % remove(key)
            % Removes a key from the filter by decrementing
            % the counters at the hashed positions
            % Throws an error if the key does not exist
            hash_djb2 = string2hash(char(key), 'djb2');
            hash_sdbm = string2hash(char(key), 'sdbm');
            for i = 1:cbf.num_hashes
                index = mod(hash_djb2 + i * hash_sdbm, cbf.array_size) + 1;
                if cbf.counters(index) == 0
                    error('Element does not exist in the filter');
                end
                cbf.counters(index) = cbf.counters(index) - 1;
            end
        end
        
        function result = exists(cbf, key)
            % exists(key)
            % Returns true if the key is likely in the filter,
            % false if it is definitely not.
            % IMPORTANT: a true result may be a false positive,
            % but a false result is always certain.
            hash_djb2 = string2hash(char(key), 'djb2');
            hash_sdbm = string2hash(char(key), 'sdbm');
            for i = 1:cbf.num_hashes
                index = mod(hash_djb2 + i * hash_sdbm, cbf.array_size) + 1;
                if cbf.counters(index) == 0
                    result = false;
                    return;
                end
            end
            result = true;
        end
    end
end