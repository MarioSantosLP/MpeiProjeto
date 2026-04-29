function cbf=cbf_add(cbf,key)
    hash_djb2=string2hash(key,'djb2');
    hash_sdbm=string2hash(key,'sdbm');

    for i=1:cbf.num_hashes
        index=mod(hash_djb2 + i * hash_sdbm, cbf.array_size) + 1;
        cbf.counters(index)=cbf.counters(index) + 1;
    end
end