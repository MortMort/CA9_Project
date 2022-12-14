function outputdata = datsort_nihpe(inputdata,sensor,type,minvalue,maxvalue)
% function outputdata = datsort(inputdata,sensor,type,minvalue,maxvalue,xx)
% data.dat1=datsort(data.dat1,13,'m8',-1,4000);
% 1: Navnet på datafilen
% 2: Navn eller nummer på sensoren som der skal sorteres ud fra
% 3: Statistiktypen som der skal sorteres ud fra
% 4: Minimumværdien
% 5: Maximumværdien

% [LicenseOk, ErrorMsg] = dat_getlchk;
% 
% if LicenseOk==1
    
    inputfield = fieldnames(inputdata);
    i_type = find(strcmp(inputfield,type));
    outputdata=inputdata;
    fprintf('Number of files retained for analysis: %d\n', length(inputdata.mean(:,1)));
    
    if strcmp(type,'filename_long')
        filenomin=findfileno_long_anyde(minvalue);
        filenomax=findfileno_long_anyde(maxvalue);
        i=(inputdata.fileno(:)>=filenomin & inputdata.fileno(:)<=filenomax);
    elseif strcmp(type,'filename_short')
        filenomin=findfileno_short(minvalue);
        filenomax=findfileno_short(maxvalue);
        i=(inputdata.fileno(:)>=filenomin & inputdata.fileno(:)<=filenomax);
    elseif strcmp(type,'fileno')
        i=(inputdata.fileno(:)>=minvalue & inputdata.fileno(:)<=maxvalue);
    elseif strcmp(type,'filename_long_discard' )
            filenomin=findfileno_long_anyde(minvalue);
            filenomax=findfileno_long_anyde(maxvalue);
            i=(inputdata.fileno(:)<filenomin | inputdata.fileno(:)>filenomax);
    else
        if ischar(sensor) || isstring(sensor) % if sensor is specified with short name
            sensor_i = find(~cellfun(@isempty,strfind(inputdata.sensorname,sensor)));
            if isempty(sensor_i)
                error(['No match for the sensor "', sensor, '".'])
            elseif length(sensor_i) > 1
                error(['More than one match for the sensor "', sensor, '". Please be more specific.'])
            elseif length(sensor_i) == 1
                disp(['Now filtering sensor stored as "', inputdata.sensorname{sensor_i}, '".'])
                i=(inputdata.(inputfield{i_type})(:,sensor_i)>=minvalue & inputdata.(inputfield{i_type})(:,sensor_i)<=maxvalue);
                length(i)
            else
                disp(['Unknown error in finding a unique sensor for "', sensor, '".'])
            end
        elseif isnumeric(sensor) % if sensor is specified with sensor number
            if strcmp(type, 'timenum') % added to filter by date
                datemin = datenum(str2num(minvalue(1:4)), str2num(minvalue(5:6)), str2num(minvalue(7:8)), str2num(minvalue(10:11)), str2num(minvalue(12:13)), 00);
                datemax = datenum(str2num(maxvalue(1:4)), str2num(maxvalue(5:6)), str2num(maxvalue(7:8)), str2num(maxvalue(10:11)), str2num(maxvalue(12:13)), 00);
                
                if datemin == datemax
                    fprintf('   Now filtering by date: from %s-%s-%s, %s:%s, onwards.\n', minvalue(1:4), minvalue(5:6), minvalue(7:8), minvalue(10:11), minvalue(12:13));
                    i = inputdata.(inputfield{i_type}) >= datemin;
                else
                    fprintf('   Now filtering by date: from %s-%s-%s, %s:%s, to %s-%s-%s, %s:%s.\n', minvalue(1:4), minvalue(5:6), minvalue(7:8), minvalue(10:11), minvalue(12:13), maxvalue(1:4), maxvalue(5:6), maxvalue(7:8), maxvalue(10:11), maxvalue(12:13));
                    i = (inputdata.(inputfield{i_type}) >= datemin & inputdata.(inputfield{i_type}) <= datemax);
                end
            else
                sensor_i = sensor;
                fprintf('   Now filtering sensor number %s, %s.\n', num2str(sensor_i), string(inputdata.sensorname{sensor_i}));
                i=(inputdata.(inputfield{i_type})(:,sensor_i)>=minvalue & inputdata.(inputfield{i_type})(:,sensor_i)<=maxvalue);
                length(i);
            end
        end
    end
    
    
    for j = 1:length(inputfield)-2
        if strcmp(inputfield{j},'sensorname') || strcmp(inputfield{j},'sensorno') || strcmp(inputfield{j},'stat') || strcmp(inputfield{j},'unit') || strcmp(inputfield{j},'description')
            % do nothing
        elseif strcmp(inputfield{j},'filename') || strcmp(inputfield{j},'fileno')
            outputdata.(inputfield{j})=inputdata.(inputfield{j})(i,1);
        elseif strcmp(inputfield{j},'filedescription') && strcmp(inputdata.(inputfield{j}){1,1},'Not loaded')~=1
            outputdata.(inputfield{j})=inputdata.(inputfield{j})(i,1);
        else
            outputdata.(inputfield{j})=inputdata.(inputfield{j})(i,:);
        end
    end
    
    length(outputdata.mean(:,1));
    clear ans;
    
% else
%     ErrorMsg
% end

