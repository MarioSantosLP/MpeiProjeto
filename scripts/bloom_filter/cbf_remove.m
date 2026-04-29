function cbf=cbf_remove(cbf,key)
    hash_djb2=string2hash(key,'djb2');
    hash_sdbm=string2hash(key,'sdbm');

    for i=1:cbf.num_hashes
        
        index=mod(hash_djb2 + i * hash_sdbm, cbf.array_size) + 1;

        if cbf.counters(index) == 0
            error('Element does not exist in the filter');
        end

        cbf.counters(index) = cbf.counters(index) - 1;
    end

end