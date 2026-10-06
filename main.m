function y = my_fun_bin(my_fun, bits, mini, val_range)
    x = polyval(bits, 2);

    if x > val_range
        y = 100000;
        return
    end

    x = mini + x;
    y = my_fun(x);
end

my_fun = @(x) -0.2 * x^2 + 5.5 * x + 6;
my_fun = @(x) -my_fun(x);
mini = -1;
maxi = 28;
val_range = maxi - mini + 1;

my_fun_ga = @(bits) my_fun_bin(my_fun, bits, mini, val_range);
nvars = length(dec2bin(val_range));
options = optimoptions('ga', ...
    PopulationType='bitstring', ...
    SelectionFcn='selectionroulette', ...
    CrossoverFcn='crossoversinglepoint', ...
    MutationFcn='mutationuniform');

[x_opt, fval_min] = ga( ...
    my_fun_ga, ...
    nvars, ...
    [], [], [], [], [], [], [], [], ...
    options);

fval_max = -fval_min;

fprintf('Found x (argument): %f\n', polyval(x_opt, 2));
fprintf('Maximum value: %f\n', fval_max);
