classdef gen_alg_bin < handle
    %GEN_ALG_BIN Calculate minimum/maximum of a given function with
    % constraints using binary number representation
    properties
        generations
        hist_min
        hist_mean
        hist_max
        prev_pop_in_domain
        penalty_base
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
            obj.prev_pop_in_domain = [];
            obj.penalty_base = NaN;
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

        function [x_opt_dec, fval] = optimize(obj, my_fun, mini, maxi, minimize, precision, plot_ax)
            %OPTIMIZE Run the ga function with plotting
            arguments
                obj
                my_fun (1,1) function_handle
                mini (1,1) double
                maxi (1,1) double
                minimize (1,1) logical
                precision (1,1) double
                plot_ax matlab.ui.control.UIAxes
            end

            obj.validate(mini, maxi)
            
            obj.generations = [];
            obj.hist_min = [];
            obj.hist_mean = [];
            obj.hist_max = [];
            obj.prev_pop_in_domain = [];
            obj.minimize = minimize;
            obj.plot_handle = plot_ax;

            % Set function sign depending on task
            if not(minimize)
                my_fun = @(x) -my_fun(x);
            end

            % Params for ga
            if precision > 0
                val_range = (ceil(maxi) - floor(mini) + 1) * 10^precision;
            else
                val_range = floor(maxi) - floor(mini) + 1;
            end
            nvars = length(dec2bin(val_range));
            my_fun_ga = @(bits) obj.my_fun_bin(my_fun, bits, mini, maxi, precision);

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

            x_opt_dec = mini + x_opt * (2.^(length(x_opt)-1:-1:0))';
            if precision > 0
                x_opt_dec = x_opt_dec / 10^precision;
            end
            fprintf('Found x (argument): %.2f\n', x_opt_dec);
            if minimize
                fprintf('Minimum value: %.2f\n', fval);
            else
                fprintf('Maximum value: %.2f\n', fval);
            end
        end

        function [state, options, optchanged] = ga_output(obj, options, state, flag)
            %GA_OUTPUT Output function for ga; takes values from ga state
            % structure
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
                obj.plotfun_metrics(); 
            end

            if ~isempty(obj.prev_pop_in_domain)
                obj.penalty_base = max(obj.prev_pop_in_domain);
            end
            obj.prev_pop_in_domain = [];
            optchanged = false;
        end

        function plotfun_metrics(obj)
            %PLOTFUN Draw plots from captured ga state structure values
            plot(obj.plot_handle, obj.generations, obj.hist_min, 'b-', 'LineWidth', 1.5)
            hold (obj.plot_handle, 'on')
            plot(obj.plot_handle, obj.generations, obj.hist_mean, 'r-', 'LineWidth', 1.5)
            plot(obj.plot_handle, obj.generations, obj.hist_max, 'g-', 'LineWidth', 1.5)
            hold (obj.plot_handle, 'off')

            title(obj.plot_handle, sprintf('Min: %.2f, Mean: %.2f, Max: %.2f', ...
                obj.hist_min(end), obj.hist_mean(end), obj.hist_max(end)))
            legend(obj.plot_handle, 'Min', 'Mean', 'Max')
            xlabel(obj.plot_handle,'generation number')
            ylabel(obj.plot_handle,'f(x)')

            drawnow
        end

        function y = my_fun_bin(obj, my_fun, bits, mini, maxi, precision)
            %MY_FUN_BIN Calculate function value from a binary input with decimal
            % constraints and a penalty value
            x = bits * (2.^(length(bits)-1:-1:0))';
            x = mini + x;

            if precision > 0
                x = x / 10^precision;
            end

            if x > maxi
                if isempty(obj.prev_pop_in_domain) || isempty(obj.penalty_base) || isnan(obj.penalty_base)
                    y = inf;
                else
                    distance = x - maxi;
                    weight = 10;
                    y = obj.penalty_base + weight * distance^2;
                end
                return
            else
                y = my_fun(x);
                obj.prev_pop_in_domain(end+1) = y;
            end
        end
    end

    methods (Static)
        function validate(mini, maxi)
            if maxi < mini
                fprintf("Minimum domain value is greater than maximum value")
                return
            end
        end
    end
end
