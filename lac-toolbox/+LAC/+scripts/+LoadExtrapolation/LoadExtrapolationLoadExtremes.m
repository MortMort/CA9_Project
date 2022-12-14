function [DLC13,Frq,Extremes,ExtremesSorted,NonExceedanceProb,flag] = LoadExtrapolationLoadExtremes(SimPath,PathDLC11,PathDLC13,Options,Sensors,check_NTM,check_ETM)

% Version review:
% 00 - ?
% 01: updated functions to fit with new LAC toolbox - MGMMI 07/2018

    DLC13 = []; Frq = []; Extremes = []; ExtremesSorted = []; NonExceedanceProb = []; flag = [0 0];

    %% Read extremes from sta files if only one extreme per time series is required, or int files if more than 1 extreme is required
    if ~strcmpi(PathDLC11,'')
        if check_NTM ~= 2
            fprintf('\nWARNING: No %s found in:\n%s\nDLC 11 extremes will be extracted from:\n%s.\n', Options.SaveDLC11,SimPath,PathDLC11)
            [Frq,Extremes] = ExtractExtremes(PathDLC11,Sensors,Options);
            
            %% Distribution probability
            PSeed=Frq/sum(Frq); % Probability of the i'th seed.
            PSeedSorted = zeros(size(Extremes));
            ExtremesSorted = zeros(size(Extremes));
            NonExceedanceProb = zeros(size(ExtremesSorted,1),size(Extremes,2));
            for i=1:size(Extremes,2)    % Loop on sensors
                                        % Sorting Extremes in ascending order
                [DataSorted]=sortrows([Extremes(:,i) PSeed],1);
                PSeedSorted(:,i) = DataSorted(:,2);
                ExtremesSorted(:,i) = DataSorted(:,1);
                
                % Define non exceedance probability
                for k=1:size(ExtremesSorted,1)
                    idat = ExtremesSorted(:,i) < ExtremesSorted(k,i);
                    NonExceedanceProb(k,i) = (idat'*PSeedSorted(:,i))^Options.NExt;
                end
            end
            flag(1) = 1;
        end
    end

    %% Get 1.3etm loads from frq file
    if ~strcmpi(PathDLC13,'')
        if check_ETM ~= 2
            fprintf('\nWARNING: No %s found in:\n%s.\n DLC 13 extremes will be extracted from:\n%s.\n', Options.SaveDLC13, SimPath,PathDLC13)
            [DLC13] = CalculateExtremesDLC13(PathDLC13,Sensors,Options);
            flag(2) = 1;
        end
    end

end


function [Frq,Extremes] = ExtractExtremes(PathDLC11,Sensors,Options)
    if Options.NExt ==1 && Options.EnableGravityPSF == 0 % Data from stapost directly, only if also gravity corr. is off
        PathHere = pwd;
        cd(PathHere);
        
	%%% MGMMI stapost
	    dat11 = LAC.vts.stapost(PathDLC11);
        dat11.read;
               
        % Find normal operation load cases (DLC11)
        getdlc  = regexp(dat11.stadat.filenames,'^11.*');
        emptyindex = cellfun('isempty', getdlc);
        getdlc(emptyindex) = {0};
        posdlc11 = find(cell2mat(getdlc) == 1);
        
        Frq           = dat11.stadat.frq(posdlc11)';
        idx1          = zeros(size(Sensors,1),1);
        for j = 1:size(Sensors,1)
            idx1(j) = dat11.findSensor(Sensors(j,1),'exact');
        end    
        
        Extremes = zeros(length(posdlc11),length(Sensors(:,1)));
	    Extremes(:,1:13) = dat11.stadat.max(idx1(1:13),posdlc11)';
	    Extremes(:,14:16) = abs(dat11.stadat.min(idx1(14:16),posdlc11))';	
                
    else
        
	    dat11 = LAC.vts.stapost(PathDLC11);
        dat11.read;    
        sensno = zeros(length(Sensors(:,1)),1); Extremes = zeros(Options.NExt,1);
        for j=1:length(Sensors(:,1))
            sensno(j) = dat11.findSensor(Sensors(j,1),'exact');
        end
        
        % find additional sensor indices to be used for gravity correction
        Ix_GC = [dat11.findSensor('PSI') dat11.findSensor('Pi1','exact') dat11.findSensor('Pi2','exact') dat11.findSensor('Pi3','exact')];
	
	% Path to mas-file based on user input
       dirmas = dir(fullfile(PathDLC11,'INPUTS','*.mas'));
       switch length(dirmas)
           case 0
             output = input('Mas-file string (absolute path): ','s');
             if strcmp(' ',(output(end)))
                 output=output(1:end-1);
             end
             [path file ext]=fileparts(output);
             if exist(output) == 2 && strcmp(ext,'.mas')
                 masfilename= output;
             end
         case 1
           masfilename = fullfile(dirmas.folder,dirmas.name);
         otherwise
           disp('Several Master files found in DLC11 folder:');
           for ff = 1:length(dirmas)
               disp(sprintf('%d. %s',ff,dirmas{ff}.name));
           end
           choice = input('Which to use? (Type just a number): ');
           masfilename = fullfile(dimas{choice}.folder,dimas{choice}.name);
       end       
       %     [F,~]   = LAC.scripts.SeismicLoads.readfrq(PathDLC11);
       MAS = LAC.scripts.GravityCorrection.GC_ReadMas(masfilename);
        
        % Matrix to multiply
        % Check for DLC 11 load cases
        getdlc  = regexp(dat11.stadat.filenames,'^11.*');
        emptyindex = cellfun('isempty', getdlc);
        getdlc(emptyindex) = {0};
        posdlc11 = find(cell2mat(getdlc) == 1);
        
        h=waitbar(0,'Extracting extremes in INT files...');
        for i=1:length(posdlc11)
            waitbar(i/length(posdlc11),h);
            Frq((i-1)*Options.NExt+1:i*Options.NExt,1)              = dat11.stadat.frq(posdlc11(i));
            intfile = fullfile(PathDLC11,'\INT',char(dat11.stadat.filenames(posdlc11(i))));
            disp(intfile)
            [~,t,IntDat] = LAC.timetrace.int.readint(intfile,1,[],[],[]);
            
            %MGMMI 28052018
            dt = t(2)-t(1);
            ind_10s_n = floor(10/dt);
            %
            
            NN = floor(size(IntDat,1)/Options.NExt);
            
            for j=1:length(Sensors(:,1))
                
                %%% MGMMI - is it ok?
                if Options.Edgefilter && strncmp(Sensors{j,1},'My',2)
                    frqEdge    = LAC.signal.getPeak(t,IntDat(:,sensno(j)),0.5,2);      
                    frq1P      = LAC.signal.getPeak(t,IntDat(:,sensno(j)),0,0.5);
                    loadsignal = LAC.signal.butterFilt(2,[frqEdge(2)-0.15 frqEdge(2)+0.15],IntDat(:,sensno(j)),mean(diff(t)),'bandpass');
                    onePsignal = LAC.signal.butterFilt(2,[max([frq1P(2)-0.15,0.01]) frq1P(2)+0.1],IntDat(:,sensno(j)),mean(diff(t)),'bandpass');
                else
                    %%%
                    loadsignal = IntDat(:,sensno(j));
                end
                
                TmpExtremes = zeros(Options.NExt,1);    % Array to contain extremes
                IxExtremes  = zeros(Options.NExt,1); 	% Array to contain indices of time-stamp of extremes
                for k=1:Options.NExt

                    if j < length(Sensors(:,1))-2
                        ix = (k-1)*NN+1:k*NN;
                        [TmpExtremes(k,1),temp_ix] = max(loadsignal(ix));
                        IxExtremes(k,1) = ix(temp_ix);

                        %%%% MGMMI 28052018 - setting 10s after local extreme to 0 to
                        % ensure independence in the extremes

                        elt = find(loadsignal((k-1)*NN+1:k*NN) == TmpExtremes(k,1))+k*NN;
                        if length(loadsignal) - elt > ind_10s_n
                            loadsignal(elt:elt+ind_10s_n) = mean(loadsignal);
                        else
                            loadsignal(elt:end) = mean(loadsignal);
                        end
                    else
                        ix = (k-1)*NN+1:k*NN;
                        [TmpExtremes(k,1),temp_ix] = min(loadsignal(ix));        
                        if Options.EnableGravityPSF
                            % When gravity correction is on, we need to keep the sign 
                            TmpExtremes(k,1) = TmpExtremes(k,1);
                        else
                            TmpExtremes(k,1) = abs(TmpExtremes(k,1));
                        end
                        IxExtremes(k,1) = ix(temp_ix);
                        
                        %%% MGMMI 280518 - ensure independance in extremes
                        elt = find(loadsignal((k-1)*NN+1:k*NN) == TmpExtremes(k,1))+k*NN;
                        if length(loadsignal) - elt > ind_10s_n
                            loadsignal(elt:elt+ind_10s_n) = mean(loadsignal);
                        else
                            loadsignal(elt:end) = mean(loadsignal);
                        end
                    end
                end
                Extremes((i-1)*Options.NExt+1:i*Options.NExt,j) = TmpExtremes;
                
                % Correction             
                if Options.EnableGravityPSF && ( ~isempty( strfind(Sensors{j,1},'Mx') ) ||  ~isempty( strfind(Sensors{j,1},'My') ) )% apply gravity correction
                    
                    % collect values of azimuth and pitch angles into input array for gravity force script
                    data_for_Fgrav_est = IntDat(IxExtremes,:); 
                    
                    % calculate Fgrav for values in 'Extremes'
                    [Fgrav] = LAC.scripts.GravityCorrection.GravityCorrection_GravityLoad(data_for_Fgrav_est(:,Ix_GC),['' Sensors{j,1}],MAS);
                    
                    % calculate gravity corrected new load (for DLC11, minimum PLF is
                    % always 1.1)
                    [Extremes((i-1)*Options.NExt+1:i*Options.NExt,j)] = LAC.scripts.GravityCorrection.GravityCorrection_CharacteristicLoad(Extremes((i-1)*Options.NExt+1:i*Options.NExt,j),Fgrav,1.25,1.1);
                    
                    if j < length(Sensors(:,1))-2
                    else
                        Extremes((i-1)*Options.NExt+1:i*Options.NExt,j) = abs( Extremes((i-1)*Options.NExt+1:i*Options.NExt,j) );
                    end
                end
            end
            clear IntDat TmpExtremes loadsignal IxExtremes
        end
        close(h);
    end

end


function [DLC13] = CalculateExtremesDLC13(PathDLC13,Sensors,Options)

    if Options.EnableGravityPSF == 0

        dat13 = LAC.vts.stapost(PathDLC13);
        dat13.read;
        DLC13SensNo = zeros(size(Sensors,1),1);
        for j = 1:size(Sensors,1)
            DLC13SensNo(j) = dat13.findSensor(Sensors{j,1},'exact');
        end    

        dat13.calcFamily;
        
        % Find etm load cases (DLC13)
        getdlc  = regexp(dat13.stadat.filenames,'^13.*');
        emptyindex = cellfun('isempty', getdlc);
        getdlc(emptyindex) = {0};
        posdlc13 = find(cell2mat(getdlc) == 1);
        
        dat13_maxFam            = unique(dat13.stadat.maxFamily(DLC13SensNo,posdlc13)','rows','stable');
        dat13_minFam            = unique(dat13.stadat.minFamily(DLC13SensNo,posdlc13)','rows','stable');
        DLC13.Extremes          = zeros(1,size(Sensors,1));
        DLC13.Extremes(1:13)    = max(dat13_maxFam(:,1:13));
        DLC13.Extremes(14:16)   = abs(min(dat13_minFam(:,14:16)));

        DLC13.Data              = dat13.stadat;
        DLC13.Families          = unique(dat13.stadat.family)';
        DLC13.ExtWS             = dat13_maxFam';
        DLC13.ExtWS(14:16,:)    = abs(dat13_minFam(:,14:16)');

        % Maximum of 3 blades
        for i=1:size(Sensors,1)
            DLC13.Extremes3B(i) = max(DLC13.Extremes([Sensors{:,2}]==Sensors{i,2}));
        end

    else % Gravity Correction is ON

        [ExtremeFam,stadat] = LAC.scripts.GravityCorrection.GravityCorrection(PathDLC13,Sensors,{'13*'},Options.MininumGravityPSF);
        CellNr = [1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2];
        
        % Identify DLC13 family
        getdlc  = regexp(stadat.filenames,'^13.*');
        emptyindex = cellfun('isempty', getdlc);
        getdlc(emptyindex) = {0};
        posdlc13 = find(cell2mat(getdlc) == 1);
        famdlc13 = unique(stadat.family(posdlc13));
        
        % Calculate Corresponding gravity corrected load incl. family weighting
        DLC13.Extremes = zeros(1,size(Sensors,1));
        for j=1:length(Sensors(:,1))
            DLC13.ExtWS(j,:) = ExtremeFam{CellNr(j)}(j,:);
            % Extreme output is extreme across families
            if (CellNr(j) == 1)
                DLC13.Extremes(1,j) = max(ExtremeFam{CellNr(j)}(j,:));
            else
                DLC13.Extremes(1,j) = abs(min(ExtremeFam{CellNr(j)}(j,:)));
            end
        end
        
        DLC13.Data = stadat; % !!! SHOULD THIS BE THE STATISTICS INCL GRAVITY CORRECTED LOADS??
        DLC13.Families = unique(stadat.family)';
        
        % Maximum of 3 blades
        for i=1:size(Sensors,1)
            DLC13.Extremes3B(i) = max(DLC13.Extremes([Sensors{:,2}]==Sensors{i,2}));
        end
        
    end
end