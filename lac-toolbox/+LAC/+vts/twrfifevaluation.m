function twrfifevaluation(prepfile, varargin)
% A function to check the tower FIF frequency range before full simulation is
% performed. If a tower file is given this will replace the existing tower
% in the prepfile.
% The function creates a simulation folder for each foundation stiffness
% and run FAT1 and LAC.vts.towerfrqcheck for a combined result
% -------------------------------------------------------------------------
% Example1:    twrfifevaluation('prepfile')
% Example2:    twrfifevaluation('prepfile','towerfile')
   
[workdir, filename, ext]= fileparts(prepfile);
    prepfilename=[filename ext];
    cd(workdir);

    %% Read prep input file
    fid=fopen(prepfile,'r');
    PrepC = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    
    TWRline = find(strncmpi('TWR',PrepC{1},length('TWR'))==1,1);
    C = strsplit_LMT(PrepC{1}{TWRline});
    towerfile =C{2};
    
    if nargin > 1
        towerfile = varargin{1};
    end

    %% Read tower file
    % get sheet thickness for all stiffnesses
    [~, filename, ext]= fileparts(towerfile);
    towerfilename=[filename ext];
    fid=fopen(towerfile,'r');
    TowerC = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    TWR=LAC.vts.convert(towerfile,'TWR');
    C = strsplit_LMT(TWR.comments);
    
    keys = {'stiffness:','frequency:','Tfnd'};
    for i=1:length(keys)
        IndexC = strfind(C, keys{i});
        Index = find(not(cellfun('isempty', IndexC)));
        if i==3
            Index = [Index(2)+1 Index(4)+1 Index(6)+1];
        end
        strings{i,:} = {C{Index(1)+1} C{Index(2)+1} C{Index(3)+1}}; 
        values(i,:) = [str2num(C{Index(1)+1}) str2num(C{Index(2)+1}) str2num(C{Index(3)+1})];     
    end
    
    fnd.stiffness = values(1,:);
    fnd.frequency = values(2,:);
    fnd.thickness = values(3,:);
    fnd.stiffnessstr = strings(1,:);
    fnd.frequencystr = strings(2,:);
    fnd.thicknessstr = strings(3,:);
    
    %% Create analysis setup
    simdirnaming = {'NominalFnd','UpperFnd','LowerFnd'};
    callstr = 'FAT1';
    for i=1:3
        simdir=fullfile(workdir,'_FIFCheck',simdirnaming{i});
        mkdir(simdir);
        % Create individual twr file for investigation
        itowerfile = fullfile(simdir,towerfilename);
        fid = fopen(itowerfile,'w');
        for iline=1:length(TowerC{1})
            if (iline>str2num(TWR.NoOfSectionsInTwr)+6) && (iline<=str2num(TWR.NoOfSectionsInTwr)+8)
                fprintf(fid,sprintf('%s %s %s %s %s %s\r\n',TWR.TowerCrossSections{1,1}.data{iline-8,1},TWR.TowerCrossSections{1,1}.data{iline-8,2},fnd.thicknessstr{1}{i},TWR.TowerCrossSections{1,1}.data{iline-8,4},TWR.TowerCrossSections{1,1}.data{iline-8,5},TWR.TowerCrossSections{1,1}.data{iline-8,6}));
            else
                fprintf(fid,sprintf('%s\r\n',TowerC{1}{iline}));
            end
        end
        fclose(fid);
        
        iprepfile = fullfile(simdir,prepfilename);
        fid = fopen(iprepfile,'w');
        nlines = find(strncmpi('LOAD CASES',PrepC{1},length('LOAD CASES'))==1,1);
        for iline =1:nlines
            if iline==TWRline
                fprintf(fid,'%s',['TWR ' itowerfile]);
            else
                fprintf(fid,'%s',PrepC{1}{iline}); 
            end
            fprintf(fid,sprintf('\r\n'));
        end
        fprintf(fid,'\r\n');
        fprintf(fid,'1104a Prod. 3-5 m/s Wdir=-6\r\n');
        fprintf(fid,'ntm 1 - 6 Weib 3 5 0.5 LF 1.35\r\n');
        fprintf(fid,'0.1 2 4 -6\r\n');
        fprintf(fid,'\r\n');
        fclose(fid);
        callstr=[callstr ' ' iprepfile];
    end
    choice = questdlg('Launch FAT1', ...
	'Run simulations?', ...
	'FAT1','End','FAT1');
    % Handle response
    switch choice
        case 'FAT1'
            status = dos(callstr)
        case 'End'
            disp(['fat1 ' callstr]);
    end
    
    callstr = ['LAC.vts.towerfrqcheck({' fullfile(workdir,'_FIFCheck',simdirnaming{1},'Loads\') ',' fullfile(workdir,'_FIFCheck',simdirnaming{2},'Loads\') ',' fullfile(workdir,'_FIFCheck',simdirnaming{3},'Loads\') '},' fullfile(workdir,'_FIFCheck') ',FreqCheck.txt'];
    
    choice = questdlg('Are Fat1 done', ...
	'Run towerfrqcheck', ...
	'Done','Break','Break');
    % Handle response
    switch choice
        case 'Done'
            LAC.vts.towerfrqcheck({fullfile(workdir,'_FIFCheck',simdirnaming{1},'Loads\'),fullfile(workdir,'_FIFCheck',simdirnaming{2},'Loads\'), fullfile(workdir,'_FIFCheck',simdirnaming{3},'Loads\')}, fullfile(workdir,'_FIFCheck'), 'FreqCheck.txt');
        case 'Break'
            disp(callstr);
    end       
end