clear all
%% User input
%  currentpath = cd(fileparts(mfilename('fullpath')));
% addpath('./+vts');
makeCombClmSetup = false;
runWnd = questdlg('Do you want to create wnd clm file','Is wnd clm file is to be created');
switch runWnd
    case 'Yes'
        choice = questdlg('Please select type of wind file available', ...
            'Wind file type selection', ...
            'Int and ext file', 'Single file','Int and ext file');
        switch choice
            case 'Single file'
                [filename,pathname] = uigetfile({'*.txt';'*.out';'*.*'},'Wind file selector');
                oneWndFile = fullfile(pathname,filename);
                fid = fopen(oneWndFile,'r');
            case 'Int and ext file'
                waitfor(msgbox('Select Internal VSC file'));
                [filename,pathname] = uigetfile({'*.txt';'*.out';'*.*'},'Int wind file selector');
                intWndFile = fullfile(pathname,filename);
                fid = fopen(intWndFile,'r');
                waitfor(msgbox('Select External VSC File'));
                [filename,pathname] = uigetfile({'*.txt';'*.out';'*.*'},'Ext wind file selector');
                extWndFile = fullfile(pathname,filename);
        end
        disp('Choose component to generate climate input to:');
        disp('(based on the worst loaded turbine on the specific component)');
        disp(' ')
        disp('A : Fatigue Blade loads   (m = 10)');
        disp('B : Fatigue Hub, DriveTrain, Nacelle loads (m =  8)');
        disp('C : Fatigue Tower loads   (m =  4)');
        disp('D : Fatigue Tower Bottom loads   (m =  8)');
        disp('E : All components (Worst loaded turbine on fatigue)');
        disp('F : A specific turbine in the park');
        disp(' ')
        default = false;
        Component = input('Select letter above (default = E) : ','s');
        if isempty(Component)
            Component = 'E';
            default = true;
        end
        result = strfind('abcdef',lower(Component));
        if ~default
            while isempty(result)
                Component = input('Error in input. Please select letter above (a, b, c, d, e, or f) : ','s');
                result = strfind('abcdef',lower(Component));
            end
        end
        switch lower(Component)
            case 'a'
                type = '_m=10'; WTGID = '';
            case 'b'
                type = '_m=8'; WTGID = '';
            case 'c'
                type = '_m=4'; WTGID = '';
            case 'd'
                type = '_TWR_m=8'; WTGID = '';
            case 'e'
                type = '_WorstCase'; WTGID = '';
            case 'f'
                type = '';
                
                disp(' ');
                disp('Turbine labels:')
                % list the turbine labels
                C = textscan(fid,'%s','delimiter',['\r', '\n']);
                D = C;
                for i = 1:length(C{1})
                    D{1}{i} = C{1}{i}(find(~isspace(C{1}{i}))); %crunched all line to read exact string
                end
                key = 'WTGLabelLongitude';
                pos = GetPosOfKeyFromOutFile(D{1} , key);
                linesListFromOutFile = GetLinesListFromOutFile_fromPOS(C{1} , pos, 0, -1);
                [nRowofTable , mTurbines] = size(linesListFromOutFile);
                temp = 1;
                for i= 1:nRowofTable
                    singleLine = strsplit_LMT(linesListFromOutFile{i,1},'	');
                    LineToTable = singleLine(strcmpi(singleLine(1:end), '')==0);
                    if strcmpi(LineToTable(1, 5), 'New')
                        dataTable{temp,1} = char(LineToTable(1, 1));
                        temp =temp+1;
                    end
                end
                FatWTGLabel = dataTable';
                NoTurbine = size(dataTable,1);
                for i=1:NoTurbine
                    fprintf(' %12s ',[FatWTGLabel{i}]);
                    if mod(i,5) == 0
                        fprintf('\n');
                    end
                end
                disp(' ');
                WTGID = input('Please enter the WTG Label of the turbine you want to analyze: ','s');
        end
        makeCombClmSetup = true;
    case 'No'
        [filename,pathname] = uigetfile({'*.clm';'*.txt';'*.*'},'Wind file selector');
        outClmFile = fullfile(pathname,filename);
end
% % in case only one climate file is available
% oneWindFile = '';
% % in case the internal and external climate files are available
% intWndFile = 'n:\RNSP\16-528\Inputs\WND\Knockalough_V1_11xV105 3.45MW HH78_161005_145026.txt';
% extWndFile = 'n:\RNSP\16-528\Inputs\WND\Knockalough_V1_11xV105 3.45MW HH78_161005_144920_ext.txt';
%Other inputs
% makeCombClmSetup = true; %in case internal and external wind files are present, make it true
% makePrepSetup = true; % in case VTS needs to be run make this true
% vts set-up inputs
runVTS = questdlg('Do you want to setup VTS run','VTS setup');
switch runVTS
    case 'Yes'
        waitfor(msgbox('Select baseline prep file'));
        [filename,pathname] = uigetfile({'*.txt';'*.*'},'Prep file selector');
        prepFile = fullfile(pathname,filename);
        waitfor(msgbox('Select TWR FIF file'));
        [filename,pathname] = uigetfile({'*.txt';'*.*'},'Fif file selector');
        fif = fullfile(pathname,filename);
        curDir = pwd;
        waitfor(msgbox('Select VTS setup folder'));
        prepFolder = uigetdir(curDir,'Select VTS setup folder');       
        hh = inputdlg('Enter hub height:','Hub height selector');
