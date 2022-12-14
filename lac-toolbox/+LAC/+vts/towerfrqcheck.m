function towerfrqcheck(loadpath,varargin)
    % TOWERFRQCHECK is a script that calculate alloweed tower frequency
    % range based on all 1P's and the 3Pmin found in the controller file.
    % The output is a text file containing relevant frequncies and checks
    % towards these. A plot of the 1P and 3P area is also shown. In this
    % plot the controller limits are used i.e. 5% on 1P. and 15% on 3P_min.
    % A plot is also shown for Noise mode parameters to evaluate the 1P
    % area and operation.
    %
    % ---------------------------------------------------------------------
    %
    % Inputs:     VTS load path or cell array of paths
    % Example1:   TowerFrqRangeCheck('path1')
    % Example2:   TowerFrqRangeCheck({'path1','path2'})
    % Example3:   TowerFrqRangeCheck({'path1','path2'},'OutPath','outfile.txt')
    % Output:     writing frequencies and range checks to
    %             path1\FreqCheck.txt by default

    %% default values
    if iscell(loadpath)
        OutFolder = loadpath{1};
        nloadpath = length(loadpath);
    else
        OutFolder = loadpath;
        nloadpath = 1;
    end
    OutFileName = 'FreqCheck.txt';
    
    % check number of argument input
    if nargin>1
        OutFolder = varargin{nargin-2};
        OutFileName = varargin{nargin-1};
    end

    Data = struct;
    errorlogarray = {};
    load('h:\3MW\MK3\Investigations\192_Power_and_Noise\NM_parameters.mat'); %Mk3 noise modes
    hightowerfreqlimit = 0.152; %tower frequency must be higher according to dms 0064-1712.v00
    %%Read setup
    for i = 1:nloadpath

        % Calculate tower frequency (gravity corrected)
        if iscell(loadpath)
            loadpathstr = loadpath{i};
        else
            loadpathstr = loadpath; 
        end
        
        Data.setup(i).twr.frq = LAC.vts.towerfrq(loadpathstr);
        
        % Open ProdCtrl csv file
        inputpath = fullfile(loadpathstr,'INPUTS\');
        findCsv = fullfile(inputpath,'ProdCtrl_*.csv');
        temp    = dir(findCsv);
        csvfile = fullfile(inputpath,temp.name);
        if ~exist(csvfile,'file')
            warning('Parameter file not found!')
            Parameters.empty=[];
        else
            Parameters=LAC.vts.convert(csvfile);
        end

        if ~any(strcmp(fieldnames(Parameters),'values'))
            Data.setup(i).ctrl.ratedRpm   = 0;
            Data.setup(i).ctrl.minimumStaticRpm = 0;
            Data.setup(i).ctrl.rotorFrequency1P=0;
            Data.setup(i).ctrl.rotorFrequency3Pmin = 0;
            Data.setup(i).ctrl.rotorradius=0;
            Data.setup(i).ctrl.gearratio = 0;
        else
            %% Read csv file
            % rotor raduis
            Data.setup(i).ctrl.rotorradius = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_SC_RotorRadius'))));

            % gear ratio
            Data.setup(i).ctrl.gearratio = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_SC_GearRatio'))));

            % rated power
            Data.setup(i).ctrl.ratedPow = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LDO_PowSetpoint'))));

            % rated rpm
            Data.setup(i).ctrl.ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LDO_GenSpdSetpoint'))));
            if isempty(Data.setup(i).ctrl.ratedRpm)
                Data.setup(i).ctrl.ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LDO_GenSpdSetpoint'))));
            end
            if isempty(Data.setup(i).ctrl.ratedRpm)
                Data.setup(i).ctrl.ratedRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_NomTorqRPM'))));
            end

            % minumum connect speed
            Data.setup(i).ctrl.minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_GenDeltaMinStaticSpd'))));
            if isempty(Data.setup(i).ctrl.minimumStaticRpm)
                Data.setup(i).ctrl.minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_LSO_GenDeltaMinStaticSpd'))));
            end
            if isempty(Data.setup(i).ctrl.minimumStaticRpm)
                Data.setup(i).ctrl.minimumStaticRpm = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,'Px_SC_GenDeltaMinStaticSpd'))));
            end


            % read LaPM
            Data.setup(i).ctrl.LaPM.GenSpd = [];
            Data.setup(i).ctrl.LaPM.Power = [];
            %  read load modes
            for j=1:5
                GenSpd = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,sprintf('Px_LDO_LaPM_GenSpdLoadMode0%d',j)))));
                Power = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,sprintf('Px_LDO_LaPM_PowLoadMode0%d',j)))));
                if GenSpd ~= 0
                   Data.setup(i).ctrl.LaPM.GenSpd(end+1)=GenSpd;
                   Data.setup(i).ctrl.LaPM.Power(end+1)=Power;
                end
            end 
            %  read power modes
            for j=1:5
                GenSpd = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,sprintf('Px_LDO_LaPM_GenSpdPowMode0%d',j)))));
                Power = Parameters.values(not(cellfun('isempty', strfind(Parameters.parameters,sprintf('Px_LDO_LaPM_PowPowMode0%d',j)))));
                if GenSpd ~= 0
                    Data.setup(i).ctrl.LaPM.GenSpd(end+1) = GenSpd;
                    Data.setup(i).ctrl.LaPM.Power(end+1) = Power;
                end
            end             
        end

        %% Read FND file
        fndpath=fullfile(loadpathstr,'Postloads\Fnd\');
        if exist(fndpath, 'dir')
            findFnd = fullfile(fndpath,'FNDload.txt');
            temp    = dir(findFnd);
            fndfile = fullfile(fndpath,temp.name);
            fid=fopen(fndfile,'r');    

            C = textscan(fid,'%s','delimiter','\n');
            fclose(fid);

            key='#2.3.1'; 
            iline = find(strncmpi(key,C{1},length(key))==1);
            str = textscan(C{1}{iline+1},'%s');
            Data.setup(i).fnd.GrotNom = cell2mat(textscan(str{1}{end},'%f'));

            key='#2.3.3'; 
            iline = find(strncmpi(key,C{1},length(key))==1);
            str = textscan(C{1}{iline+1},'%s');
            Data.setup(i).fnd.GrotMin = cell2mat(textscan(str{1}{4},'%f'));
        else
            Data.setup(i).fnd.GrotNom =0;
            Data.setup(i).fnd.GrotMin =0;
        end

        %% read tower file
        % Find lower FND stiffness
        twrpath = fullfile(loadpathstr,'PARTS\TWR\');
        findTWRparts = fullfile(twrpath,'*');
        temp    = dir(findTWRparts);
        temp    = struct2cell(temp);
        temp_size = size(temp, 2);
        for j = 1:temp_size
            ind = temp_size-j+1;
            if strcmp(temp{1, ind}, '.') || strcmp(temp{1, ind}, '..')
                temp(:, ind) = [];
            end
        end
        if size(temp, 2) > 1
            error('Multiple TWR parts files, please select the proper one')
        end
        TWRpartsfile = fullfile(twrpath,temp{1});
        fid=fopen(TWRpartsfile,'r');
        C = textscan(fid,'%s','delimiter','\n');
        fclose(fid);

            % Find data for lower foundation stiffness
            key='Lower:';
            iline = find(strncmpi(key,C{1},length(key))==1,1);
            if isempty(iline)       % if no line is found, try UTF-16 encoding
                fid = fopen(TWRpartsfile, 'r', 'n', 'Unicode');
                C = textscan(fid,'%s','delimiter','\n');
                fclose(fid);
                iline = find(strncmpi(key,C{1},length(key))==1);
            end
            Data.setup(i).twr.fnd.Grot_low = cell2mat(textscan(C{1}{iline+2}, 'Foundation stiffness:%f[GNm/rad]'));
            Data.setup(i).twr.fnd.Tfnd_low = cell2mat(textscan(C{1}{iline+7}, 'Tfnd =%fm'));

            % Find data for nominal foundation stiffness
            key='Nominal:';
            iline = find(strncmpi(key,C{1},length(key))==1,1);
            Data.setup(i).twr.fnd.Grot_nom = cell2mat(textscan(C{1}{iline+2}, 'Foundation stiffness:%f[GNm/rad]'));
            Data.setup(i).twr.fnd.Tfnd_nom = cell2mat(textscan(C{1}{iline+7}, 'Tfnd =%fm'));

            % Find data for upper foundation stiffness
            key='Upper:';
            iline = find(strncmpi(key,C{1},length(key))==1,1);
            Data.setup(i).twr.fnd.Grot_up = cell2mat(textscan(C{1}{iline+2}, 'Foundation stiffness:%f[GNm/rad]'));
            Data.setup(i).twr.fnd.Tfnd_up = cell2mat(textscan(C{1}{iline+7}, 'Tfnd =%fm'));

            % Read actual Tfnd value
            n_sec = cell2mat(textscan(C{1}{8}, '%f %*s'));
            Tfnd(1) = cell2mat(textscan(C{1}{n_sec+7}, '%*f %*f %f %*f %*f %*f'));
            Tfnd(2) = cell2mat(textscan(C{1}{n_sec+8}, '%*f %*f %f %*f %*f %*f'));
            flag = 0;
            if Tfnd(1) == Tfnd(2)
                Data.setup(i).twr.fnd.Tfnd_act = Tfnd(1);
                if Tfnd(1) ~= max(Data.setup(i).twr.fnd.Tfnd_up, Data.setup(i).twr.fnd.Tfnd_nom)
                    msg = 'Foundation stiffness level is not equal to upper foundation stiffness level. Check section thickness of the two lowest sections.';
                    flag = 1;      
                elseif Tfnd(1) == Data.setup(i).twr.fnd.Tfnd_up
                    msg = 'Foundation stiffness level is equal to upper foundation stiffness level.';
                elseif Tfnd(1) == Data.setup(i).twr.fnd.Tfnd_nom
                    msg = 'Foundation stiffness level is equal to nominal foundation stiffness level (which is higher than upper foundation stiffness).';
                    flag = 1;
                end
            else
                msg = 'Section thickness (Tfnd) is not identical for the two lowest sections.';
                flag = 1;
            end
            if flag
                h = msgbox(msg);
                waitfor(h)
                errorlogarray{end+1} = msg;
            end

        %% read out file
        % Check 2nd tower frq
        outpath=fullfile(loadpathstr,'out');
        findOUT = fullfile(outpath,'*.out');
        temp    = dir(findOUT);
        OUTfile = fullfile(outpath,temp(1).name);
        fid=fopen(OUTfile,'r');    

        C = textscan(fid,'%s','delimiter','\n');
        fclose(fid);

        key='The first 8 eigenfrequencies'; 
        iline = find(strncmpi(key,C{1},length(key))==1);
        str = textscan(C{1}{iline+6},'%s');
        Data.setup(i).twr.frq.frq2nd = textscan(str{1}{end},'%f');
    end

    %% Calculate values based on csv read
    LaPMpowarray = [];
    LaPMspdarray = [];
    for i = 1:nloadpath
        % rated 1P
        Data.setup(i).designvalues.rated1P = Data.setup(i).ctrl.ratedRpm/Data.setup(i).ctrl.gearratio/60;
        % 3P minimum
        Data.setup(i).designvalues.rotorFrequency3Pmin = 3*Data.setup(i).ctrl.minimumStaticRpm/Data.setup(i).ctrl.gearratio/60;
        % LaPM1P        
        Data.setup(i).designvalues.LaPM1P = Data.setup(i).ctrl.LaPM.GenSpd/Data.setup(i).ctrl.gearratio/60;
        Data.setup(i).ctrl.LaPM.n_LaPM = length(Data.setup(i).ctrl.LaPM.Power);
        LaPMspdarray = [LaPMspdarray  Data.setup(i).ctrl.LaPM.GenSpd];
        LaPMpowarray = [LaPMpowarray  Data.setup(i).ctrl.LaPM.Power];
    end
    [LaPMpowarray idx] = unique(LaPMpowarray);
    LaPMspdarray = LaPMspdarray(idx);



    %% Check input
    TWRfrq = Data.setup(1).twr.frq.corr;
    for i = 2:nloadpath
        TWRfrq(end+1) = Data.setup(i).twr.frq.corr;
    end
    
    if max(TWRfrq<hightowerfreqlimit)
        InputOK = 0;
        % Construct a questdlg with three options
        str = 'Tower frequency is below the high tower limit.';
        choice = questdlg(sprintf('%s Do you want to continue?',str), ...
        'Warning', ...
        'Continue','Break','Continue');
        % Handle response
        switch choice
            case 'Continue'
                InputOK = 1;
            case 'Break'
                InputOK = 0;
        end
        errorlogarray{end+1} = str;
    else
        InputOK = 1;
    end
        
    
    if (min((TWRfrq == TWRfrq(1)))==0)
        InputOK = 0;
        % Construct a questdlg with three options
        str = 'Tower frequencies does not match across the variants.';
        choice = questdlg(sprintf('%s Do you want to continue?',str), ...
        'Warning', ...
        'Continue','Break','Continue');
        % Handle response
        switch choice
            case 'Continue'
                InputOK = 1;
            case 'Break'
                InputOK = 0;
        end
        errorlogarray{end+1} = str;
    else
        InputOK = 1;
    end

    %% Write frequencies
    if InputOK == 1
        % Create output folder if not already created
        if ~exist([OutFolder, OutFileName], 'dir')
            mkdir(OutFolder);
        end

        % Write header info
        FileIdOutput = fopen(fullfile(OutFolder,OutFileName),'w');

        n_pad = nloadpath*7+5;
        if n_pad < 20
            n_pad = 20;
        end

        fprintf(FileIdOutput,'File Generated by towerfrqcheck.m');
        fprintf(FileIdOutput,'\r\n');
        for i=1:nloadpath
            if iscell(loadpath)
                fprintf(FileIdOutput,'%s',['[',num2str(i),'] ',loadpath{i}]);
            else
                fprintf(FileIdOutput,'%s',['[',num2str(i),'] ',loadpath]);
            end
            fprintf(FileIdOutput,'\r\n');
        end
        fprintf(FileIdOutput,'\r\n');
        fprintf(FileIdOutput,'# Frequencies');
        fprintf(FileIdOutput,'\r\n');

        fprintf(FileIdOutput,strpad('',n_pad,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10s',['[', num2str(i), ']']);
        end
        fprintf(FileIdOutput,'\r\n');

        % Write Corrected twr frq
        fprintf(FileIdOutput,strpad('Tower freq. corr.',n_pad,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10.3f',Data.setup(i).twr.frq.corr);
        end
        fprintf(FileIdOutput,'\r\n');

        % Write 1P nominal
        fprintf(FileIdOutput,strpad('1P nominal',20,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10.3f',Data.setup(i).designvalues.rated1P);
        end
        fprintf(FileIdOutput,'\r\n'); 

        % Write 3P minimum
        fprintf(FileIdOutput,strpad('3P min',20,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10.3f',Data.setup(i).designvalues.rotorFrequency3Pmin);
        end
        fprintf(FileIdOutput,'\r\n');

        % Write 2nd tower freq.
        fprintf(FileIdOutput,strpad('2nd tower freq.',20,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10.3f',cell2mat(Data.setup(i).twr.frq.frq2nd));
        end
        fprintf(FileIdOutput,'\r\n');    

        % Write 1P LaPM
        n_LaPM = length(LaPMpowarray);
        fprintf(FileIdOutput,'%s\r\n','1P LaPM');
        for j=1:n_LaPM   
            str=sprintf('%4d',LaPMpowarray(j));
            fprintf(FileIdOutput,'%s',strpad(str,n_pad,' ','L'));
            for i=1:nloadpath
                [val idx] = ismember(LaPMpowarray(j),Data.setup(i).ctrl.LaPM.Power);
                if ~isempty(idx)
                    fprintf(FileIdOutput,'%10.3f',Data.setup(i).designvalues.LaPM1P(idx));
                else
                    fprintf(FileIdOutput,'%10s','-----');
                end
            end
            fprintf(FileIdOutput,'\r\n');
        end
        fprintf(FileIdOutput,'\r\n');

        % Frequency range check
        % Write 1P nominal
        passedstr={'x ','v '};
        fprintf(FileIdOutput,'# Frequency range check\r\n');
        fprintf(FileIdOutput,strpad('1P nominal',n_pad,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10s',passedstr{rangecheck(Data.setup(i).twr.frq.corr,Data.setup(i).designvalues.rated1P,7)+1});
            if ~rangecheck(Data.setup(i).twr.frq.corr,Data.setup(i).designvalues.rated1P,10);
                str = 'Tower frequency is within 10% of 1P operation. Please check that frequncy range is OK for all foundation stiffness';
                disp(str);
                errorlogarray{end+1} = str;
            end
        end
        fprintf(FileIdOutput,'\r\n');

        % Write 3P minimum
        fprintf(FileIdOutput,strpad('3P min',n_pad,' ','R'));
        for i=1:nloadpath
            fprintf(FileIdOutput,'%10s',passedstr{rangecheck(Data.setup(i).twr.frq.corr,Data.setup(i).designvalues.rotorFrequency3Pmin,20)+1});
        end
        fprintf(FileIdOutput,'\r\n');

        % Write 2nd/6P ratio
        fprintf(FileIdOutput,strpad('2nd/6P ratio',n_pad,' ','R'));
        for i=1:nloadpath
            ratio = cell2mat(Data.setup(i).twr.frq.frq2nd)/(6*Data.setup(i).designvalues.rated1P);
            fprintf(FileIdOutput,'%9.3f',ratio);
        end
        fprintf(FileIdOutput,'\r\n');

        % Write 1P LaPM

        fprintf(FileIdOutput,'1P LaPM\r\n');
        for j=1:n_LaPM
            str=sprintf('%4d',LaPMpowarray(j));
            fprintf(FileIdOutput,'%s',strpad(str,n_pad,' ','L'));
            for i=1:nloadpath
                [val idx] = ismember(LaPMpowarray(j),Data.setup(i).ctrl.LaPM.Power);
                if ~isempty(idx)
                    fprintf(FileIdOutput,'%10s',passedstr{rangecheck(Data.setup(i).twr.frq.corr,Data.setup(i).designvalues.LaPM1P(idx),7)+1});
                else
                    fprintf(FileIdOutput,'%10s','---');
                end            
            end
            fprintf(FileIdOutput,'\r\n');
        end

        % Write document properties
        TwrFrqCorr = Data.setup(1).twr.frq.corr;
        Twr2ndFrq = cell2mat(Data.setup(1).twr.frq.frq2nd);
        EigFrqMax = 0;
        EigFrqMaxPro = 0;
        EigFrqMin = 0;
        EigFrqMinPro = 0;
        FndStiffMin = Data.setup(1).twr.fnd.Grot_low;
        FndStiffNom = Data.setup(1).fnd.GrotNom;   

        rotorFrequencies1P = [Data.setup(1).designvalues.rated1P Data.setup(1).designvalues.LaPM1P];
        rotorFrequency3Pmin = [Data.setup(1).designvalues.rotorFrequency3Pmin];
        [val idx] = unique(rotorFrequencies1P);
        numberofunique1P = length(val);
        for i=2:nloadpath
            rotorFrequencies1P = [rotorFrequencies1P Data.setup(i).designvalues.rated1P Data.setup(i).designvalues.LaPM1P];
            rotorFrequency3Pmin = [rotorFrequency3Pmin Data.setup(i).designvalues.rotorFrequency3Pmin];
            [val idx] = unique([Data.setup(i).designvalues.rated1P Data.setup(i).designvalues.LaPM1P]);
            numberofunique1P(end+1) = length(val); 
        end

        [rotorFrequency3Pmin_critical,~] = min(rotorFrequency3Pmin);
        rotorRpm3Pmin_critical=rotorFrequency3Pmin_critical*60/3;

        % Check and calculate tower frequency interval
        [~, ind] = min(abs(rotorFrequencies1P - TwrFrqCorr));
        rotorFrequency1P_critical = rotorFrequencies1P(ind);
        rotorRpm1P_critical = rotorFrequency1P_critical*60;
        Sub_Super_Critical = zeros(nloadpath, 1);
        EigFrqMinPro = zeros(nloadpath, 1);
        EigFrqMaxPro = zeros(nloadpath, 1);
        EigFrqMin = zeros(nloadpath, 1);
        EigFrqMax = zeros(nloadpath, 1);
        for i=1:nloadpath
            if min(rotorFrequencies1P) > TwrFrqCorr     % Sub-critical
                critical1Pfreq = min(rotorFrequencies1P);
                Sub_Super_Critical(i)=1;
                EigFrqMinPro(i) = 0.05;
                EigFrqMaxPro(i) = (critical1Pfreq*0.95)/TwrFrqCorr - 1;
                EigFrqMaxPro(i) = min(0.05,max(0.02,EigFrqMaxPro(i)));
                if TwrFrqCorr*1.02 > critical1Pfreq*0.95   % Within the 5% limit of 1P
                    h = msgbox('Not sufficient tower frq range. Tower frq within 5% of 1P when the minimum 2% tower frq range is applied.');
                    waitfor(h)
                end
            elseif max(rotorFrequencies1P) <= TwrFrqCorr    % Super-critical
                critical1Pfreq = max(rotorFrequencies1P);
                Sub_Super_Critical(i)=2;
                EigFrqMinPro(i) = 1 - (critical1Pfreq*1.05)/TwrFrqCorr;
                EigFrqMaxPro(i) = (rotorFrequency3Pmin(i)*0.80)/TwrFrqCorr - 1;
                EigFrqMinPro = min(0.05,max(0.02,EigFrqMinPro));
                EigFrqMaxPro = min(0.05,max(0.02,EigFrqMaxPro));
                if TwrFrqCorr*0.98 < critical1Pfreq*1.05 || TwrFrqCorr*1.02 > rotorFrequency3Pmin(i)*0.80  % Within the 5% limit of 1P or within 20% limit of 3P 
                    if TwrFrqCorr*0.98 < critical1Pfreq*1.05       % Within the 5% limit of 1P
                        str = 'Not sufficient tower frq range. Tower frq within 5% of 1P when the minimum 2% range is applied';
                        h = msgbox(str);
                        waitfor(h)
                    elseif TwrFrqCorr*1.02 > rotorFrequency3Pmin(i)*0.80    % Within the 20% limit of 3P
                        str = 'Tower frq within 20% of 3Pmin when the minimum 2% range is applied. Check AEP impact';
                        h = msgbox(str);
                        waitfor(h)
                    end
                    errorlogarray{end+1} = str;
                end
            end
            EigFrqMin(i) = TwrFrqCorr*(1-EigFrqMinPro(i));
            EigFrqMax(i) = TwrFrqCorr*(1+EigFrqMaxPro(i));
        end

        % Print data to text file
        % Do NOT change the printing properties or the order since the Word
        % macro depends on this. Extra info can be appended to the existing
        % lines under each ## tags
        fprintf(FileIdOutput,'\r\n');
        fprintf(FileIdOutput,'# Document properties\r\n');

        fprintf(FileIdOutput,'  ## Tower frequency properties\r\n');
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n', 'Twr_frq', TwrFrqCorr);
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n', 'Twr_frq_Min', max(EigFrqMin));
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n', 'Twr_frq_Max', min(EigFrqMax));
        fprintf(FileIdOutput,'  %-15s : %4.1f   %%\r\n', 'Twr_frq_Min_pct', min(EigFrqMinPro)*10^2*-1);
        fprintf(FileIdOutput,'  %-15s : %4.1f   %%\r\n', 'Twr_frq_Max_pct', min(EigFrqMaxPro)*10^2);
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n\r\n', '2nd Twr frq', Twr2ndFrq);

        fprintf(FileIdOutput,'  ## Rotor frequency properties\r\n');
        fprintf(FileIdOutput,'  %-15s : %4.1f   rpm\r\n', 'Rotor_1P', Data.setup(1).designvalues.rated1P*60);
        fprintf(FileIdOutput,'  %-15s : %4.1f   rpm\r\n', 'Rotor_3Pmin', rotorRpm3Pmin_critical);
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n', 'Rotor_1P_frq', Data.setup(1).designvalues.rated1P);
        fprintf(FileIdOutput,'  %-15s : %6.3f Hz\r\n\r\n', 'Rotor_3Pmin_frq', rotorFrequency3Pmin_critical);

        fprintf(FileIdOutput,'  ## Foundation stiffness properties\r\n');
        fprintf(FileIdOutput,'  %17s%10s%10s\r\n', '', 'Grot', 'Tfnd');
        fprintf(FileIdOutput,'  %17s%10s%10s\r\n', '', '[GNm/rad]', '[m]');
        fprintf(FileIdOutput,'  %-15s : %9.1f%10.3f\r\n', 'Fnd_stiff_low', Data.setup(1).twr.fnd.Grot_low, Data.setup(1).twr.fnd.Tfnd_low);
        fprintf(FileIdOutput,'  %-15s : %9.1f%10.3f\r\n', 'Fnd_stiff_nom', Data.setup(1).twr.fnd.Grot_nom, Data.setup(1).twr.fnd.Tfnd_nom);
        fprintf(FileIdOutput,'  %-15s : %9.1f%10.3f\r\n', 'Fnd_stiff_up', Data.setup(1).twr.fnd.Grot_up, Data.setup(1).twr.fnd.Tfnd_up);
        fprintf(FileIdOutput,'  %-15s : %9s%10.3f\r\n', 'Fnd_stiff_act', '', Data.setup(1).twr.fnd.Tfnd_act);
        if Data.setup(1).fnd.GrotMin == 0
            fprintf(FileIdOutput,'(insufficient range to 1P or 3P, check for allowable range)\r\n');
        end
        if ~isempty(errorlogarray)
            for i=1:length(errorlogarray)
                fprintf(FileIdOutput,sprintf('*** Warning *** %s\r\n',errorlogarray{i}));
            end
        end
        
        fclose(FileIdOutput);

        % Create plot of frequency ranges
        h1=figure(1);
        cmap = colormap(jet(sum(numberofunique1P)+nloadpath));
        dh = 0.5; %height of freq rectangles plotted
        h = 1;
        for i=2:nloadpath
            h(end+1) = i+0.5*dh*length(unique(Data.setup(i).designvalues.LaPM1P));
        end
        
        if sum(Sub_Super_Critical)/length(Sub_Super_Critical) == 1
            figurefrqRangemin=0.95*TwrFrqCorr;
        else
            figurefrqRangemin=min(rotorFrequencies1P);%*0.95
        end
        figurefrqRangemax=max(rotorFrequency3Pmin);%*1.2

        iColor = 0;
        legend1P = struct;
        for i=1:nloadpath
            iColor = iColor+1;
            % 1P nominal
            legend1P(iColor).name = sprintf('%4d',Data.setup(i).ctrl.ratedPow);
            frq1Pnom = Data.setup(i).designvalues.rated1P;
            figurefrqRangemin = min(frq1Pnom,figurefrqRangemin);
            figurefrqRangemax = min(frq1Pnom,figurefrqRangemax);
            rectangle('Position',[frq1Pnom*0.95,h(i),frq1Pnom*(1.05-0.95),dh],'FaceColor',cmap(iColor,:));
            text(frq1Pnom,(h(i)+0.25),legend1P(iColor).name,'HorizontalAlignment','right')
            
            %3Pmin
            frq3P=rotorFrequency3Pmin(i);
            figurefrqRange(2 + i*2)=frq3P;
            rectangle('Position',[frq3P*0.85,h(i),frq3P*(1.15-0.85),0.5],'FaceColor',cmap(iColor,:));
            
            % 1P LaPM
            [uniqueval uniqueidx] = unique(Data.setup(i).designvalues.LaPM1P);
            for iUnique = 1:length(uniqueval)
                iColor = iColor+1;
                % generate legends
                [memval memidx] = ismember(Data.setup(i).designvalues.LaPM1P,Data.setup(i).designvalues.LaPM1P(uniqueidx(iUnique)));
                [findval findidx] = find(memidx);
                str = '';
                for imember = 1:length(findidx)
                    if imember==length(findidx)
                        str = sprintf('%s%4d',str,Data.setup(i).ctrl.LaPM.Power(findidx(imember)));
                    else
                        str = sprintf('%s%4d / ',str,Data.setup(i).ctrl.LaPM.Power(findidx(imember)));
                    end
                end
                legend1P(iColor).name = str;
                % plot
                frq1PLaPM = uniqueval(iUnique);
                figurefrqRangemin = min(frq1PLaPM,figurefrqRangemin);
                figurefrqRangemax = min(frq1PLaPM,figurefrqRangemax);
                rectangle('Position',[frq1PLaPM*0.95,(h(i)-(0.5*dh*iUnique)),frq1PLaPM*(1.05-0.95),(0.5*dh)],'FaceColor',cmap(iColor,:));
                text(frq1PLaPM,(h(i)-(0.5*dh*iUnique)+0.12),legend1P(iColor).name,'HorizontalAlignment','right')
            end         
        end
        hlimit = h(end)+0.5;
        axis([figurefrqRangemin*0.90, max(rotorFrequency3Pmin), 0, inf]);
        line([TwrFrqCorr TwrFrqCorr],[0 hlimit],'Color','k','LineWidth',3);
        line([max(EigFrqMin) max(EigFrqMin)],[0 hlimit],'Color','k','LineWidth',1);
        line([min(EigFrqMax) min(EigFrqMax)],[0 hlimit],'Color','k','LineWidth',1);
        text(max(EigFrqMin),0.5,sprintf('%.1f %%',min(EigFrqMinPro)*10^2),'HorizontalAlignment','right')
        text(min(EigFrqMax),0.5,sprintf(' %.1f %%',min(EigFrqMaxPro)*10^2),'HorizontalAlignment','left')
        set(gca,'ytick',[])
        print(h1,fullfile(OutFolder,'TwrRangePlot'),'-dpng');

        title('Frequency interval overview (1P \pm 5%, 3P_{min} -15/0%)')             % add title to plot
        xlabel('Frequency [Hz]')                      % add label to x-axis
        ylabel('Mode [-]')                               % add label to y-axis
        %% Plot Twr frq and noise modes
        plotnoise = 1;
        D=[105 112 117 126 136];
        [val Di] = min(abs(D-2*Data.setup(1).ctrl.rotorradius));
        Index=find([NRS.Turbine.D] == D(Di));
        if val >0    % Rotor diameter not matching
            Dstr=num2str(2*Data.setup(1).ctrl.rotorradius);
            Dselect=num2str(D(Di));
            m = msgbox('No match for rotor size = %s m found.');
            waitfor(m)
            plotnoise=0;
        end
        
        if plotnoise
            for iIndex = 1:length(Index)
                h = figure;
                hold on;
                nNM = length(NRS.Turbine(Index(iIndex)).NM);
                cmap = colormap(jet(nNM));
                % plot noise modes
                for l=1:nNM
                    x=NRS.Turbine(Index(iIndex)).NM(l).wsp;
                    y=NRS.Turbine(Index(iIndex)).NM(l).rpm;
                    err=0.05*y;
                    errorbar(x,y,err,'color',cmap(l,:));
                end
                % plot twr frq range
                plot(NRS.Turbine(Index(iIndex)).NM(l).wsp,ones(1,length(NRS.Turbine(Index(iIndex)).NM(l).wsp))*max(EigFrqMin)*Data.setup(1).ctrl.gearratio*60,'-k');
                plot(NRS.Turbine(Index(iIndex)).NM(l).wsp,ones(1,length(NRS.Turbine(Index(iIndex)).NM(l).wsp))*min(EigFrqMax)*Data.setup(1).ctrl.gearratio*60,'-k');
                legend(NRS.Turbine(Index(iIndex)).NM.name,'TwrFrg_{range}');
                title(NRS.Turbine(Index(iIndex)).Variant);            
                print(h,fullfile(OutFolder,sprintf('TwrNMPlot_%s',NRS.Turbine(Index(iIndex)).Variant)),'-dpng');
            end   
        end
    end
fclose all;    
end

function [outstr]=strpad(instr,TotalLength,padchar,position)
    padsize=TotalLength-length(instr);
    padstr=instr;
    for i=1:(padsize)
        switch upper(position)
            case 'L'
                padstr=sprintf('%s%s',padchar,padstr);
            case 'R'
                padstr=sprintf('%s%s',padstr,padchar);
        end
    end
    outstr=padstr;
end

function [passed]=rangecheck(twrfrq,P_frq,margin)
    passed=0;
    if twrfrq<P_frq %Sub critical
        if twrfrq<=P_frq*((100-margin)/100)
            passed=1;
        end
    else % super critical
        if twrfrq>P_frq*((100+margin)/100)
            passed=1;
        end
    end
    
    if P_frq==0 || P_frq==twrfrq
        passed=0;
    end
end