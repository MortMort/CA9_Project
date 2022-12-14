function climate = import_VSC_Climate_file(filename)
dataraw = textscan(fileread(filename),'%[^\n\r]');
dataraw = dataraw{1};
Sensors = strsplit_LMT(dataraw{1},'\t');
climate.raw = {};
for i = 2:length(dataraw)
    datarawSplit = strsplit_LMT(dataraw{i},'\t');
    climate.raw = [climate.raw' datarawSplit']';
end
updated = struct();
for i = 1:length(Sensors)
    if sum(strcmp(Sensors,Sensors{i}))>1
        if ~isfield(updated,Sensors{i})
            updated.(Sensors{i}) = sum(strcmp(Sensors,Sensors{i}));
        else
            Sensors{i} = [Sensors{i} '_' num2str(updated.(Sensors{i})-sum(strcmp(Sensors,Sensors{i}))+1)];
        end
    end
    if any(isnan(str2double(climate.raw(:,i))))
        climate.(Sensors{i}) = climate.raw(:,i);
    else
        climate.(Sensors{i}) = str2double(climate.raw(:,i));
    end
end


