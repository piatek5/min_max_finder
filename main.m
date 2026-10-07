import gen_alg_bin.*

my_fun = @(x) -0.2 * x^2 + 5.5 * x + 6;
mini = -1;
maxi = 28;
minimize = false;

ga_bin = gen_alg_bin();
ga_bin.set_options('PopulationSize', 5)
ga_bin.optimize(my_fun, mini, maxi, minimize)
