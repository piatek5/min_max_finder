classdef gen_alg_bin < handle
    %GEN_ALG_BIN Calculate minimum/maximum of a given function with
    %constraints using binary number representation
    properties
        generations
        hist_min
        hist_mean
        hist_max
        options
        minimize
    end

    methods
        function obj = gen_alg_bin()
            %GEN_ALG_BIN Construct an instance of this class
            obj.generations = [];
            obj.hist_min = [];
            obj.hist_mean = [];
            obj.hist_max = [];
            obj.minimize = true;
            obj.options = optimoptions('ga', ...
                PopulationType='bitstring', ...
                SelectionFcn='selectionroulette', ...
                CrossoverFcn='crossoversinglepoint', ...
                MutationFcn='mutationuniform', ...
                PlotFcn=@(options, state, flag) obj.plotfun(options, state, flag), ...
                OutputFcn=@(options, state, flag) obj.ga_output(options, state, flag));
        end

        function set_options(obj, varargin)
            obj.options = optimoptions(obj.options, varargin{:});
        end

        function [x_opt_dec, fval] = optimize(obj, my_fun, mini, maxi, minimize)
            %OPTIMIZE Run the ga function with plotting
            arguments
                obj
                my_fun (1,1) function_handle
                mini (1,1) double = intmin
                maxi (1,1) double = intmax
                minimize (1,1) logical = true
            end

            obj.minimize = minimize;

            % Set function sign depending on task
            if not(minimize)
                my_fun = @(x) -my_fun(x);
            end

            % Params for ga
            val_range = maxi - mini + 1;
            nvars = length(dec2bin(val_range));
            my_fun_ga = @(bits) obj.my_fun_bin(my_fun, bits, mini, maxi);

            % Calling the evolution algorithm
            [x_opt, fval_min] = ga( ...
                my_fun_ga, ...
                nvars, ...
                [], [], [], [], [], [], [], [], ...
                obj.options);

            % Reversing the final result
            if not(minimize)
                fval = -fval_min;
            end

            x_opt_dec = mini + polyval(x_opt, 2);
            fprintf('Found x (argument): %f\n', x_opt_dec);
            fprintf('Maximum value: %f\n', fval);
        end

        function [state, options, optchanged] = ga_output(obj, options, state, ~)
            %GA_OUTPUT Output function for ga; takes values from ga state
            %structure
            sign = 1;
            % Set value sign depending on task
            if not(obj.minimize)
                sign = -1;
            end
            obj.generations(end+1) = state.Generation;
            obj.hist_min(end+1) = min(state.Score) * sign;
            obj.hist_mean(end+1) = mean(state.Score) * sign;
            obj.hist_max(end+1) = max(state.Score) * sign;

            optchanged = false;
        end

        function state = plotfun(obj, ~, state, flag)
            %PLOTFUN Draw plots from captured ga state structure values
            if strcmp(flag, 'iter')
                plot(obj.generations, obj.hist_min, 'b-', 'LineWidth', 1.5)
                hold on
                plot(obj.generations, obj.hist_mean, 'r-', 'LineWidth', 1.5)
                plot(obj.generations, obj.hist_max, 'g-', 'LineWidth', 1.5)
                hold off
            
                legend('Min (Best)', 'Mean', 'Max')
            end
        end
    end

    methods (Static)
        function y = my_fun_bin(my_fun, bits, mini, maxi)
        %MY_FUN_BIN Calculate function value from a binary input with decimal
        %constraints and a penalty value
            x = polyval(bits, 2);
            x = mini + x;
            y = my_fun(x);

            % Penalty for exceeding domain
            if x > maxi
                y = y^2;
                return
            end
        end
    end
end