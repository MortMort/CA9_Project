function IdlingStabilityAssessment_Step02_PostProcess(TurbineID, Options, BLD)
    fprintf('Running Step 2 of the Idling Stability Assessment script .. \n\n');

    % Variables assignment
    WS_range = Options.WS_range;
    WD_range = -Options.WD_range;
    WD_range(WD_range < -180) = WD_range(WD_range < -180) + 360;
    WD_range = sort(WD_range);
    TI_range = Options.TI_range;
    AZ_range = Options.AZ_range;
    
    outputPath = [pwd, '\', TurbineID, '\Outputs\'];
    FigsPath   = [pwd, '\', TurbineID, '\Output_Figures\'];
    SSPath     = [pwd, '\', TurbineID, '\', BLD.profile, '_profile'];
    simPath    = [SSPath, '\TI_', num2str(TI_range(1)), '\WS', num2str(WS_range(1)), '\Loads\'];

%% Reads STA data for each TI
    fprintf('1 - READING STA FILES .. \n');
    iPath = 1;

    for iTI = 1:length(TI_range)
        for i = 1:length(WS_range)
            simDIR = [SSPath, '\TI_', num2str(100*TI_range(iTI)), '\WS', num2str(WS_range(i)), '\Loads'];
            VTS_r = LAC.vts.stapost(simDIR);
            VTS_r.read();

            eval(['VTS_aux.WS' strrep(num2str(WS_range(i)), '.', '_')  ' = VTS_r.stadat;']);
            clear VTS_r;
        end

        eval(['f_names = fieldnames(VTS_aux.WS' num2str(WS_range(1)) ');']);

        for i = 1:length(f_names)
            field = char(f_names(i));

            if eval(['length(VTS_aux.WS' num2str(WS_range(1)) '.' field '(1, :))']) ~= 1
                message = ['VTS_all.SS' num2str(100*TI_range(iTI)) '.stadat.' field, '=['];

                for iWS = 1:length(WS_range)
                    aux = [' VTS_aux.WS' strrep(num2str(WS_range(iWS)), '.', '_') '.' field];
                    message = [message  aux];
                end

                message = [message '];'];
                eval(message);

            else
                message = ['VTS_all.SS' num2str(100*TI_range(iTI)) '.' field '=VTS_aux.WS15.' field ';'];
                eval(message);
            end

        end

        clear VTS_aux;
        disp(' ');
    end

    fprintf('DONE! \n\n');

%% Find blade properties
    fprintf('2 - FINDING BLADE PROPERTIES AND SENSOR NUMBERS .. \n');
    bldFile = dir(fullfile(simPath,'PARTS\BLD\*'));
    bladeProps = LAC.vts.convert([fullfile(simPath,'PARTS\BLD\') bldFile(3).name],'BLD'); %3 beacuse we skip '.' and '..'
    bladeMassProps = bladeProps.computeMass;
    Smom1 = bladeMassProps.Smom1;
    p2pMoment = 2 * 9.81 * Smom1 / 1000;

%% Find sensor numbers
% Blade root edgewise bending moment sensors, My11r, My21r, My31r
    sens_edg(1) = find(strcmpi('My11r', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor'])));
    sens_edg(2) = find(strcmpi('My21r', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor'])));
    sens_edg(3) = find(strcmpi('My31r', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor'])));

% WSpeed, WDirection and Rotor Azimuth
    wsSens = strcmpi('Vhub', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor']));
    wdSens = strcmpi('Wdir', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor']));
    azSens = strcmpi('PSI', eval(['VTS_all.SS' num2str(100*TI_range(1)) '.sensor']));

    fprintf('DONE! \n\n');

%% DATA POST-PROCESSING 
    fprintf('3 - POST PROCESSING DATA .. \n');
    labels = fieldnames(VTS_all);

% Binning    
    for ID = 1:length(labels)
        VTS = eval(strcat('VTS_all.', labels{ID}));

        % Get STA data
            fnames   = VTS.stadat.filenames;
            WS.mean  = VTS.stadat.mean(wsSens, :);
            WD.mean  = -VTS.stadat.mean(wdSens, :);
            WD.mean(WD.mean < -180)  = WD.mean(WD.mean < -180) + 360;

        % Wind speed binning
            iNAN=find(isnan(WS.mean));
            for i=1:length(iNAN)
                WS.mean(iNAN(i))=WS.mean(iNAN(i)-1);
            end

            WS.bins = WS_range;
            for i=1:length(WS.bins)-1
                WS.edges(i)=mean([WS.bins(i),WS.bins(i+1)]);
            end

            WS.edges=[(WS.bins(1)-(WS.edges(1)-WS.bins(1))), WS.edges, (WS.bins(end)+(WS.bins(end)-WS.edges(end)))];
            WS.ibins=discretize(WS.mean,WS.edges);

        % Wind direction binning
            iNAN=find(isnan(WD.mean));
            for i=1:length(iNAN)
                WD.mean(iNAN(i))=WD.mean(iNAN(i)-1);
            end

            WD.bins = WD_range;
            for i=1:length(WD.bins)-1
                WD.edges(i)=mean([WD.bins(i),WD.bins(i+1)]);
            end

            WD.edges=[(WD.bins(1) - (WD.edges(1) - WD.bins(1))), WD.edges,(WD.bins(end) + (WD.bins(end) - WD.edges(end)))];
            WD.ibins=discretize(WD.mean,WD.edges);

        % Initial azimuth binning
            for i = 1:length(VTS.stadat.filenames)
                p1 = find(VTS.stadat.filenames{i} == 'z');
                p2 = find(VTS.stadat.filenames{i} == 'w');

                PSI.init(i) = str2num(VTS.stadat.filenames{i}(p1 + 1 : p2(2) - 1));
            end

            PSI.bins = AZ_range;
            for i = 1:length(PSI.bins)-1
               PSI.edges(i) = mean([PSI.bins(i), PSI.bins(i+1)]);
            end
                
            PSI.edges = [PSI.bins(1) - (PSI.edges(1) - PSI.bins(1)), PSI.edges, PSI.bins(end) + (PSI.bins(end) - PSI.edges(end))];
            PSI.ibins = discretize(PSI.init, PSI.edges);

% EV processing
        My1.range = VTS.stadat.max(sens_edg(1), :) - VTS.stadat.min(sens_edg(1), :);
        My2.range = VTS.stadat.max(sens_edg(2), :) - VTS.stadat.min(sens_edg(2), :);
        My3.range = VTS.stadat.max(sens_edg(3), :) - VTS.stadat.min(sens_edg(3), :);

        for i = 1:length(WS.bins)
            for j = 1:length(WD.bins)
                for k = 1:length(PSI.bins)
                    iLC = intersect(intersect(find(WS.ibins == i), find(WD.ibins == j)), find(PSI.ibins == k));
                    
                    % Sorting loads to apply family method 2 if necessary
                    EV_tmp(:, 1) = sort(My1.range(iLC), 'descend');
                    EV_tmp(:, 2) = sort(My2.range(iLC), 'descend');
                    EV_tmp(:, 3) = sort(My3.range(iLC), 'descend');
                    
                    if Options.fam_method == 0
                        EV_azi(k) = max([EV_tmp(1, 1), EV_tmp(1, 2), EV_tmp(1, 3)]); % maximum of 3 blades
                    elseif Options.fam_method == 1
                        EV_azi(k) = max([mean(EV_tmp(:, 1)), mean(EV_tmp(:, 2)), mean(EV_tmp(:, 3))]); % maximum of 3 blades with family method 1
                    elseif Options.fam_method == 2
                        EV_azi(k) = max([mean(EV_tmp(1:floor(Options.turb_seeds/2), 1)), mean(EV_tmp(1:floor(Options.turb_seeds/2), 2)), mean(EV_tmp(1:floor(Options.turb_seeds/2), 3))]); % maximum of 3 blades with family method 2
                    end
                    
                end
                EV.My(i,j) = max(EV_azi); % Gets the maximum EV among all azimuth positions
                clear EV_tmp EV_azi;
            end
        end

% Create Unstable Regions
        EV.StabMap = zeros(size(EV.My));
        EV.StabMap(EV.My >= p2pMoment) = 1;
        for i = 1:length(WS.bins)
            j = 1;
            n = 1;
			toggle = 0;
            EV.Zones{i} = [];
            while j <= length(WD.bins)
                if ~toggle
                    if EV.StabMap(i, j)
                        EV.Zones{i}(n, 1) = j;
                        toggle = 1;
                    end
                end
                if toggle
                    if ~EV.StabMap(i, j)
                        EV.Zones{i}(n, 2) = j - 1;
                        toggle = 0;
                        n = n + 1;                
                    elseif j == length(WD.bins)
                        EV.Zones{i}(n, 2) = j;
                    end
                end
                j = j + 1;
            end
        end

%% Output Critical Yaw Error Zones

        WD.bins(end+1) = -WD.bins(1);
        EV.My(:,end+1) = EV.My(:,1);
        
        fid = fopen([outputPath, 'CriticalYawErrorZones_' labels{ID}, '.txt'], 'w');

        fprintf(fid, 'Critical Yaw Error Zones:\n');
        for i=1:length(WS.bins)
            fprintf(fid, '\nWS=%.1fm/s:\n',WS.bins(i));
            if isempty(EV.Zones{i})
                fprintf(fid, '\tNone\n');
            else
                for j=1:length(EV.Zones{i}(:,1)) 
                    fprintf(fid, '\t%.1f\t\t%.1f\n',WD.edges(EV.Zones{i}(j,1)),WD.edges(EV.Zones{i}(j,2)+1));
                end
            end
        end

        fclose(fid);

        %% Plotting

        %Bending Moment vs Wind Direction Plot
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        hold off
        
        for i=1:length(WS.bins)
            plot(WD.bins,EV.My(i,:))
            hold on
        end
        plot([-180 180],[p2pMoment,p2pMoment],'r--','LineWidth',2)
        xlim([-180 180])
        legend(sprintfc('WS=%.1fm/s',WS.bins),'Location','North','Orientation','Horizontal')
        xlabel('\bfYaw Error [\circ]')
        ylabel('\bfMy Root [kNm]')
        title('\bfMaximum Root Edgewise Bending Moment')
        saveas(gca, [FigsPath labels{ID} '_BendingMoment_vs_YawError.fig']);
        saveas(gca, [FigsPath labels{ID} '_BendingMoment_vs_YawError.emf']);
        saveas(gca, [FigsPath labels{ID} '_BendingMoment_vs_YawError.png']);

        %Critical Yaw Error Plot
        imgSz=[800 800];
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        hold off
        %Plot Circles
        plot([0 0],[-1 1],'k-')
        hold on
        plot([-1 1],[0 0],'k-')
        circ=linspace(0,2*pi,360);
        plot(cos(circ),sin(circ),'k-')

        for i=1:length(WS.bins)-1
            plot(cos(circ)*WS.bins(i)/WS.bins(end),sin(circ)*WS.bins(i)/WS.bins(end),'k--')
        end
        
        %Plot Tick Marks
        ticks=[0:30:330];
        yawerrs=ticks;
        yawerrs(yawerrs>180)=yawerrs(yawerrs>180)-360;
        hozAl={'center','left','left','left','left','left','center','right','right','right','right','right'};
        vertAl={'bottom','bottom','middle','middle','middle','top','top','top','middle','middle','middle','bottom'};
        for i=1:length(ticks)
            plot([cosd(90-ticks(i)),1.05*cosd(90-ticks(i))],[sind(90-ticks(i)),1.05*sind(90-ticks(i))],'k-')
            text(1.08*cosd(90-ticks(i)),1.08*sind(90-ticks(i)),[num2str(yawerrs(i)),'\circ'],'HorizontalAlignment',hozAl{i},'VerticalAlignment',vertAl{i})
        end

        axis equal
        axLim=1.2;
        xlim([-axLim axLim])
        ylim([-axLim axLim])
        axis off

        cmap=jet(length(WS.bins));
        l = 0;

        %Plot Yaw Error Patches
        for i=length(WS.bins):-1:1
            r=WS.bins(i)/WS.bins(end);

        %   Modified to account with wind speed bins having just one critical zone
            if isempty(EV.Zones{i}) == 0
                l = l + 1;
                for j=1:length(EV.Zones{i}(:,1)) 
                    alpha = linspace(-WD.edges(EV.Zones{i}(j,1)) + 90, -WD.edges(EV.Zones{i}(j,2)+1) + 90)/180*pi;
                    P(l, j)=patch([0 cos(alpha)*r 0], [0 sin(alpha)*r 0],cmap(i,:),'FaceAlpha',1,'EdgeColor','k','LineWidth',1);
                end
            else
            end
        end
        title('\bfCritical Yaw Error Zones')

        iWS = not(cellfun('isempty', EV.Zones));
		if exist('P') == 1
			legend(P(:,1),sprintfc('WS=%.1fm/s', flip(WS.bins(iWS))), 'Location','NorthEast','Orientation','Vertical')
		else
		end
        hold off

        saveas(gca, [FigsPath labels{ID} '_CriticalYawError.fig']);
        saveas(gca, [FigsPath labels{ID} '_CriticalYawError.emf']);
        saveas(gca, [FigsPath labels{ID} '_CriticalYawError.png']);

        clear VTS fnames WS WD AZ My1 My2 M3 SectionLoads PSI EV P;
        close all;
    end

    fprintf('Step 3 finished. All results postprocessed!\n');
end