end

% fif = 'n:\RNSP\16-528\Inputs\TWR\0063-4271_V00 - FLEX INPUT FILE - V105-3.45 HH78 IECs, srchd, 2016-12-05, 17-57-12.txt'; % fif file
% prepFile = 'n:\RNSP\16-528\Inputs\prep\V105_3.45_IEC1A_HH72.5_STD_T3III110_57f73b_92e8ae.txt'; % prep file that needs to be used as baseline
% prepFolder = 'n:\RNSP\16-528\V105.3450.HH78.IECs\VTS\001\'; %folder where the updated prep file wi;ll be written
% hh = 78;% hub height

% User input for wnd type


%% Make climate file for twr load calculation
if makeCombClmSetup == true
    switch choice
        case 'Int and ext file'
            % Automation
            SuppressDialogbox.bOption=false;
            SuppressDialogbox.PrintMode=''; %[B or D]
            SuppressDialogbox.logNormalChoice=''; %[yes or no]
            
            LAC.vts.VSCoutToVTSclm(intWndFile,1,Component,WTGID, SuppressDialogbox); %makes clm file for tower load)
            LAC.vts.VSCoutToVTSclm(extWndFile,1,Component,WTGID, SuppressDialogbox);
            
            [path,name,ext] = fileparts(intWndFile);
            if lower(Component) == 'f' 
                dum = horzcat(name,'_WTG_',WTGID,'.clm');
            else
                dum = horzcat(name,type,'.clm');
            end
            dum = strrep(dum,' ','_');
            intClmFile = fullfile(path,dum);          
            fid = fopen(strrep(intClmFile,' ','_'),'r');
            CI = textscan(fid,'%s','delimiter','\r');
            fclose(fid);
            
            [path,name,ext] = fileparts(extWndFile);
            if lower(Component) == 'f'  
                dum = horzcat(name,'_WTG_',WTGID,'.clm');
            else
                dum = horzcat(name,type,'.clm');
            end
            dum = strrep(dum,' ','_');
            extClmFile = fullfile(path,dum);
            fid = fopen(strrep(extClmFile,' ','_'),'r');
            CE = textscan(fid,'%s','delimiter','\r');
            fclose(fid);
            
            fndEnd = false;
            for i = 1:length(CI{1})
                strTmp = strread(CI{1}{i},'%s');
                if ~isempty(strTmp)
                    if strcmpi('SiteTurb',strTmp{1})
                        st = i + 2;
                        fndEnd = true;
                    end
                    if fndEnd && strcmpi('-1',strTmp{1})
                        ed = i - 1;
                    end
                end
            end
            tot = ed-st+1;
            for i = 1:tot
                strTmp = strread(CI{1}{i+st-1},'%s');
                etmInt(i) = str2double(strTmp{6});
            end
            
            fndEnd = false;
            for i = 1:length(CE{1})
                strTmp = strread(CE{1}{i},'%s');
                if ~isempty(strTmp)
                    if strcmpi('SiteTurb',strTmp{1})
                        st = i + 2;
                        fndEnd = true;
                    end
                    if fndEnd && strcmpi('-1',strTmp{1})
                        ed = i - 1;
                    end
                end
            end
            tot = ed-st+1;
            for i = 1:tot
                strTmp = strread(CE{1}{i+st-1},'%s');
                etmExt(i) = str2double(strTmp{6});
            end
            
            if length(etmInt) ~= length(etmExt)
                error('size of site turbulence in internal file not equal to external file');
            else
                for i = 1: length(etmExt)
                    strTmp = strread(CE{1}{i+st-1},'%s');
                    numTmp = str2double(strTmp);
                    if etmExt(i) < etmInt(i)
                        numTmp(6) = etmInt(i);
                    end
                    fmtString =[ '%2i  %2i  ' repmat('\t%-9.4f ',1,length(numTmp)-2)];
                    for j = 1:length(strTmp)
                        
                        CE{1}{i+st-1} = sprintf(fmtString,numTmp);%(1),numTmp(2),numTmp(3),numTmp(4),numTmp(5),numTmp(6));
                    end
                end        
                if lower(Component) == 'f'  
                    dum = horzcat(name,'_comb_WTG_',WTGID,'.clm');
                else
                    dum = horzcat(name,'_comb',type,'.clm');
                end
                dum = strrep(dum,' ','_');
                outClmFile = fullfile(path,dum);
                fid = fopen(outClmFile,'wt');
                for i = 1:length(CE{1})
                    fprintf(fid,'%s\n',CE{1}{i});
                end
                fclose(fid);
            end
        case 'Single file'
            % Automation
            SuppressDialogbox.bOption=false;
            SuppressDialogbox.PrintMode=''; %[B or D]
            SuppressDialogbox.logNormalChoice=''; %[yes or no]
            LAC.vts.VSCoutToVTSclm(oneWndFile,1,Component,WTGID, SuppressDialogbox);
            [path,name,ext] = fileparts(oneWndFile);
            if lower(Component) == 'f'
              dum = horzcat(name,'_WTG_',WTGID,'.clm');
            else
              dum = horzcat(name,type,'.clm'); 
            end
            dum = strrep(dum,' ','_');
            outClmFile = fullfile(path,dum);
    end
