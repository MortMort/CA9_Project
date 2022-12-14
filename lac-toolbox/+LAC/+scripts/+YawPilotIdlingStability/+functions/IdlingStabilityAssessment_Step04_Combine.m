function IdlingStabilityAssessment_Step04_Combine(TurbineID, OutFolder)
    fprintf('Running Step 4 of the Idling Stability Assessment script .. \n\n');

    % Get output paths
    outputPaths = fullfile(pwd, TurbineID, 'Outputs');
    
    % Make output dir
    outputdir = fullfile(OutFolder,'Outputs');
    outfigsdir = fullfile(OutFolder,'Output_Figures');
    mkdir(outputdir)
    mkdir(outfigsdir)

%% Read Critical Yaw Error Zones

    fileformat = 'CriticalYawErrorZones_SS\d*.txt';
    ws_format = 'WS=';
    
    for folder = 1:length(outputPaths)
        Turbine = matlab.lang.makeValidName(TurbineID{folder});
        dirFolder = dir(outputPaths{folder});
        files = fullfile(outputPaths{folder},regexpi([dirFolder.name],fileformat,'match'));
        % Loop through files (TIs)
        TIvals = [];
        for file = 1:length(files)
            % Get TI, create struct
            ti = char(strrep(regexp(files{file},'SS\d*','match'),'SS',''));
            Data.(Turbine).(sprintf('TI%s',ti)) = struct;
            if any(ismember(TIvals,str2double(ti)))
                continue;
            else
                TIvals = [ TIvals str2double(ti) ];
            end
            % Read file
            fid = fopen(files{file},'r');
            filedata = textscan(fid,'%s','Delimiter','\n'); filedata = filedata{1};
            fclose(fid);
            % Loop through WSpeeds
            indws = find(~cellfun(@isempty,strfind(filedata,ws_format)));
            WSvals = [];
            for ws = 1:length(indws)
                % Get WS
                if any(ismember(WSvals,str2double(regexp(filedata{indws(ws)},'\d+.\d','match'))))
                    continue;
                else
                    WSvals = [ WSvals str2double(regexp(filedata{indws(ws)},'\d+.\d','match')) ];
                end
                wspeed = matlab.lang.makeValidName(['WS' char(...
                    regexp(filedata{indws(ws)},'\d+.\d','match'))]);
                Data.(Turbine).(sprintf('TI%s',ti)).(wspeed) = {};
                % Get data
                if ws ~= length(indws)
                    txtdata = filedata(indws(ws)+1:indws(ws+1)-2);
                else
                    txtdata = filedata(indws(ws)+1:end);
                end
                % Save critical yaw zones
                for line = 1:length(txtdata)
                    if strcmp(txtdata{line},'None')
                        Data.(Turbine).(sprintf('TI%s',ti)).(wspeed) = {'None'};
                    else
                        sector = sscanf(txtdata{line},'%f');
                        Data.(Turbine).(sprintf('TI%s',ti)).(wspeed) = [ ...
                            Data.(Turbine).(sprintf('TI%s',ti)).(wspeed) sector];
                    end
                end
            end
            
        end
    end
    
%% Get combined sectors
    
    % Loop through TIs
    finalsectors = cell(length(TIvals),length(WSvals)); % rows - TI, cols - WS
    for turb = 1:length(TIvals)
        DataWs = cell(length(TurbineID),length(WSvals));
        % Get all files for this TI
        for t = 1:length(TurbineID)
            DataTI = Data.(matlab.lang.makeValidName(TurbineID{t})).(sprintf('TI%d',TIvals(turb)));
            % Loop though WS
            for wsp = 1:length(WSvals)
                DataWs{t,wsp} = DataTI.(matlab.lang.makeValidName(sprintf('WS%.1f',WSvals(wsp))));
            end
        end
        DataWs = [ num2cell(WSvals); DataWs];
        % ---- Get combined sectors for this TI from all files ----
        sectors_comb_beginning = [];
        sectors_comb_end = [];
        for cols = 1:size(DataWs,2) % cols - WS
            for rows = 2:size(DataWs,1) % rows - Turbine
                datacell = DataWs{rows,cols};
                if length(datacell)<=1 && strcmp(datacell,'None')
                    continue;
                else
                    for d = 1:length(datacell)
                        sectors_comb_beginning = [sectors_comb_beginning datacell{d}(1)];
                        sectors_comb_end = [sectors_comb_end datacell{d}(2)];
                    end
                end
                if isempty(sectors_comb_beginning)
                    finalsectors{turb,cols} = [];
                else
                    begsectors = unique(sectors_comb_beginning);
                    endsectors = zeros(size(begsectors));
                    % unique values for sec beginning
                    for st = 1:length(begsectors)
                        indb = find(sectors_comb_beginning == begsectors(st));
                        % max sector end
                        endsectors(st) = max(sectors_comb_end(indb));
                    end
                    % unique values for end
                    endsectorsx = unique(endsectors);
                    begsectorsx = zeros(size(endsectorsx));
                    for stx = 1:length(endsectorsx)
                        inde = find(endsectors == endsectorsx(stx));
                        % min sector beg
                        begsectorsx(stx) = min(begsectors(inde));
                    end
                    finalsectors{turb,cols} = [begsectorsx; endsectorsx];
                end
            end
        end      
    end

