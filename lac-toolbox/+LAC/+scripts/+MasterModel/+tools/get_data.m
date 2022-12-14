
function [data, outSensors] = get_data(paths)

    mainloads = cellfun(@(p) LAC.intpostd.convert(p,'MAIN'),paths,'Un',0);
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
        lead_sensors = LAC.scripts.MasterModel.tools.get_lead_sensors(diameter);

        mainload = mainloads{i};

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
               
               current_data(end+1) = mainload.(section_name)(idx).Value;
               
           end
           
           
            
        end

    data(:,i) = current_data;


    end



data(isinf(data) | isnan(data)) = 0;

outSensors=lead_sensors(:,4);


end




