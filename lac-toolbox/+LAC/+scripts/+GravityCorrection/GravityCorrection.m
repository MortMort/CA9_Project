function [ExtremeFam,out] = GravityCorrection(PathDLC,Sensors,DLCs,PLFmin)
% GravityCorrection - 
% See DMS 0012-1549
%
% Syntax:  [Fgrav] = GravityCorrection(PathDLC,Sensors,DLCs,PLFmin)
%
% Inputs:
%    PathDLC			- 
%    Sensors			- 
%    DLCs			- Structure with wildcards to read subset of DLCs.
%    PLFmin			- 
%
% Outputs:
%    ExtremeFam		- 
%    Out			- 
%
% Example: 
%    TBD
%    TBD
%    TBD
%
% Author: IVSON, Ivan Sønderby
% Oct. 2019; Last revision: 16-Oct-2019

% Inputs:
%    - Path to loads folder, e.g. 'h:\Vidar\Investigations\235_LoadExtrapolation\Comparison_V150\ETM_it5\Loads'; 

%------------- BEGIN CODE --------------

    obj = LAC.vts.stapost(PathDLC);
    obj.read;    
    sensno = zeros(length(Sensors(:,1)),1);
    for j=1:length(Sensors(:,1))
        sensno(j) = obj.findSensor(['' Sensors{j,1}],'exact');
    end    
    obj.calcFamily;
    
    % determine whether sensor should be gravity corrected or not
    SensorGrav = zeros(1,length(Sensors(:,1)));
    for j=1:length(Sensors(:,1))
        if ( ~isempty( strfind(Sensors{j,1},'Mx') ) ||  ~isempty( strfind(Sensors{j,1},'My') ) )% apply gravity correction
            SensorGrav(j) = 1;	
        else % no gravity correction
            SensorGrav(j) = 0;	
        end
    end
    
    % Prepare output of full stadat struct
    out = obj.stadat;
    
    % Find additional sensor indices to be used for gravity correction
    Ix_GC = [obj.findSensor('PSI') obj.findSensor('Pi1') obj.findSensor('Pi2') obj.findSensor('Pi3')];
    
    % Path to mas-file based on user input
    dirmas = dir(fullfile(PathDLC,'INPUTS','*.mas'));
    switch length(dirmas)
      case 0
        output = input('Mas-file string (absolute path): ','s');
        if strcmp(' ',(output(end)))
            output=output(1:end-1)
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

    % Routine to read the DLC wild card
    switch iscell(DLCs)
        case 1    
        posdlc = [];
        for iLC = 1 : length(DLCs)
            getdlc = regexp(obj.stadat.filenames,regexprep(DLCs{iLC},{'^','*'},{'^','.*'},'emptymatch'));
            emptyindex = cellfun('isempty', getdlc);
            getdlc(emptyindex) = {0};
            dlcstr   = cell2mat(getdlc);
            auxpos = find(dlcstr == 1);
            posdlc = [posdlc auxpos];
        end
        case 0
            getdlc = regexp(obj.stadat.filenames,regexprep(DLCs,{'^','*'},{'^','.*'},'emptymatch'));
            emptyindex = cellfun('isempty', getdlc);
            getdlc(emptyindex) = {0};
            dlcstr   = cell2mat(getdlc);
            dlcpos = find(dlcstr == 1);
    end
    
    if length(obj.stadat.filenames) > length(posdlc)
        fprintf(' Only a subset of load cases are read from the simulation folder. \n STADAT will include all the DLC in the folder.');
    end
    
    % Matrix to multiply
    h=waitbar(0,'Extracting extremes in INT files...');
    nr_files = length(obj.stadat.filenames(posdlc));
    for i=1:nr_files
        waitbar(i/length(obj.stadat.filenames(posdlc)),h);
        intfile = fullfile(PathDLC,'\INT',char(obj.stadat.filenames(posdlc(i))));
        disp(['' intfile ' of ' num2str(nr_files)])
        [~,t,IntDat] = LAC.timetrace.int.readint(intfile,1,[],[],[]);
        for j=1:length(Sensors(:,1))
            if SensorGrav(j)
                loadsignal = IntDat(:,sensno(j));
                % find extreme value for given sensor
                [Extremes{1}(i,j),IxExtremes{1}] = max(loadsignal);
                [Extremes{2}(i,j),IxExtremes{2}] = min(loadsignal);
                % calculate Fgrav for values in 'Extremes'
                data_for_Fgrav_est = IntDat(IxExtremes{1},:);
                [Fgrav{1}(i,j)] = LAC.scripts.GravityCorrection.GravityCorrection_GravityLoad([data_for_Fgrav_est(:,Ix_GC)],['' Sensors{j,1}],MAS);
                data_for_Fgrav_est = IntDat(IxExtremes{2},:);
                [Fgrav{2}(i,j)] = LAC.scripts.GravityCorrection.GravityCorrection_GravityLoad([data_for_Fgrav_est(:,Ix_GC)],['' Sensors{j,1}],MAS);
            end
        end
    end
    close(h)
    
    % Calculate Corresponding gravity corrected load incl. family weighting
    for j=1:length(Sensors(:,1))
        if SensorGrav(j)
            [ExtremeFam{1}(j,:)] = LAC.scripts.GravityCorrection.GravityCorrection_CharacteristicLoad(Extremes{1}(:,j),Fgrav{1}(:,j),1.35,PLFmin,obj.stadat.family(posdlc)',obj.stadat.method(posdlc)')'; % Family load for all families
            [ExtremeFam{2}(j,:)] = LAC.scripts.GravityCorrection.GravityCorrection_CharacteristicLoad(Extremes{2}(:,j),Fgrav{2}(:,j),1.35,PLFmin,obj.stadat.family(posdlc)',obj.stadat.method(posdlc)')'; % Family load for all families
        else
            ExtremeFam{1}(j,:) = unique(obj.stadat.maxFamily(sensno(j),posdlc));
            ExtremeFam{2}(j,:) = unique(obj.stadat.minFamily(sensno(j),posdlc));
        end
    end

    %------------- END OF CODE --------------

end
