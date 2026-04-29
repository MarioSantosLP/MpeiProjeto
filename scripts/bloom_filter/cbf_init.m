function cbf=initialize(array_size, num_hashes)
    cbf.array_size=array_size;
    cbf.num_hashes=num_hashes;
    cbf.counters=zeros(1,array_size);
end
