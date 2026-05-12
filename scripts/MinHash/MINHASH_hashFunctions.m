function hc = MINHASH_hashFunctions(item, R, hf)

    s = char(string(item));
    p = uint64(R.p);
    x = uint64(0);
    base = uint64(257);

    for i = 1:length(s)
        x = mod(x * base + uint64(double(s(i)) + 1), p);
    end

    a = uint64(R.a(hf));
    b = uint64(R.b(hf));

    hc = double(mod(a * x + b, p));

end