end

%% Setup prep

switch runVTS
    case 'Yes'
        v = {'V50','Ve50','V1 ','Ve1'};
        [path,name,ext] = fileparts(prepFile);
        name = horzcat(name,ext);
        wrtFile = fullfile(prepFolder,name);
        fid = fopen(prepFile,'r');
        C = textscan(fid,'%s','delimiter','\r\n');
        fclose(fid);
        head = C{1}(1);
        head = inputdlg('Enter heading for the Prep File','Prep File Heading',1,head);
        C{1}(1) = head;
        key = 'TWR';
        pos = find(strncmp(key,C{1},length(key)) == 1);
        C{1}{pos} = sprintf('TWR %s',fif);
        key = 'WND';
        pos = find(strncmp(key,C{1},length(key)) == 1);
        C{1}{pos} = sprintf('WND %s',outClmFile);
        key = 'Hhub';
        pos = find(strncmp(key,C{1},length(key)) == 1);
        C{1}{pos} = sprintf('Hhub%11.2f\t\tHub height',str2double(hh{1}));
        
        for i = 1:length(C{1})
            strtmp = strread(C{1}{i},'%s');
            key = 'vexp';
            pos = find(strncmpi(key,strtmp,length(key)) == 1);
            if ~isempty(pos)
                for j = 1:length(pos)
                    if length(strtmp)>pos(j)
                        if ~isnan(str2double(strtmp{pos(j)+1}))
                            dum = horzcat(strtmp{pos(j)},' ',strtmp{pos(j)+1});
                            C{1}{i} = strrep(C{1}{i},dum,'');
                        end
                    end
                end
            end
            key = 'rho';
            pos = find(strncmpi(key,strtmp,length(key)) == 1);
            if ~isempty(pos)
                for j = 1:length(pos)
                    if length(strtmp)>pos(j)
                        if ~isnan(str2double(strtmp{pos(j)+1}))
                            dum = horzcat(strtmp{pos(j)},' ',strtmp{pos(j)+1});
                            C{1}{i} = strrep(C{1}{i},dum,'');
                        end
                    end
                end
            end
            key = 'turb';
            pos = find(strncmpi(key,strtmp,length(key)) == 1);
            if ~isempty(pos)
                for j = 1:length(pos)
                    if length(strtmp)>pos(j)
                        if ~isnan(str2double(strtmp{pos(j)+1}))
                            dum = horzcat(strtmp{pos(j)},' ',strtmp{pos(j)+1});
                            C{1}{i} = strrep(C{1}{i},dum,'');
                        end
                    end
                end
            end
        end
        fid = fopen(outClmFile,'r');
        CW = textscan(fid,'%s','delimiter','\r');
        fclose(fid);
        pos = 0;
        for i = 1:length(v)
            pos = find(strncmp(v{i},CW{1},length(v{i})) == 1);
            vLine = CW{1}{pos};
            pos = find(strncmp(v{i},C{1},length(v{i})) == 1);
            C{1}{pos} = vLine;
        end
        fid = fopen(wrtFile,'wt');
        for i = 1:length(C{1})
            fprintf(fid,'%s\n',C{1}{i});
        end
        fclose(fid);
end

%Helpers
function pos = GetPosOfKeyFromOutFile(outFileAsChar , key)
pos = find(strncmpi(key,outFileAsChar,length(key)) == 1);
end

function linesListFromOutFile = GetLinesListFromOutFile_fromPOS(outFileAsChar , pos, nRowsToSkip, nRowsToRead)

if size(pos,1)
    for i= 1:size(pos,1)
        posStart = pos(i) + nRowsToSkip ;
        
        if nRowsToRead == -1
            posEnd = length(outFileAsChar);
        else
            posEnd = posStart + nRowsToRead ;
        end
        
        for j=posStart:posEnd-1
            lineRead = outFileAsChar{j}(1:end);
            if isempty(lineRead) && nRowsToRead == -1
                break;
            end
            linesListFromOutFile{j-posStart+1,i} = lineRead;
        end
    end
end
end

