function [Index_out,Val_out,out] = getIndexFromVSCresultData(VSCresultsfile,sensor,pval,varargin)
% [Index_out,Val_out,out] = getIndexFromVSCresultData(VSCresultsfile,sensor,pval)
% Function to calculate the quantiles from VSC results data file and write
% out the specified index
%
% Inputs
% - VSCresultsfile is the VSC result file
% - sensor is the sensor of interest or multiple sensors
% - pval is the quantile of interest
%
% Output
% - Index_out associated index to the quantile pval
% - Val_out value for associated index found for the quantile pval
% - out struct with additional information, including indexes and values for
%   the 5%, 20%, 50%, 80%, 95% and 100% quantile
% Example
% VSCresultsfile = h:\Feasibility\Projects\001_NextGen_F0\Investigations\019_LFS-3000_update_F0_VSC_climate_sweep\03_load_results\LoadsDE.txt
% index = getIndexFromVSCresultData(VSCresultsfile,'MxHub_LDD_m=3.3',0.8)
%
% NIWJO Dec 2020

% Disable write to command window doing testing
writeToWindow = ~(~isempty(varargin) && strcmpi(varargin{end},'test'));

% Input handles
if ~iscell(sensor)
    sensor = {sensor};
end

[VSC_results_data] = LAC.vsc.import_VSC_Results_file(VSCresultsfile);
out.p = [5, 20, 50, 80, 95, 100]./100;
for q = 1:length(sensor)
    out.sensorfixed{q} = regexprep(sensor{q},{'=', '\.'},{'', ''});
    if any(strcmp(fieldnames(VSC_results_data.Fatigue),out.sensorfixed{q}))
        if writeToWindow
            fprintf('Fatigue data for sensor %s \n\n',out.sensorfixed{q});
        end
        data = VSC_results_data.Fatigue;
    elseif any(strcmp(fieldnames(VSC_results_data.Extreme),out.sensorfixed{q}))
        if writeToWindow
            fprintf('Extreme data for sensor %s \n\n',out.sensorfixed{q});
        end
        data = VSC_results_data.Extreme;
    else
        error('Sensor not found')
    end
    
    % Writing out quantiles to command window
    
    for i = 1:length(out.p)
        [~,minIdx] = min(abs(data.(out.sensorfixed{q})-LAC.vsc.quantile(data.(out.sensorfixed{q}),out.p(i))));
        out.Index(q,i) = data.IndexName(minIdx);
        out.pVal(q,i) = LAC.vsc.quantile(data.(out.sensorfixed{q}),out.p(i));
        out.Eval(q,i) = data.(out.sensorfixed{q})(out.Index(q,i));
    end
    
    if writeToWindow
        fprintf('%s        %s   %s      %s\n','p','Index','Pval','ExactVal')
        for i = 1:length(out.p)
            fprintf('%4.2f   %4.0f      %6.2f    %6.2f\n',out.p(i),out.Index(q,i),out.pVal(q,i),out.Eval(q,i))
        end
        fprintf('\n');
    end
    
    % Calculating index
    [~,minIdx] = min(abs(data.(out.sensorfixed{q})-LAC.vsc.quantile(data.(out.sensorfixed{q}),pval)));
    Index_out(q) = data.IndexName(minIdx);
    Val_out(q) = data.(out.sensorfixed{q})(Index_out(q));
end
end