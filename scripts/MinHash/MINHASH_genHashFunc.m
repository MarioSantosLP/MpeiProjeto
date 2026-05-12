function R = MINHASH_genHashFunc(k)

    p = 10000019;

    R = struct();
    R.a = randi([1 p - 1], k, 1);
    R.b = randi([0 p - 1], k, 1);
    R.p = p;
    R.k = k;

end
