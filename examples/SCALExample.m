%% Automated History Matching of SCAL Experiments
%
% DESCRIPTION: Example of how to run a case with the SCAL module
%
% ----------------------------------
% (c) 2020-2022
% Siroos Azizmohammadi
% Omidreza Amrollahinasab
% Montanuniversität Leoben, Austria
% Chair of Reservoir Engineering
% https://dpe.ac.at/
% ----------------------------------
%
%% clear memory, close all figures and screen
clc;
clear all;
close all;
clear classes;

%% configure model from file
% adding mrst modules
mrstModule add ad-core ad-props ad-blackoil ad-scal
% input absolute path to the settings file
model = Configure("C:\Users\omidreza\Documents\GitHub\ad-scal\examples\settings_case4.txt");

%% verbose to display internal messages
verbose = false; 
model.verbose = verbose;

%% discretize geometry
model = CreateGrid(model);

%% create rock model
model = CreateRock(model);

%% create saturation functions model
model = CreatePc(model);
model = CreateKr(model);

%% plot satuartion functions and comparison plots
if not(strcmpi(model.simulation.type,strcat('historymatch')))
    PlotKrPc(model);
    if or(isfield(model.experiment.satfun,'kr_compare'), ...
            isfield(model.experiment.satfun,'pc_compare'))
        PlotKrPcComparison(model)
    end
    % just a pause before you run the simulations to check if you have the
    % correct input relative permeability and capillary pressures for 
    % your simulations - you can also plot them against other kr and pc 
    % curves for comparison purposes
    disp('Check input saturation functions, continue? [enter for yes/control + c to no]');
    pause()
end

%% create fluid model
model = CreateFluid(model);

%% run Froward/Histormatch simulation
if not((strcmpi(model.simulation.type,strcat('historymatch'))))  
% ------------forward homogeneous model-----------------------------------
    fprintf('Simulating the homogeneous model...\n')
    model = Run(model, true);
    disp("Plot saturation profile? [enter for yes/ control + c for no]");
    pause()
    plot_saturation_profile(model)
else
% ------------investigate the input range for------------------------------
%     plot_input_range(model)
%     fprintf('Want to continue? Press Enter to continue \n')
%     pause
%-------------Exploratory data analysis------------------------------------
    filter_no.pressure = 5;
    filter_no.prod = 5;
    filtered_data = PlotObservation_pre_hm(model, filter_no);
    plot_saturation_profile_pre_hm(model)
    choice = input('History match with the filtered data? [y/n]','s');
    if strcmpi(choice, 'y')
        model = replace_observation_with_filtered_data(model, filtered_data);
    end
    close
%--------------------------------------------------------------------------
    fprintf('Starting the history match...\n')
%----------Multi objective history matching ------------------------------
    if strcmpi(model.history_match.algorithm,'ga_multi_objective')
        model = historymatch_multi_obj(model);
        [x_best, fval_sum_best] = get_x_best(model);
        model.history_match.x = x_best;
        model.history_match.fval = fval_sum_best;
    else
%----------single objective history matching ------------------------------
        [model, model_cent] = historymatch(model);
    end
%% plotting after history match
    plot_HM_results(model)
    obj_fun = model.history_match.obj_fun;
    if strcmpi(obj_fun,'simultaneous')
        plot_HM_response(model,'ss')
        model_cent.history_match = model.history_match;
        plot_HM_response(model_cent,'cent')
    else
        plot_HM_response(model,'')
    end
end

%% output results
if not(isempty(model.output))
    if(model.output.include)
        SaveResults(model);
    end
end

%% compute and plot fractional flow
% [sw, fw] = compute_fractional_flow (model);
% plot_fractional_flow(sw, fw);

