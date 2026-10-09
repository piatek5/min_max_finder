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
        plot_handle
    end

    methods
        function obj = gen_alg_bin()
            %GEN_ALG_BIN Construct an instance of this class
            obj.generations = [];
            obj.hist_min = [];
            obj.hist_mean = [];
            obj.hist_max = [];
            obj.minimize = true;
            obj.plot_handle = [];
            obj.options = optimoptions('ga', ...
                SelectionFcn='selectionroulette', ...
                CrossoverFcn='crossoversinglepoint', ...
                MutationFcn='mutationuniform', ...
                PopulationType='bitstring', ...
                OutputFcn=@(options, state, flag) obj.ga_output(options, state, flag));
        end

        function set_options(obj, varargin)
            obj.options = optimoptions(obj.options, varargin{:});
        end

        function [x_opt_dec, fval] = optimize(obj, my_fun, mini, maxi, minimize, plot_ax)
            %OPTIMIZE Run the ga function with plotting
            arguments
                obj
                my_fun (1,1) function_handle
                mini (1,1) double
                maxi (1,1) double
                minimize (1,1) logical
                plot_ax matlab.ui.control.UIAxes
            end

            obj.validate(mini, maxi, my_fun)
            
            obj.generations = [];
            obj.hist_min = [];
            obj.hist_mean = [];
            obj.hist_max = [];
            obj.minimize = minimize;
            obj.plot_handle = plot_ax;

            % Set function sign depending on task
            if not(minimize)
                my_fun = @(x) -my_fun(x);
            end

            % Params for ga
            if mini > maxi
                [mini, maxi] = deal(maxi, mini);
            end
            val_range = maxi - mini + 1;
            nvars = length(dec2bin(val_range));
            my_fun_ga = @(bits) obj.my_fun_bin(my_fun, bits, mini, maxi);

            % Calling the genetic algorithm
            [x_opt, fval] = ga( ...
                my_fun_ga, ...
                nvars, ...
                [], [], [], [], [], [], [], [], ...
                obj.options);

            % Reversing final result
            if not(minimize)
                fval = -fval;
            end

            x_opt_dec = mini + polyval(x_opt, 2);
            fprintf('Found x (argument): %.2f\n', x_opt_dec);
            if minimize
                fprintf('Minimum value: %.2f\n', fval);
            else
                fprintf('Maximum value: %.2f\n', fval);
            end
        end

        function [state, options, optchanged] = ga_output(obj, options, state, flag)
            %GA_OUTPUT Output function for ga; takes values from ga state
            %structure
            v_sign = 1;
            % Set value sign depending on task
            if not(obj.minimize)
                v_sign = -1;
            end
            obj.generations(end+1) = state.Generation;
            obj.hist_min(end+1) = min(state.Score .* v_sign) ;
            obj.hist_mean(end+1) = mean(state.Score.* v_sign);
            obj.hist_max(end+1) = max(state.Score.* v_sign);

            % Plotting previous data
            if strcmp(flag, 'iter')
                obj.plotfun(); 
            end

            optchanged = false;
        end

        function plotfun(obj)
            %PLOTFUN Draw plots from captured ga state structure values
            plot(obj.plot_handle, obj.generations, obj.hist_min, 'b-', 'LineWidth', 1.5)
            hold (obj.plot_handle, 'on')
            plot(obj.plot_handle, obj.generations, obj.hist_mean, 'r-', 'LineWidth', 1.5)
            plot(obj.plot_handle, obj.generations, obj.hist_max, 'g-', 'LineWidth', 1.5)
            hold (obj.plot_handle, 'off')

            title(obj.plot_handle, sprintf('Min: %.2f, Mean: %.2f, Max: %.2f', ...
                obj.hist_min(end), obj.hist_mean(end), obj.hist_max(end)))
        
            legend(obj.plot_handle, 'Min', 'Mean', 'Max')
            drawnow
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
                y = 1e12 * (1 + (x - maxi)^2);
                return
            end
        end

        function validate(mini, maxi, func_str)
            % min/max domain
            if maxi < mini
                fprintf("Minimum domain value is greater than maximum value")
                return
            end
            % function
            try
                current_func = str2func(func_str);
                test_val = current_func(0);
            catch exception
                fprintf("Function: " + exception.message);
                return
            end
        end
    end
end