%% Check which variants give each sector
    summary_file = fullfile(OutFolder,'Summary_sectors.txt');
    fid = fopen(summary_file,'w+');
    fprintf(fid,'Summary - Critical sectors:\n\n');
    for turb = 1:length(TIvals)
        DataWs = cell(length(TurbineID),length(WSvals)); % data for all variants and TI = turb
        % Get all files for this TI
        for t = 1:length(TurbineID)
            DataTI = Data.(matlab.lang.makeValidName(TurbineID{t})).(sprintf('TI%d',TIvals(turb)));
            % Loop trhough WS
            for wsp = 1:length(WSvals)
                DataWs{t,wsp} = DataTI.(matlab.lang.makeValidName(sprintf('WS%.1f',WSvals(wsp))));
            end
        end
        % Combined sectors for this TI
        sectors_ti = finalsectors(turb,:);
        % Loop through WS
        for wsp = 1:length(WSvals)
            fprintf(fid, 'TI = %.0f%%, WS = %.1f m/s\n', TIvals(turb), WSvals(wsp));
            sectors_ti_ws = sectors_ti{wsp};
            data_variants = DataWs(:,wsp); 
            if ~isempty(sectors_ti_ws)
                % Loop trhough sectors
                for sec = 1:size(sectors_ti_ws,2)
                    fprintf(fid,'\tSector [%.0f; %.0f]:\n', sectors_ti_ws(1,sec), sectors_ti_ws(2,sec));
                    % Loop throug variants
                    for variant = 1:length(data_variants)
                        if ~strcmp(data_variants{variant},'None')
                            % Check if inside sector
                            count_var = 0; % for separate sector in same combined sector
                            for ss = 1:length(data_variants{variant})
                                sector_var = data_variants{variant}{ss};
                                if sector_var(1) >= sectors_ti_ws(1,sec) && sector_var(2) <= sectors_ti_ws(2,sec)
                                    count_var = count_var+1;
                                    if count_var == 1 % to not repeat variants that have two separate sectors inside same combined sector
                                        fprintf(fid,'\t\t%s\n',TurbineID{variant});
                                    end
                                end
                            end
                        end
                    end
                end
            else
                fprintf(fid,'\tNone\n');
            end
            fprintf(fid,'\n');
        end
    end
    fclose(fid);

    
%% Create combined txt files
    for j = 1:length(TIvals)       
        fid = fopen(fullfile(outputdir, sprintf('CriticalYawErrorZones_SS%d.txt',TIvals(j))), 'w');
        fprintf(fid, 'Critical Yaw Error Zones:\n');
        for i = 1:length(WSvals)
            fprintf(fid, '\nWS=%.1fm/s:\n',WSvals(i));
            if isempty(finalsectors{j,i})
                fprintf(fid, '\tNone\n');
            else
                for k = 1:size(finalsectors{j,i},2) 
                    sectorswrite = finalsectors{j,i}(:,k);
                    fprintf(fid, '\t%.1f\t\t%.1f\n',sectorswrite(1),sectorswrite(2));
                end
            end
        end
        fclose(fid);
    end
    
%% Plot stability roses
    for tv = 1:length(TIvals)
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        hold off
        
        % Plot Circles
        plot([0 0],[-1 1],'k-')
        hold on
        plot([-1 1],[0 0],'k-')
        circ=linspace(0,2*pi,360);
        plot(cos(circ),sin(circ),'k-')       
        for i=1:length(WSvals)-1
            plot(cos(circ)*WSvals(i)/WSvals(end),sin(circ)*WSvals(i)/WSvals(end),'k--')
        end
        
        %Plot Tick Marks
        ticks = 0:30:330;
        yawerrs = ticks;
        yawerrs(yawerrs>180) = yawerrs(yawerrs>180)-360;
        hozAl = {'center','left','left','left','left','left','center','right','right','right','right','right'};
        vertAl = {'bottom','bottom','middle','middle','middle','top','top','top','middle','middle','middle','bottom'};
        for i=1:length(ticks)
            plot([cosd(90-ticks(i)),1.05*cosd(90-ticks(i))],[sind(90-ticks(i)),1.05*sind(90-ticks(i))],'k-')
            text(1.08*cosd(90-ticks(i)),1.08*sind(90-ticks(i)),[num2str(yawerrs(i)),'\circ'],'HorizontalAlignment',hozAl{i},'VerticalAlignment',vertAl{i})
        end
        
        axis equal
        axLim=1.2;
        xlim([-axLim axLim])
        ylim([-axLim axLim])
        axis off
        
        cmap=jet(length(WSvals));
        l = 0;
        
        %Plot Yaw Error Patches
        for i = length(WSvals):-1:1
            r = WSvals(i)/WSvals(end);
            
            %   Modified to account with wind speed bins having just one critical zone
            if ~isempty(finalsectors{tv,i})
                l = l + 1;
                sectorsplot = finalsectors{tv,i};
                for j=1:size(sectorsplot,2)
                    alpha = linspace(-sectorsplot(1,j) + 90, -sectorsplot(2,j) + 90)/180*pi;
                    P(l, j)=patch([0 cos(alpha)*r 0], [0 sin(alpha)*r 0],cmap(i,:),'FaceAlpha',1,'EdgeColor','k','LineWidth',1);
                end
            else
            end
        end
        title('\bfCritical Yaw Error Zones')
        
        iWS = not(cellfun('isempty', {finalsectors{tv,:}}));
        if exist('P') == 1
            legend(P(:,1),sprintfc('WS=%.1fm/s', flip(WSvals(iWS))), 'Location','NorthEast','Orientation','Vertical')
        else
        end
        hold off
        
        saveas(gca, fullfile(outfigsdir,sprintf('SS%d_CriticalYawError.fig',TIvals(tv))));
        saveas(gca, fullfile(outfigsdir,sprintf('SS%d_CriticalYawError.emf',TIvals(tv))));
        saveas(gca, fullfile(outfigsdir,sprintf('SS%d_CriticalYawError.png',TIvals(tv))));
        
    end


    fprintf('Step 4 finished. All results postprocessed!\n');
end