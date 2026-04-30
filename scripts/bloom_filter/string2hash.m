function hash = string2hash(str, type)
    % string2hash
    % Converts a string into a numeric hash value.
    % Two algorithms are supported:
    %   'djb2' - uses multiplier 33, good general purpose hash
    %   'sdbm' - uses multiplier 65599, produces different distribution
    % Both are used together in the Counting Bloom Filter to generate
    % k independent hash positions via: h(i) = (djb2 + i * sdbm) mod m
    %
    % Input:
    %   str  - input string (char or string)
    %   type - hash algorithm: 'djb2' (default) or 'sdbm'
    % Output:
    %   hash - numeric hash value in range [0, 2^32 - 2]

    str = double(char(str));
    if (nargin < 2), type = 'djb2'; end
    switch(type)
        case 'djb2'
            hash = 5381;
            for i = 1:length(str)
                hash = mod(hash * 33 + str(i), 2^32 - 1);
            end
        case 'sdbm'
            hash = 0;
            for i = 1:length(str)
                hash = mod(hash * 65599 + str(i), 2^32 - 1);
            end
        otherwise
            error('string2hash:inputs', 'Unknown hash type. Use ''djb2'' or ''sdbm''.');
    end
end