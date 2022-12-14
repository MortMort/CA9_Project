function[Meas_filtered2,Sim_filtered2] = MetMastNac_Filter(Meas_data,Sim_data,X_sens,X_sens2,X_sens3,WTG)

import LAC.scripts.PowerVerification.auxiliary.Step03.Xbinning

j = 1;
k = 1;
for i = 1:length(Meas_data.data.mean(:,1))
    if 100*abs((Meas_data.data.mean(i, X_sens2) - Meas_data.data.mean(i, X_sens3)) / (Meas_data.data.mean(i, X_sens2))) < WTG.MM_Nacelle_Diff
        Meas_filtered2.data(j, :) = Meas_data.data.mean(i, :);
        Sim_filtered2.data(j, :)  = Sim_data.data.mean(i, :);
        Meas_filtered2.datamax(j, :) = Meas_data.data.max(i, :);
        Sim_filtered2.datamax(j, :)  = Sim_data.data.max(i, :);
        Meas_filtered2.datamin(j, :) = Meas_data.data.min(i, :);
        Sim_filtered2.datamin(j, :)  = Sim_data.data.min(i, :);
        
        j = j + 1;
    else
        Meas_filtered2.data_out(k, :) = Meas_data.data.mean(i, :);
        Sim_filtered2.data_out(k, :)  = Sim_data.data.mean(i, :);
        
        k = k + 1;
    end
end

%   12.2 - Binning

[Meas_filtered2.WSpeed_binning] = Xbinning(Meas_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);
[Sim_filtered2.WSpeed_binning]  = Xbinning(Sim_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);

% Trimming off extra elements to make Sim and Meas have the same indices, remove extra bins [ATRSN]
for i = 1:length(Meas_filtered2.WSpeed_binning.index)
    
    if length(Meas_filtered2.WSpeed_binning.index{i}) >= length(Sim_filtered2.WSpeed_binning.index{i})
        
        DelIdx1 = ismember(Meas_filtered2.WSpeed_binning.index{i},Sim_filtered2.WSpeed_binning.index{i});
        Meas_filtered2.WSpeed_binning.index{i}(find(DelIdx1 ==0)) = [];
        DelIdx2 = ismember(Sim_filtered2.WSpeed_binning.index{i},Meas_filtered2.WSpeed_binning.index{i});
        Sim_filtered2.WSpeed_binning.index{i}(find(DelIdx2 ==0)) = [];
    else
        DelIdx1 = ismember(Sim_filtered2.WSpeed_binning.index{i},Meas_filtered2.WSpeed_binning.index{i});
        Sim_filtered2.WSpeed_binning.index{i}(find(DelIdx1 ==0)) = [];
        DelIdx2 = ismember(Meas_filtered2.WSpeed_binning.index{i},Sim_filtered2.WSpeed_binning.index{i});
        Meas_filtered2.WSpeed_binning.index{i}(find(DelIdx2 ==0)) = [];
        
    end
end

MinLengthFilt2 = min(length(Meas_filtered2.WSpeed_binning.index),length(Sim_filtered2.WSpeed_binning.index));
Meas_filtered2.WSpeed_binning.index = Meas_filtered2.WSpeed_binning.index(1:MinLengthFilt2);
Sim_filtered2.WSpeed_binning.index  = Sim_filtered2.WSpeed_binning.index(1:MinLengthFilt2);
% End of trimming

for j = 1:length(Meas_filtered2.WSpeed_binning.index)
    if isempty(Meas_filtered2.WSpeed_binning.index{j})
        Meas_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Meas_filtered2.data(1, :)));
        Meas_filtered2.WSpeed_binning.max(j, :) = zeros(1, length(Meas_filtered2.datamax(1, :)));
        Meas_filtered2.WSpeed_binning.min(j, :) = zeros(1, length(Meas_filtered2.datamin(1, :)));
        
    elseif length(Meas_filtered2.WSpeed_binning.index{j}) == 1
        Meas_filtered2.WSpeed_binning.mean(j, :) = Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :);
        Meas_filtered2.WSpeed_binning.max(j, :) = Meas_filtered2.datamax(Meas_filtered2.WSpeed_binning.index{j}, :);
        Meas_filtered2.WSpeed_binning.min(j, :) = Meas_filtered2.datamin(Meas_filtered2.WSpeed_binning.index{j}, :);
        
    else
        Meas_filtered2.WSpeed_binning.mean(j, :) = mean(Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :));
        Meas_filtered2.WSpeed_binning.max(j, :) = mean(Meas_filtered2.datamax(Meas_filtered2.WSpeed_binning.index{j}, :));
        Meas_filtered2.WSpeed_binning.min(j, :) = mean(Meas_filtered2.datamin(Meas_filtered2.WSpeed_binning.index{j}, :));
    end
end

for j = 1:length(Sim_filtered2.WSpeed_binning.index)
    if isempty(Sim_filtered2.WSpeed_binning.index{j})
        Sim_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Sim_filtered2.data(1, :)));
        Sim_filtered2.WSpeed_binning.max(j, :) = zeros(1, length(Sim_filtered2.datamax(1, :)));
        Sim_filtered2.WSpeed_binning.min(j, :) = zeros(1, length(Sim_filtered2.datamin(1, :)));
        
    elseif length(Sim_filtered2.WSpeed_binning.index{j}) == 1
        Sim_filtered2.WSpeed_binning.mean(j, :) = Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :);
        Sim_filtered2.WSpeed_binning.max(j, :) = Sim_filtered2.datamax(Sim_filtered2.WSpeed_binning.index{j}, :);
        Sim_filtered2.WSpeed_binning.min(j, :) = Sim_filtered2.datamin(Sim_filtered2.WSpeed_binning.index{j}, :);
        
    else
        Sim_filtered2.WSpeed_binning.mean(j, :) = mean(Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :));
        Sim_filtered2.WSpeed_binning.max(j, :) = mean(Sim_filtered2.datamax(Sim_filtered2.WSpeed_binning.index{j}, :));
        Sim_filtered2.WSpeed_binning.min(j, :) = mean(Sim_filtered2.datamin(Sim_filtered2.WSpeed_binning.index{j}, :));
    end
end