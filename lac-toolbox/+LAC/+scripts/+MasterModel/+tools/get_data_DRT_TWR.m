function [data, outSensors] = get_data_DRT_TWR(paths,varargin)
%% Input parser scheme (MB, methods)
p = inputParser;

% MBA sensor selection
defaultSensor = 'MS';
validSensors = {'MS','MB'};
checkSensors = @(x) any(validatestring(x,validSensors));

% processing method selection
defaultMethod = 1;
checkMethods = @(x) validateattributes(x,{'numeric'},{'>=',0,'<=',2},'Rankings');

% VLD codec
defaultOption = true;
checkOptions = @(x) validateattributes(x,{'logical'},{'binary'});

% inputs
addRequired(p,'paths',@iscell);
addOptional(p,'sensor',defaultSensor,checkSensors)
addOptional(p,'method',defaultMethod,checkMethods)
addOptional(p,'option',defaultOption,checkOptions)

% parse
parse(p,paths,varargin{:})

if ~isempty(fieldnames(p.Unmatched))
   disp('Extra inputs:')
   disp(p.Unmatched)
end
if ~isempty(p.UsingDefaults)
   disp('Using defaults: ')
   disp(p.UsingDefaults)
end

% assigning arguments
method = p.Results.method; % Postloads
sen = p.Results.sensor; % GRS
useVLDcodec = p.Results.option; % VLD

%% Get Data
mainloads = cellfun(@(p) LAC.intpostd.convert(p,'MAIN'),paths,'Un',0);

if method > 0
    pathsChangedDLC14 = cellfun(@(p) strrep(p,'\Postloads','\Postloads_ChangedDLC14'),paths,'Un',0);
    mainloadsAlt = cellfun(@(p) LAC.intpostd.convert(p,'MAIN'),pathsChangedDLC14,'Un',0); % loads for Postloads_Changed DLC14
end

section_names = cellfun(@(mainload) mainload.sectionName,mainloads,'Un',0);
num_turbines = length(mainloads);

intersection = section_names{1};
for i = 2:length(section_names)
    intersection = intersect(intersection,section_names{i});
end

section_names = intersection;

for i = 1:length(paths)
    
    current_path = paths{i};
    diameter = str2num(regexp(fileread(paths{i}),'(?<=Rotor radius\s+)\d+(\.\d+)*','match','once'))*2;
    lead_sensors = LAC.scripts.MasterModel.tools.get_lead_sensors(diameter,sen);
    % Add DRT sensor list (YAYDE - 03/03/2020)
    drt_sensors = LAC.scripts.MasterModel.tools.get_drt_sensors(sen);
    % Add TWR sensor list (YAYDE - 30/04/2020)
    twr_sensors = LAC.scripts.MasterModel.tools.get_twr_sensors;
    
    mainload = mainloads{i};


    if method > 0
        mainloadAlt = mainloadsAlt{i};
    end
    
    current_data = [];
    
    for j = 1:length(lead_sensors)
        
        lead_sensor = lead_sensors(j,:);
        
        for k = 1:length(section_names)
            
            section_name = section_names{k};     
            
            valid_names   = ~cellfun(@isempty,regexp({mainload.(section_name).Sensor},lead_sensor{1}));
            valid_methods = ~cellfun(@isempty,regexp({mainload.(section_name).Method},lead_sensor{2}));
            valid_notes   = ~cellfun(@isempty,regexp({mainload.(section_name).Note  },lead_sensor{3}));
            
            idx  = find(all([valid_names ; valid_methods ; valid_notes]),1);
            
            if isempty(idx)
                continue;
            end
            
            % method handling
            if (method == 2)
                if strcmp(lead_sensor{1} , ['Mx' sen 'f'])
                    % use PostloadsChangedDLC14 according to EWE proposal
                    current_data(end+1) = mainloadAlt.(section_name)(idx).Value;   
                else
                    current_data(end+1) = mainload.(section_name)(idx).Value;
                end
            elseif (method == 3)
                if any(strcmp(lead_sensor{1} , ...
                        {['Fx' sen 'f'],...
                         ['Fy' sen 'r'],...
                         ['Fz' sen 'f'],...
                         ['Mx' sen 'f'],...
                         ['Mz' sen 'f'],...
                         ['Mx' sen 'r'],...
                         ['Mz' sen 'r'],...
                         ['Mr' sen ],...
                         ['My' sen 'r'],...
                         'Mxtt',...
                         'Mztt',...
                         'Mztt*',...
                         'Mbtt',...
                         'AxK',...
                         'AyK',...
                         'OMPxK',...
                         'OMPyK',...
                         'OMPK',...
                         'Mbt0',...
                         'Mxt0',...
                         'Mbt1',...
                         'Mxt1'}))
                else
                    current_data(end+1) = mainload.(section_name)(idx).Value;
                end
            
            else
                current_data(end+1) = mainload.(section_name)(idx).Value;
            end
        end
    end
    
    %%%%% Add calculation of gearbox proxies (YAYDE - 03/03/2020)
    [DRTdata,VLDs] = LAC.scripts.MasterModel.tools.calc_DRTdata(current_path,sen,useVLDcodec);
    current_data=[current_data , DRTdata'];
    %%%%%
    
    %%%%% Add tower sensors (YAYDE - 30/04/2020)
    TWRdata = LAC.scripts.MasterModel.tools.calc_TWRdata(current_path);
    current_data=[current_data , TWRdata'];
    %%%%%
    
    data(:,i) = current_data;
    
end

data(isinf(data) | isnan(data)) = 0;

outSensors=lead_sensors(:,4);
% Add DRT sensors to the list
if method > 0
    outSensors=[outSensors ; drt_sensors(:,4)];
else
    outSensors = [outSensors; VLDs];
end
% Add TWR sensors to the list
outSensors=[outSensors ; twr_sensors(:,4)];
end




