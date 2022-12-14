function IdlingStabilityAssessment_Step01_PreProcess(TurbineID, VTS_model, Options, BLD)
    fprintf('Running Step 1 of the Idling Stability Assessment script .. \n\n');

%%  Variables assignment
    WS_range = Options.WS_range;
    WD_range = Options.WD_range;
    TI_range = Options.TI_range;
    AZ_range = Options.AZ_range;
    vexp = Options.Wshear;
    rho = Options.AirDensity;
    
    pitch   = Options.pitch;
    n_seeds = Options.turb_seeds;
    
    if Options.fam_method == 0
        fam = '+';
    elseif Options.fam_method == 1
        fam = '-';
    elseif Options.fam_method == 2
        fam = '*';
    end
    
%% FOLDER STRUCTURE -------------------------------------------------------
	mkdir([pwd '\' TurbineID]);
	mkdir([pwd '\' TurbineID '\Outputs']);
    mkdir([pwd '\' TurbineID '\Output_Figures']);

	mainFolder = strcat(pwd, '\', TurbineID, '\', BLD.profile, '_profile\');
    mkdir(mainFolder);

    for iTI = 1:length(TI_range)
        mkdir([mainFolder 'TI_' num2str(100 * TI_range(iTI))]);
        for iWS = 1:length(WS_range)
            mkdir([mainFolder 'TI_' num2str(100 * TI_range(iTI)) '\WS' num2str(WS_range(iWS))]);
        end
    end

%% CLEAN LCs FROM PREP FILE -----------------------------------------------
    % Copy VTS model to the folder structure 
    copyfile(VTS_model, [pwd '\' TurbineID]);
    [~, fname, ~] = fileparts(VTS_model);
    
    % Writes in the prep file without loadcases
    VTSmodel_noLC = [pwd '\' TurbineID '\' fname '_noLC.txt'];
    
    fid_in  = fopen(VTS_model, 'r');
    fid_out = fopen(VTSmodel_noLC, 'w');

    line = fgets(fid_in);
    while ischar(line)
        if strfind(line,'SEN') % inserting reduced sensor-file
            sensor_file = 'SEN W:\ToolsDevelopment\FAT1\PartFiles\SEN\SSS_sensors.001';
            fprintf(fid_out,'%s\n',sensor_file);
        else                
            fprintf(fid_out,'%s',line);
        end

        if strfind(line,'LOAD CASES')
            break;
        end
        line = fgets(fid_in);
    end
    fclose(fid_in);
    fclose(fid_out);    
    
%% WRITE DLCs --------------------------------------------------
    for iTI = 1:length(TI_range)
        % String to be used in the bat file that launches FAT1
        qstart_cmd = ['start FAT1 -u -p '];
        
        for iWS = 1:length(WS_range)
            qstart_cmd = [qstart_cmd '.\WS' num2str(WS_range(iWS)) '\VTS_IDLE_WS' num2str(WS_range(iWS)) '.txt '];
            copyfile(VTSmodel_noLC, [mainFolder 'TI_' num2str(100 * TI_range(iTI)) '\WS' num2str(WS_range(iWS)) '\VTS_IDLE_WS' num2str(WS_range(iWS)) '.txt']);
            fid = fopen([mainFolder 'TI_' num2str(100 * TI_range(iTI)), '\WS' num2str(WS_range(iWS)) '\VTS_IDLE_WS' num2str(WS_range(iWS)) '.txt'], 'a+');

            if TI_range(iTI) == 0
                for iAZ = 1:length(AZ_range)
                   for iWD = 1:length(WD_range) 
                       fprintf(fid, '\n');
                       fprintf(fid, '61SSSidle_ws%saz%iwd%i\n', num2str(WS_range(iWS)), AZ_range(iAZ), WD_range(iWD));
                       fprintf(fid, 'ntm %i Freq 0 LF 1.35\n', ceil(rand()*8));
                       fprintf(fid, '0.1 0 %s %i azim0 %i pitch0 9999 %i %i %i turb 0.01 Vexp 0.0 rho %.3f time  0.0100  600.0  10.0 400.0 Profdat %s\n', num2str(WS_range(iWS)), WD_range(iWD), AZ_range(iAZ), pitch, pitch, pitch, rho, BLD.profile);
                   end
                end

            else
                for iAZ = 1:length(AZ_range)
                    for iWD = 1:length(WD_range) 
                       fprintf(fid, '\n');
                       fprintf(fid, '61SSSidle_ws%saz%iwd%i\n', num2str(WS_range(iWS)), AZ_range(iAZ), WD_range(iWD));
                       fprintf(fid, 'ntm 1 %s %i Freq 0 LF 1.35\n', fam, n_seeds);
                       fprintf(fid, '0.1 0 %s %i azim0 %i pitch0 9999 %i %i %i turb %s Vexp %.2f rho %.3f time  0.0100  600.0  10.0 400.0 Profdat %s\n', num2str(WS_range(iWS)), WD_range(iWD), AZ_range(iAZ), pitch, pitch, pitch, num2str(TI_range(iTI)), vexp, rho, BLD.profile);
                    end
                end
            end

            fclose(fid);

            % Writing BAT file to launch FAT1 with all LCs under a TI value
            fid = fopen([mainFolder 'TI_' num2str(100 * TI_range(iTI)) '\QuickStart_FAT1.bat'], 'w');
            fprintf(fid, '%s', qstart_cmd);
            fclose(fid);
        end
    end

    fprintf('Step 1 finished. All VTS model files and folder structure successfully created\n');  

end