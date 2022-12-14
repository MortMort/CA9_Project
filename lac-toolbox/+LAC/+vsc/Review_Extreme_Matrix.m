function Review_Extreme_Matrix(S,dlc_str,sensor_str,save_output_to,name_prefix)
%plot sensors from extreme load matrix (interpolation surface),
%takes data from 'ReferenceLoads' section in VSC xml file

%to-do:
%display surfaces, instead of just data scatter;
%load more data at once (e.g. more sensors, load cases) and allow drop-down selection;
%allow filtering by other (computed) parameters, e.g. Iref;
%include display of data linear and 2nd order fits to estimate interp/extrapolation;
%include display of data from 'DesignLoad' and 'ApprovedDesignLoad';
%restructure code as class

%inputs:
% S - struct with converted VSC xml, through use of 'LAC.codec.xml2struct()';
% dlc_str - filtering for extreme load cases: '13' '15' '21' '23' '32' '42'
%   '61' '62', or even e.g. '62E50a050';
% sensor_str - sensors to plot, any of: 'MxBld_0000' 'MxBld_0250' 'MxBld_0500' 'MxBld_0750'
%   'MyBld_0000' 'MyBld_0250' 'MyBld_0500' 'MyBld_0750' 'MxHub' 'MyHub'
%   'MPitch' 'FyMBRot' 'MyMBRot' 'MxMBFix' 'MzMBFix' 'MxTwrTop' 'MzTwrTop'
%   'MyMBRot' 'MxMBRot' 'MzMBRot' 'MrMB' 'MxMBFix' 'MzMBFix' 'FyMBRot'
%   'MrTwrTop' 'MrTwrBot' 'MrTwrBot_Fnd' 'bldefl';
% save_output_to - path to output folder;
% name_prefix - prefix added to file name of saved figures;

%%


%some logic on how to cycle through load cases and parameters and call main function
% parameters you may choose:
% for all cases: 'WindShear' 'WindGradient' 'TurbulenceIntensity'
% for DLC62: 'TurbulenceIntensity' 'WindSpeed'
for i = 1:length(dlc_str)
    for j = 1:length(sensor_str)
        if strfind(dlc_str{i},'62')
            Extreme_MatrixOverview2(S,dlc_str{i},'TurbulenceIntensity','WindSpeed',sensor_str{j},save_output_to,name_prefix)
        else
            Extreme_MatrixOverview2(S,dlc_str{i},'TurbulenceIntensity','WindShear',sensor_str{j},save_output_to,name_prefix)
        end
    end
end

close all

end
%%
function Extreme_MatrixOverview2(S,dlc_str,param1,param2,sensor_str,save_output_to,name_prefix)
%extract all load case names
for i = 1:length(S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase)
    load_cases{i,1} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Attributes.value;
end
%filter for load cases you need
find_dlc_str = strfind(cellfun(@(x) x(1:min(length(x),length(dlc_str))),load_cases,'UniformOutput',0),dlc_str);

%%
%for each sensor, which methods are available: max, min, abs
sensor_methods = ...
    {'MxBld_0000' 1 1 0
    'MxBld_0250' 1 1 0
    'MxBld_0500' 1 1 0
    'MxBld_0750' 1 1 0
    'MyBld_0000' 1 1 0
    'MyBld_0250' 1 1 0
    'MyBld_0500' 1 1 0
    'MyBld_0750' 1 1 0
    'MxHub' 0 0 1
    'MyHub' 0 0 1
    'MPitch' 1 1 0
    'FyM\wRot' 1 1 0 %regular expression, to account for both MB and MS
    'MxM\wRot' 0 0 1
    'MyM\wRot' 1 1 0
    'MzM\wRot' 0 0 1
    'MxM\wFix' 0 0 1
    'MzM\wFix' 0 0 1
    'MrM\w' 1 0 0
    'MxTwrTop' 0 0 1
    'MzTwrTop' 0 0 1
    'MrTwrTop' 0 0 1
    'MrTwrBot' 0 0 1
    'MrTwrBot_Fnd' 0 0 1
    'bldefl' 1 0 0};

