function IdlingStabilityAssessment_Step03_Report(TurbineID, TI_range)
    fprintf('Running Step 3 of the Idling Stability Assessment script .. \n\n');
    
    addpath([pwd '\auxiliary\']);
    wr = wordreport;

    figs = dir([pwd, '\', TurbineID, '\Output_Figures\*.fig']);
    for i = 1:length(figs)
       fig_names{i, 1} = figs(i).name; 
    end
    
%   Critical Yaw Error plots
    for iTI = 1:length(TI_range)
        wr.addtext(['STANDSTILL PROFILE, TI = ', num2str(100 * TI_range(iTI)), ' %'], [0 1]);
        fig = strfind(fig_names, ['SS', num2str(100 * TI_range(iTI)), '_Critical']);
        iFig = not(cellfun('isempty', fig));
        
        name = strcat(pwd, '\', TurbineID, '\Output_Figures\', fig_names(iFig));
        a = openfig(name{:}); 
        set(a, 'Renderer', 'painters')
        wr.addfigure();
        close;
    end

%   Bending Moment vs Wind Direction
    for iTI = 1:length(TI_range)
        wr.addtext(['STANDSTILL PROFILE, TI = ', num2str(100 * TI_range(iTI)), ' %'], [0 1]);
        fig = strfind(fig_names, ['SS', num2str(100 * TI_range(iTI)), '_BendingMoment_vs_YawError']);
        iFig = not(cellfun('isempty', fig));
        
        name = strcat(pwd, '\', TurbineID, '\Output_Figures\', fig_names(iFig));
        a = openfig(name{:}); 
        set(a, 'Renderer', 'painters')
        wr.addfigure();
        close;
    end    
    
    fprintf('Step 3 finished. Save the MS Word report!\n');
end
