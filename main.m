function y = my_fun_bin(my_fun, bits, mini, val_range)
    x = polyval(bits, 2);
    x = mini + x;
    y = my_fun(x);

    % Penalty for exceeding domain
    if x > val_range
        y = y^2;
        return
    end
end

function state = plotfun(options, state, flag)
    persistent gen hist_min hist_mean hist_max
    
    switch flag
        case 'init'
            % Initializing arrays for plot history
            gen = []; hist_min = []; hist_mean = []; hist_max = [];
    
        case 'iter'
            % Appending new results
            gen(end+1) = state.Generation;
            hist_min(end+1) = min(state.Score) * -1;
            hist_mean(end+1) = mean(state.Score) * -1;
            hist_max(end+1) = max(state.Score) * -1;
    
            % Drawing plots using previous data
            plot(gen, hist_min, 'b-', 'LineWidth', 1.5)
            hold on
            plot(gen, hist_mean, 'r-', 'LineWidth', 1.5)
            plot(gen, hist_max, 'g-', 'LineWidth', 1.5)
            hold off
    
            legend('Min (Best)', 'Mean', 'Max')
    end
end

% Params for function call
my_fun = @(x) -0.2 * x^2 + 5.5 * x + 6;
my_fun = @(x) -my_fun(x);
mini = -1;
maxi = 28;
val_range = maxi - mini + 1;

% Params for ga call
my_fun_ga = @(bits) my_fun_bin(my_fun, bits, mini, val_range);
nvars = length(dec2bin(val_range));
options = optimoptions('ga', ...
    PopulationType='bitstring', ...
    SelectionFcn='selectionroulette', ...
    CrossoverFcn='crossoversinglepoint', ...
    MutationFcn='mutationuniform', ...
    PlotFcn=@plotfun);

% Calling the evolution algorithm
[x_opt, fval_min] = ga( ...
    my_fun_ga, ...
    nvars, ...
    [], [], [], [], [], [], [], [], ...
    options);

% Reversing the final result
fval_max = -fval_min;

fprintf('Znalezione x (argument): %f\n', polyval(x_opt, 2));
fprintf('Wartość maksimum: %f\n', fval_max);