%find the sensor you want, write logical matrix
aux_find = cell2mat(cellfun(@(x) ~isempty(regexp(sensor_str,x,'ONCE')),sensor_methods(:,1),'UniformOutput',false));

%extract loads
k=1; l=1; m=1;
for i = 1:length(S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase)
    %only extract for filtered DLC
    if find_dlc_str{i}
        %if the method is defined for this sensor, extract max load
        if sensor_methods{aux_find,2}
            for j = 1:length(S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 1}.DesignClimate)
                loads_max{k,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 1}.DesignClimate{1, j}.Attributes.(sensor_str);
                parameters11{k,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 1}.DesignClimate{1, j}.Attributes.(param1);
                parameters21{k,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 1}.DesignClimate{1, j}.Attributes.(param2);
            end
            k = k+1;
        end
        %if the method is defined for this sensor, extract min load
        if sensor_methods{aux_find,3}
            for j = 1:length(S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 2}.DesignClimate)
                loads_min{l,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 2}.DesignClimate{1, j}.Attributes.(sensor_str);
                parameters12{l,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 2}.DesignClimate{1, j}.Attributes.(param1);
                parameters22{l,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 2}.DesignClimate{1, j}.Attributes.(param2);
            end
            l = l+1;
        end
        %if the method is defined for this sensor, extract abs load
        if sensor_methods{aux_find,4}
            for j = 1:length(S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 3}.DesignClimate)
                loads_abs{m,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 3}.DesignClimate{1, j}.Attributes.(sensor_str);
                parameters13{m,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 3}.DesignClimate{1, j}.Attributes.(param1);
                parameters23{m,j} = S.VscData.LoadData.ReferenceLoads.Extreme.LoadCase{1, i}.Method{1, 3}.DesignClimate{1, j}.Attributes.(param2);
            end
            m = m+1;
        end
    end
end

%%
%re-structure data, convert to num, so we can use it to plot

if sensor_methods{aux_find,2}
    X1 = reshape(cellfun(@str2num,parameters11),[],1);
    Y1 = reshape(cellfun(@str2num,parameters21),[],1);
    Z1 = reshape(cellfun(@str2num,loads_max),[],1);
end
if sensor_methods{aux_find,3}
    X2 = reshape(cellfun(@str2num,parameters12),[],1);
    Y2 = reshape(cellfun(@str2num,parameters22),[],1);
    Z2 = reshape(cellfun(@str2num,loads_min),[],1);
end
if sensor_methods{aux_find,4}
    X3 = reshape(cellfun(@str2num,parameters13),[],1);
    Y3 = reshape(cellfun(@str2num,parameters23),[],1);
    Z3 = reshape(cellfun(@str2num,loads_abs),[],1);
end

%%
%scatter plot
fig = figure();
set(fig,'visible','off')

%logic depending on which sensor you need, and plot, adjust labels, etc.
if sensor_methods{aux_find,2}
    scatter3(X1,Y1,Z1,[],Z1,'filled','DisplayName','max');
    hold on
end
if sensor_methods{aux_find,3}
    scatter3(X2,Y2,Z2,[],Z2,'filled','DisplayName','min');
end
if sensor_methods{aux_find,4}
    scatter3(X3,Y3,Z3,[],Z3,'filled','DisplayName','abs');
end
colorbar
legend('show')
title(dlc_str); xlabel(param1); ylabel(param2); zlabel(sensor_str)

%save your plot
saveas(gcf, fullfile(save_output_to,sprintf('%s_%s_%s_%s_%s.fig',name_prefix,dlc_str,sensor_str,param1,param2)),'fig')
saveas(gcf, fullfile(save_output_to,sprintf('%s_%s_%s_%s_%s.emf',name_prefix,dlc_str,sensor_str,param1,param2)),'emf')

close all

end
