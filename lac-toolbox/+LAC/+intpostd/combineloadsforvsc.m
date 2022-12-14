function combineloadsforvsc(InputPathArray,OutputPath,RefFlag,n_mode0)

FND_on = 1;     % flag to determine whether to combine FNDload files or not (1 = combine, 0 = don't combine), copies the mode 0 FNDload file if set to 0
VSC_on = 1;     % flag to determine whether to combine VSCload files or not (1 = combine, 0 = don't combine), copies the mode 0 VSCload file if set to 0

% Input description
% - InputPathArray:     Cell array of paths (to postloads folders) to
%                       include in the combination.
% - OutputPath:         Path to output folder. Subfolders will be created
%                       which will overwrite postloads files, so don't
%                       write to existing postloads folder.
% - RefFlag:            Flag that determines whether to write reference
%                       numbers in the output files or not. Set to 1 if you
%                       want references and 0 if you don't want them.
% - n_mode0:            Index of mode 0 in the InputPathArray.
%
% Example: CombineForDesign({'h:\3MW\MK3\V1263600.087\IEC2A.001\Loads\Postloads\','h:\3MW\MK3\V1263450.087\IEC2A.001\Loads\Postloads\'},'h:\3MW\MK3\V1263600.087\IEC2A.001\Loads\Postloads\VSC_combine',1,2)

%% Change encoding to read German umlauts
default_char = feature('DefaultCharacterSet');
feature('DefaultCharacterSet','ISO-8859-1');

    %% Read Postload files
    for iPostLoad = 1:length(InputPathArray)
        %% read TWR file
        findTWR = fullfile(InputPathArray{iPostLoad},'\TWR\TWRload.txt');
        temp    = dir(findTWR);
        TWRfile = fullfile(InputPathArray{iPostLoad},'\TWR\',temp.name);
        fid=fopen(TWRfile,'r');    

        TWRcontent{iPostLoad} = textscan(fid,'%s','delimiter','\n', 'whitespace', '');
        fclose(fid);
        
        %% read FND file
        if FND_on == 1
            findFND = fullfile(InputPathArray{iPostLoad},'\FND\FNDload.txt');
            temp    = dir(findFND);
            FNDfile = fullfile(InputPathArray{iPostLoad},'\FND\',temp.name);
            fid=fopen(FNDfile,'r');    

            FNDcontent{iPostLoad} = textscan(fid,'%s','delimiter','\n', 'whitespace', '');
            fclose(fid);
        end
        
        %% read VSC file
        if VSC_on == 1
            findVSC = fullfile(InputPathArray{iPostLoad},'\VSC\VSCload.txt');
            temp    = dir(findVSC);
            VSCfile = fullfile(InputPathArray{iPostLoad},'\VSC\',temp.name);
            fid=fopen(VSCfile,'r');    

            VSCcontent{iPostLoad} = textscan(fid,'%s','delimiter','\n', 'whitespace', '');
            fclose(fid);
        end
    end
    
    %% Check tower geometry consitency
    for iPostLoad = 1:length(InputPathArray)
        [line,~]=FindLine(TWRcontent{iPostLoad}{1},'#Appendix');
        tmpstr = strread(TWRcontent{iPostLoad}{1}{line+10},'%s');
        TWRsections(iPostLoad) = strread(tmpstr{1},'%d');
        nOutputSections(iPostLoad) = 0;
        for iSec=1:TWRsections(iPostLoad)
            tmpstr = strread(TWRcontent{iPostLoad}{1}{line+10+iSec},'%s');
            OutputSection = strread(tmpstr{6},'%f');
            if OutputSection>0
                nOutputSections(iPostLoad)=nOutputSections(iPostLoad)+1;
            end
        end
    end
    if ((sum(TWRsections)/length(TWRsections))~=TWRsections(end))||((sum(nOutputSections)/length(nOutputSections))~=nOutputSections(end))
        h = msgbox('Towers do not contain the same number of sections. Program will not continue');
        waitfor(h)
        return
    else
        nTWRSections = nOutputSections(end);
    end
    
    %% Create output directory and files
    mkdir(fullfile(OutputPath,'\TWR\'));
    mkdir(fullfile(OutputPath,'\FND\'));
    mkdir(fullfile(OutputPath,'\VSC\'));
    
    TWRFileId = fopen(fullfile(OutputPath,'\TWR\TWRload.txt'),'w');
    if FND_on == 1
        FNDFileId = fopen(fullfile(OutputPath,'\FND\FNDload.txt'),'w');
    else
        copyfile([InputPathArray{n_mode0},'\FND\FNDload.txt'], [OutputPath,'\FND\FNDload.txt'])
            % Find Mode 0 FND file and copy that to FND_combine folder
    end

    if VSC_on == 1
        VSCFileId = fopen(fullfile(OutputPath,'\VSC\VSCload.txt'),'w');
    else
        copyfile([InputPathArray{n_mode0},'\VSC\VSCload.txt'], [OutputPath,'\VSC\VSCload.txt'])
            % Find Mode 0 VSC file and copy that to VSC_combine folder
    end

    %% Write TWR file
    [line,~]=FindLine(TWRcontent{iPostLoad}{1},'1  REFERENCES');
    for iline = 1:line+2
        fprintf(TWRFileId,'%s\r\n',TWRcontent{1}{1}{iline});
    end
    for iPostLoad = 1:length(InputPathArray)
        for i=1:4
            fprintf(TWRFileId,'[%d] %s\r\n',iPostLoad,TWRcontent{iPostLoad}{1}{iline+i});
        end
    end
 
    %2, 2.1 and 3
    [lineBegin,~]=FindLine(TWRcontent{1}{1},'2  SENSOR NUMBERS');
    [lineEnd,~]=FindLine(TWRcontent{1}{1},'3.1 Equivalent');
    PrintBlock(TWRcontent{1}{1},lineBegin-3,lineEnd+3,TWRFileId);
    for iTwrSec = 1:nTWRSections
        [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','3.1 Equivalent',3);
        if RefFlag == 1
            if iTwrSec == 1
                len_str = length(str);
            end
            fprintf(TWRFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(TWRFileId,'%s\r\n',str);
        end
    end
     
    % Check whether Mz sensor value table is there are not
    % If not, tower load file contains, 4.1,4.2 and 4.3 Moment due.. tables
    % If Yes, 4.1,4.2 for Mres,4.3,4.4 for Mz and 4.5 Moment due
    % Above changes are for Tower Torsion Project
    
    [line,~] = FindLine(TWRcontent{1}{1},'4.3 EXTREME LOADS EXCL PLF SORTED INCL PLF Max Mz load set');
    
    if ~isempty(line)
        bMzTable = true;
    else
        bMzTable = false;
    end
    
    % Check if CHT tower (post processing is different)
    % If we have Max Mz load set, then we have everything equal to normal
    % twr loads up to 4.4 and from 4.5 to 4.19 are extreme loads specific
    % to CHT (DLCs 11, 23, 32, 61, 62); 4.20 is moment due to tower OoV
    % If we don't have Max Mz load set, then we have two first tables including 
    % all DLCs (only for Mres) and then the specific DLCs ones (DLCs 11, 23, 
    % 32, 61, 62 --> sometimes DLC13 is also included, this is not implemented here)
    
   [lineCHT_New,~] = FindLine(TWRcontent{1}{1}, '4.5 EXTREME LOADS INCL PLF SORTED Mres INCL PLF    INCL only DLC');
   [lineCHT_Old,~] = FindLine(TWRcontent{1}{1}, '4.3 EXTREME LOADS INCL PLF SORTED INCL PLF    INCL only DLC');
   
   if ~isempty(lineCHT_Old) || ~isempty(lineCHT_New)
       CHT = true;
   else
       CHT = false;
   end

    if bMzTable == false && CHT == false
        %4.1
        [line,~]=FindLine(TWRcontent{1}{1},'4  EXTREME LOADS');
        PrintBlock(TWRcontent{1}{1},line-3,line+6,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.1 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.2
        [line,~]=FindLine(TWRcontent{1}{1},'4.2 EXTREME LOADS');
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.2 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.3 and 5.1
        [lineBegin,~]=FindLine(TWRcontent{1}{1},'4.3 MOMENT DUE');
        [lineEnd,~]=FindLine(TWRcontent{1}{1},'#5.1 SLS Loads;');
        PrintBlock(TWRcontent{1}{1},lineBegin-2,lineEnd+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','#5.1 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %5.2
        [line,~]=FindLine(TWRcontent{1}{1},'#5.2 Quantile Ldd');
        PrintBlock(TWRcontent{1}{1},line-2,line+1,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,4,'max','#5.2 Quantile Ldd',1);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
    elseif bMzTable == true && CHT == false
        
         %4.1
        [line,~]=FindLine(TWRcontent{1}{1},'4  EXTREME LOADS');
        PrintBlock(TWRcontent{1}{1},line-3,line+6,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.1 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.2
        [line,~]=FindLine(TWRcontent{1}{1},'4.2 EXTREME LOADS');    %Mres
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.2 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
        %4.3
        [line,~]=FindLine(TWRcontent{1}{1},'4.3 EXTREME LOADS');    %Mz
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs','4.3 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
        %4.4
        [line,~]=FindLine(TWRcontent{1}{1},'4.4 EXTREME LOADS');    %Mz
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs','4.4 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.5 and 5.1
        [lineBegin,~]=FindLine(TWRcontent{1}{1},'4.5 MOMENT DUE');
        [lineEnd,~]=FindLine(TWRcontent{1}{1},'#5.1 SLS Loads;');    %Mres
        PrintBlock(TWRcontent{1}{1},lineBegin-2,lineEnd+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','#5.1 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
         %5.2
        [line,~]=FindLine(TWRcontent{1}{1},'#5.2 SLS Loads;');    %Mz
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs','#5.2 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %5.3
        [line,~]=FindLine(TWRcontent{1}{1},'#5.3 Quantile Ldd');
        PrintBlock(TWRcontent{1}{1},line-2,line+1,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,4,'max','#5.3 Quantile Ldd',1);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
    elseif bMzTable == true && CHT == true
        
         %4.1
        [line,~]=FindLine(TWRcontent{1}{1},'4  EXTREME LOADS');
        PrintBlock(TWRcontent{1}{1},line-3,line+6,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.1 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.2 to 4.19
        sectionheaders = {'4.2 EXTREME LOADS',...
            '4.3 EXTREME LOADS',...
            '4.4 EXTREME LOADS',...
            '4.5 EXTREME LOADS',...
            '4.6 EXTREME LOADS',...
            '4.7 EXTREME LOADS',...
            '4.8 EXTREME LOADS',...
            '4.9 EXTREME LOADS',...
            '4.10 EXTREME LOADS',...
            '4.11 EXTREME LOADS',...
            '4.12 EXTREME LOADS',...
            '4.13 EXTREME LOADS'};
      %{
            ,...
            '4.14 EXTREME LOADS',...
            '4.15 EXTREME LOADS',...
            '4.16 EXTREME LOADS',...
            '4.17 EXTREME LOADS',...
            '4.18 EXTREME LOADS',...
            '4.19 EXTREME LOADS'};
        %}
        
        for j = 1:length(sectionheaders)
        
            [line,~]=FindLine(TWRcontent{1}{1},sectionheaders{j});    %Mres
            PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
            for iTwrSec = 1:nTWRSections
                [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs',sectionheaders{j},3);
                if RefFlag == 1
                    if iTwrSec == 1
                        len_str = length(str);
                    end
                    fprintf(TWRFileId,'%s',str);
                    nWS = len_str - length(str) + 8;
                    fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
                else
                    fprintf(TWRFileId,'%s\r\n',str);
                end
            end
            
        end

        %4.20 and 5.1
        [lineBegin,~]=FindLine(TWRcontent{1}{1},'4.14 MOMENT DUE'); %Check in TWRload file in postloads folder which subsection is last in section 4 and correct  this line ad section headers var.
        [lineEnd,~]=FindLine(TWRcontent{1}{1},'#5.1 SLS Loads;');    %Mres
        PrintBlock(TWRcontent{1}{1},lineBegin-2,lineEnd+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','#5.1 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
         %5.2
        [line,~]=FindLine(TWRcontent{1}{1},'#5.2 SLS Loads;');    %Mz
        PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs','#5.2 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %5.3
        [line,~]=FindLine(TWRcontent{1}{1},'#5.3 Quantile Ldd');
        PrintBlock(TWRcontent{1}{1},line-2,line+1,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,4,'max','#5.3 Quantile Ldd',1);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
    else % CHT older post processing
        
         %4.1
        [line,~]=FindLine(TWRcontent{1}{1},'4  EXTREME LOADS');
        PrintBlock(TWRcontent{1}{1},line-3,line+6,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','4.1 EXTREME LOADS',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %4.2 to 4.17
        sectionheaders = {'4.2 EXTREME LOADS',...
            '4.3 EXTREME LOADS',...
            '4.4 EXTREME LOADS',...
            '4.5 EXTREME LOADS',...
            '4.6 EXTREME LOADS',...
            '4.7 EXTREME LOADS',...
            '4.8 EXTREME LOADS',...
            '4.9 EXTREME LOADS',...
            '4.10 EXTREME LOADS',...
            '4.11 EXTREME LOADS',...
            '4.12 EXTREME LOADS',...
            '4.13 EXTREME LOADS',...
            '4.14 EXTREME LOADS',...
            '4.15 EXTREME LOADS',...
            '4.16 EXTREME LOADS',...
            '4.17 EXTREME LOADS'};
            %'4.18 EXTREME LOADS',...  % add if DLC13 included
            %'4.19 EXTREME LOADS',...  % add if DLC13 included
            %'4.20 EXTREME LOADS'};    % add if DLC13 included
        
        for j = 1:length(sectionheaders)
        
            [line,~]=FindLine(TWRcontent{1}{1},sectionheaders{j});    %Mres
            PrintBlock(TWRcontent{1}{1},line-2,line+3,TWRFileId);
            for iTwrSec = 1:nTWRSections
                [str,idx]=SelectString(TWRcontent,iTwrSec,2,'abs',sectionheaders{j},3);
                if RefFlag == 1
                    if iTwrSec == 1
                        len_str = length(str);
                    end
                    fprintf(TWRFileId,'%s',str);
                    nWS = len_str - length(str) + 8;
                    fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
                else
                    fprintf(TWRFileId,'%s\r\n',str);
                end
            end
            
        end

        %Moment out of vertical and 5.1
        [lineBegin,~]=FindLine(TWRcontent{1}{1},'MOMENT DUE TO TOWER OUT OF VERTICAL');
        [lineEnd,~]=FindLine(TWRcontent{1}{1},'#5.1 SLS Loads;');    %Mres
        PrintBlock(TWRcontent{1}{1},lineBegin-2,lineEnd+3,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,2,'max','#5.1 SLS Loads;',3);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end

        %5.2
        [line,~]=FindLine(TWRcontent{1}{1},'#5.2 Quantile Ldd');
        PrintBlock(TWRcontent{1}{1},line-2,line+1,TWRFileId);
        for iTwrSec = 1:nTWRSections
            [str,idx]=SelectString(TWRcontent,iTwrSec,4,'max','#5.2 Quantile Ldd',1);
            if RefFlag == 1
                if iTwrSec == 1
                    len_str = length(str);
                end
                fprintf(TWRFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(TWRFileId,'%s\r\n',str);
            end
        end
        
    end
    
    %6
    [line,~]=FindLine(TWRcontent{1}{1},'#6  Lateral');
    PrintBlock(TWRcontent{1}{1},line-5,line+3,TWRFileId);
    for iTwrSec = 1:nTWRSections+1
        [str,idx]=SelectString(TWRcontent,iTwrSec,5,'max','#6  Lateral',3);
        if RefFlag == 1
            if iTwrSec == 1
                len_str = length(str);
            end
            fprintf(TWRFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(TWRFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(TWRFileId,'%s\r\n',str);
        end
    end
    
    %Appendix
    [line,~]=FindLine(TWRcontent{1}{1},'#Appendix');
    PrintBlock(TWRcontent{1}{1},line-2,line+10+TWRsections(1),TWRFileId);
   
    fclose(TWRFileId);
    
    %% Write FND file
    if FND_on == 1
        [line,~]=FindLine(FNDcontent{iPostLoad}{1},'#1  REFERENCES');
        for iline = 1:line+2
            fprintf(FNDFileId,'%s\r\n',FNDcontent{1}{1}{iline});
        end
        for iPostLoad = 1:length(InputPathArray)
            for i=1:4
                fprintf(FNDFileId,'[%d] %s\r\n',iPostLoad,FNDcontent{iPostLoad}{1}{iline+i});
            end
        end

        %2 and 3.1 (header)
        [lineBegin,~]=FindLine(FNDcontent{1}{1},'#2  NOTES');
        [lineEnd,~]=FindLine(FNDcontent{1}{1},'#3.1 Characteristic');
        PrintBlock(FNDcontent{1}{1},lineBegin-3,lineEnd+2,FNDFileId);
        
        for i=1:4
           
            [str,idx]=SelectString(FNDcontent,i,4+i,'abs','#3.1 Characteristic',2);
            if contains(str, 'Mbt0')
                    [Mbt, PLF] = MbtVal(FNDcontent);
                    str = UpdateStr(str, Mbt, PLF);
            end
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                
                fprintf(FNDFileId,'%s\r\n',str);
            end
           
        end 
 
        %3.2
        [line,~]=FindLine(FNDcontent{1}{1},'#3.2 Characteristic');
        PrintBlock(FNDcontent{1}{1},line-2,line+2,FNDFileId);
        for i=1:4
            [str,idx]=SelectString(FNDcontent,i,4+i,'abs','#3.2 Characteristic',2);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(FNDFileId,'%s\r\n',str);
            end
        end

        %3.3
        [line,~]=FindLine(FNDcontent{1}{1},'#3.3 Characteristic');
        PrintBlock(FNDcontent{1}{1},line-2,line+2,FNDFileId);
        for i=1:4
            [str,idx]=SelectString(FNDcontent,i,4+i,'abs','#3.3 Characteristic',2);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(FNDFileId,'%s\r\n',str);
            end
        end

        %3.4
        [line,~]=FindLine(FNDcontent{1}{1},'#3.4 Characteristic');
        PrintBlock(FNDcontent{1}{1},line-2,line+2,FNDFileId);
        for i=1:4
            [str,idx]=SelectString(FNDcontent,i,4+i,'abs','#3.4 Characteristic',2);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(FNDFileId,'%s\r\n',str);
            end
        end

        %3.5
        [line,~]=FindLine(FNDcontent{1}{1},'#3.5 Quantile');
        PrintBlock(FNDcontent{1}{1},line-2,line+1,FNDFileId);    
        for i=1:4
            [str,idx]=SelectString(FNDcontent,i,4,'abs','#3.5 Quantile',1);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(FNDFileId,'%s\r\n',str);
            end
        end

        %3.6
        [line,~]=FindLine(FNDcontent{1}{1},'#3.6 Characteristic');
        PrintBlock(FNDcontent{1}{1},line-2,line+2,FNDFileId);    
        for i=1:4
            [str,idx]=SelectString(FNDcontent,i,4+i,'abs','#3.6 Characteristic',2);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(FNDFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(FNDFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(FNDFileId,'%s\r\n',str);
            end
        end  

        %3.7
        [line,~]=FindLine(FNDcontent{1}{1},'#3.7 Service');
        PrintBlock(FNDcontent{1}{1},line-2,line+1,FNDFileId);
        for i=1:4
            [str1,idx1]=SelectString(FNDcontent,i,3,'abs','#3.7 Service',1);
            [str2,idx2]=SelectString(FNDcontent,i,4,'abs','#3.7 Service',1);
            [str3,idx3]=SelectString(FNDcontent,i,5,'abs','#3.7 Service',1);
            strcell1=strread(str1,'%s');
            strcell2=strread(str2,'%s');
            strcell3=strread(str3,'%s');
            if RefFlag == 1
                fprintf(FNDFileId,'%s%s%s%s%s',strpad(strcell1{1},9,' ','r'),strpad(strcell1{2},5,' ','r'),strpad(strcell1{3},13,' ','l'),strpad(strcell2{4},12,' ','l'),strpad(strcell3{5},12,' ','l'));
                fprintf(FNDFileId, '%7s%7s%7s\r\n', ['[', num2str(idx1), ']'], ['[', num2str(idx2), ']'], ['[', num2str(idx3), ']']);
            else
                fprintf(FNDFileId,'%s%s%s%s%s\r\n',strpad(strcell1{1},9,' ','r'),strpad(strcell1{2},5,' ','r'),strpad(strcell1{3},13,' ','l'),strpad(strcell2{4},12,' ','l'),strpad(strcell3{5},12,' ','l'));
            end
        end 

        %4.1
        [lineBegin,~]=FindLine(FNDcontent{1}{1},'* Characteristic Extreme');
        [lineEnd,~]=FindLine(FNDcontent{1}{1},'#4.1 Fatigue');
        PrintBlock(FNDcontent{1}{1},lineBegin,lineEnd+1,FNDFileId);
        for i=1:3
            [str1,idx1]=SelectString(FNDcontent,i,3,'abs','#4.1 Fatigue',1);
            [str2,idx2]=SelectString(FNDcontent,i,4,'abs','#4.1 Fatigue',1);
            [str3,idx3]=SelectString(FNDcontent,i,5,'abs','#4.1 Fatigue',1);
            strcell1=strread(str1,'%s');
            strcell2=strread(str2,'%s');
            strcell3=strread(str3,'%s');
            if RefFlag == 1
                fprintf(FNDFileId,'%s%s%s%s%s',strpad(strcell1{1},9,' ','r'),strpad(strcell1{2},5,' ','r'),strpad(strcell1{3},13,' ','l'),strpad(strcell2{4},12,' ','l'),strpad(strcell3{5},12,' ','l'));
                fprintf(FNDFileId, '%7s%7s%7s\r\n', ['[', num2str(idx1), ']'], ['[', num2str(idx2), ']'], ['[', num2str(idx3), ']']);
            else
                fprintf(FNDFileId,'%s%s%s%s%s\r\n',strpad(strcell1{1},9,' ','r'),strpad(strcell1{2},5,' ','r'),strpad(strcell1{3},13,' ','l'),strpad(strcell2{4},12,' ','l'),strpad(strcell3{5},12,' ','l'));
            end
            %fprintf(FNDFileId,'\r\n\r\n');
        end
        fprintf(FNDFileId,'\r\n\r\n');

        %4.2
        for iPostLoad = 1:length(InputPathArray)
            if iPostLoad == 1
                fprintf(FNDFileId,'#4.2 Rainflow counting spectra\r\n');
                [lineBegin,~]=FindLine(FNDcontent{iPostLoad}{1},'#4.2 Rainflow');
                [lineEnd,~]=FindLine(FNDcontent{iPostLoad}{1},'#5 Markov matrices');
                PrintBlock(FNDcontent{iPostLoad}{1},lineBegin+1,lineEnd-2,FNDFileId);
                continue
            end
            fprintf(FNDFileId,'#4.2.%d Rainflow counting spectra\r\n',iPostLoad);
            [lineBegin,~]=FindLine(FNDcontent{iPostLoad}{1},'#4.2 Rainflow');
            [lineEnd,~]=FindLine(FNDcontent{iPostLoad}{1},'#5 Markov matrices');
            PrintBlock(FNDcontent{iPostLoad}{1},lineBegin+1,lineEnd-2,FNDFileId);
        end

        %5.1
        [lineHeader,~]=FindLine(FNDcontent{1}{1},'#5 Markov matrices');
        PrintBlock(FNDcontent{1}{1},lineHeader-1,lineHeader+2,FNDFileId);
        for iPostLoad = 1:length(InputPathArray)
            fprintf(FNDFileId,'#5.1.%d Fy [kN] Markov matrix\r\n',iPostLoad);
            [lineBegin,~]=FindLine(FNDcontent{iPostLoad}{1},'#5.1 Fy [kN] Markov matrix');
            [lineEnd,~]=FindLine(FNDcontent{iPostLoad}{1},'#5.2 Mx [kNm] Markov matrix');
            PrintBlock(FNDcontent{iPostLoad}{1},lineBegin+1,lineEnd-1,FNDFileId);
        end

        %5.2
        for iPostLoad = 1:length(InputPathArray)
            fprintf(FNDFileId,'#5.2.%d Mx [kNm] Markov matrix\r\n',iPostLoad);
            [lineBegin,~]=FindLine(FNDcontent{iPostLoad}{1},'#5.2 Mx [kNm] Markov matrix');
            [lineEnd,~]=FindLine(FNDcontent{iPostLoad}{1},'#5.3 Mz [kNm] Markov matrix');
            PrintBlock(FNDcontent{iPostLoad}{1},lineBegin+1,lineEnd-1,FNDFileId);
        end

        %5.3
        for iPostLoad = 1:length(InputPathArray)
            fprintf(FNDFileId,'#5.3.%d Mz [kNm] Markov matrix\r\n',iPostLoad);
            [lineBegin,~]=FindLine(FNDcontent{iPostLoad}{1},'#5.3 Mz [kNm] Markov matrix');
            lineEnd = length(FNDcontent{iPostLoad}{1});
            PrintBlock(FNDcontent{iPostLoad}{1},lineBegin+1,lineEnd-1,FNDFileId);
        end

        fclose(FNDFileId);
    end
    
    %% Write VSC file
    if VSC_on == 1
        [line,~]=FindLine(VSCcontent{iPostLoad}{1},'1 REFERENCES');
        for iline = 1:line+2
            fprintf(VSCFileId,'%s\r\n',VSCcontent{1}{1}{iline});
        end
        for iPostLoad = 1:length(InputPathArray)
            for i=1:4
                fprintf(VSCFileId,'[%d] %s\r\n',iPostLoad,VSCcontent{iPostLoad}{1}{iline+i});
            end
        end

        %1, 2 and 3
        [lineBegin,~]=FindLine(VSCcontent{n_mode0}{1},'1  MAIN TURBINE DATA');
        [lineEnd,~]=FindLine(VSCcontent{n_mode0}{1},'4 DESIGN LOADS');
        PrintBlock(VSCcontent{n_mode0}{1},lineBegin-3,lineEnd+5,VSCFileId);

        %4
        [lineBeginRfc,~]=FindLine(VSCcontent{n_mode0}{1},'@rfc_d@');
        [lineEndRfc,~]=FindLine(VSCcontent{n_mode0}{1},'@#rfc_d@');
        [lineBeginLdd,~]=FindLine(VSCcontent{n_mode0}{1},'@ldd_d@');
        [lineEndLdd,~]=FindLine(VSCcontent{n_mode0}{1},'@#ldd_d@');
        
        for i=1:(lineEndRfc-lineBeginRfc)-1
            [str1,idx1]=SelectString(VSCcontent,i,2,'max','-- RFC --',1);
            [str2,idx2]=SelectString(VSCcontent,i,3,'max','-- RFC --',1);
            [str3,idx3]=SelectString(VSCcontent,i,4,'max','-- RFC --',1);
            strcell1=strread(str1,'%s');
            strcell2=strread(str2,'%s');
            strcell3=strread(str3,'%s');
            if RefFlag == 1
                fprintf(VSCFileId,'%s%s%s%s%s',strpad(strcell1{1},15,' ','l'),strpad(strcell1{2},12,' ','l'),strpad(strcell2{3},12,' ','l'),strpad(strcell3{4},12,' ','l'),strpad(strcell1{5},12,' ','l'));
                fprintf(VSCFileId, '%7s%7s%7s\r\n', ['[', num2str(idx1), ']'], ['[', num2str(idx2), ']'], ['[', num2str(idx3), ']']);
            else
                fprintf(VSCFileId,'%s%s%s%s%s\r\n',strpad(strcell1{1},15,' ','l'),strpad(strcell1{2},12,' ','l'),strpad(strcell2{3},12,' ','l'),strpad(strcell3{4},12,' ','l'),strpad(strcell1{5},12,' ','l'));
            end
        end
        [line,~]=FindLine(VSCcontent{1}{1},'-- LDD --');
        PrintBlock(VSCcontent{1}{1},line-3,line+1,VSCFileId);
        for i=1:(lineEndLdd-lineBeginLdd)-1
            [str1,idx1]=SelectString(VSCcontent,i,2,'max','-- LDD --',1);
            [str2,idx2]=SelectString(VSCcontent,i,3,'max','-- LDD --',1);
            [str3,idx3]=SelectString(VSCcontent,i,4,'max','-- LDD --',1);
            [str4,idx4]=SelectString(VSCcontent,i,5,'max','-- LDD --',1);
            strcell1=strread(str1,'%s');
            strcell2=strread(str2,'%s');
            strcell3=strread(str3,'%s');
            strcell4=strread(str4,'%s');
            if RefFlag == 1
                fprintf(VSCFileId,'%s%s%s%s%s%s',strpad(strcell1{1},15,' ','l'),strpad(strcell1{2},12,' ','l'),strpad(strcell2{3},12,' ','l'),strpad(strcell3{4},12,' ','l'),strpad(strcell4{5},12,' ','l'),strpad(strcell1{6},12,' ','l'));
                fprintf(VSCFileId, '%7s%7s%7s%7s\r\n', ['[', num2str(idx1), ']'], ['[', num2str(idx2), ']'], ['[', num2str(idx3), ']'], ['[', num2str(idx4), ']']);
            else
                fprintf(VSCFileId,'%s%s%s%s%s\r\n',strpad(strcell1{1},15,' ','l'),strpad(strcell1{2},12,' ','l'),strpad(strcell2{3},12,' ','l'),strpad(strcell3{4},12,' ','l'),strpad(strcell1{5},12,' ','l'));
            end
        end

        %5.1
        [line,~]=FindLine(VSCcontent{1}{1},'#5.1 Mres');
        PrintBlock(VSCcontent{1}{1},line-6,line+3,VSCFileId);
        for i=1:5
            [str,idx]=SelectString(VSCcontent,i,5,'max','#5.1 Mres',3);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end
        for i=6:10
            [str,idx]=SelectString(VSCcontent,i,6,'max','#5.1 Mres',3);
            if RefFlag == 1
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end 

        %5.1.1
        [line,~]=FindLine(VSCcontent{1}{1},'#5.1.1 Mres');
        PrintBlock(VSCcontent{1}{1},line-2,line+3,VSCFileId);
        for i=1:6
            [str,idx]=SelectString(VSCcontent,i,5,'max','#5.1.1 Mres',3);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end
        for i=7:12
            [str,idx]=SelectString(VSCcontent,i,6,'max','#5.1.1 Mres',3);
            if RefFlag == 1
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end 

        %5.1.2
        [line,~]=FindLine(VSCcontent{1}{1},'#5.1.2 Mres');
        PrintBlock(VSCcontent{1}{1},line-2,line+3,VSCFileId);
        for i=1:2
            [str,idx]=SelectString(VSCcontent,i,5,'max','#5.1.2 Mres',3);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end
        for i=3:4
            [str,idx]=SelectString(VSCcontent,i,6,'max','#5.1.2 Mres',3);
            if RefFlag == 1
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end 

        %5.2
        [line,~]=FindLine(VSCcontent{1}{1},'#5.2 Mres');
        PrintBlock(VSCcontent{1}{1},line-2,line+2,VSCFileId);
        [str,idx]=SelectString(VSCcontent,1,5,'max','#5.2 Mres',2);
        if RefFlag == 1
            len_str = length(str);
            fprintf(VSCFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(VSCFileId,'%s\r\n',str);
        end
        [str,idx]=SelectString(VSCcontent,2,6,'max','#5.2 Mres',2);
        if RefFlag == 1
            fprintf(VSCFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(VSCFileId,'%s\r\n',str);
        end

        %5.3
        [line,~]=FindLine(VSCcontent{1}{1},'#5.3 Mres');
        PrintBlock(VSCcontent{1}{1},line-2,line+2,VSCFileId);
        [str,idx]=SelectString(VSCcontent,1,5,'max','#5.3 Mres',2);
        if RefFlag == 1
            len_str = length(str);
            fprintf(VSCFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(VSCFileId,'%s\r\n',str);
        end
        [str,idx]=SelectString(VSCcontent,2,6,'max','#5.3 Mres',2);
        if RefFlag == 1
            fprintf(VSCFileId,'%s',str);
            nWS = len_str - length(str) + 8;
            fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
        else
            fprintf(VSCFileId,'%s\r\n',str);
        end

        %5.4
        [line,~]=FindLine(VSCcontent{1}{1},'#5.4 Mres');
        PrintBlock(VSCcontent{1}{1},line-2,line+2,VSCFileId);
        for i=1:2
            [str,idx]=SelectString(VSCcontent,i,5,'max','#5.4 Mres',2);
            if RefFlag == 1
                if i == 1
                    len_str = length(str);
                end
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end
        for i=3:4
            [str,idx]=SelectString(VSCcontent,i,6,'max','#5.4 Mres',2);
            if RefFlag == 1
                fprintf(VSCFileId,'%s',str);
                nWS = len_str - length(str) + 8;
                fprintf(VSCFileId,['%', num2str(nWS + 3), 's\r\n'],['[', num2str(idx),']']);
            else
                fprintf(VSCFileId,'%s\r\n',str);
            end
        end 

        fclose(VSCFileId);
    end
    
    % Return to default encoding
    feature('DefaultCharacterSet',default_char);
end

function [line,StrArr]=FindLine(text,key)
    line = find(strncmpi(key,text,length(key))==1);
    if ~isempty(line)
        StrArr = strread(text{line},'%s');
    else
        StrArr = [];
    end
end

function PrintBlock(Text,lineBegin,lineEnd,FileId)
    for iline = lineBegin:lineEnd
        fprintf(FileId,'%s\r\n',Text{iline});
    end
end

function [str,idx]=SelectString(Content,Line,Col,Selection,OffsetStr,Offset)
    nInput = length(Content);  
    for iInput = 1:nInput
        [Offsetline(iInput),~]=FindLine(Content{iInput}{1},OffsetStr);
        tmpstr=strread(Content{iInput}{1}{Offsetline(iInput)+Offset+Line},'%s');
        if ~strcmp(strread(tmpstr{Col},'%s'),'-')
            ValArr(iInput) = strread(tmpstr{Col},'%f');
        else
            ValArr(iInput) = NaN;
        end
    end
    Select = char(lower(Selection));
    switch Select
        case char('min')
            [~,idx]=min(ValArr);
        case char('max')
            [~,idx]=max(ValArr);
        case char('abs')
            [~,idx]=max(abs(ValArr));
    end
    str=Content{idx}{1}{Offsetline(idx)+Offset+Line};
end

function SearchAndPrintTable(key,offset,idx,FileId)
    for iPostLoad = 1:length(InputPathArray)
        [line,~]=FindLine(TWRcontent{iPostLoad},key);
        nLineBegin(iPostLoad)=line+offset;
    end
    for iTwrSec = 1:nTWRSections-1
        for iPostLoad = 1:length(InputPathArray)
            tmpstr=strread(TWRcontent{iPostLoad}{1}{nLineBegin(iPostLoad)+iTwrSec},'%s');
            Mres(iPostLoad) = strread(tmpstr{idx},'%f');
        end
        [~,idx]=max(Mres);
        fprintf(FileId,'%s\r\n',TWRcontent{idx}{1}{nLineBegin(iPostLoad)+iTwrSec});
    end
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
function str = UpdateStr(str, Mbt, PLF)%Function to fix problem with Mbt0 Senstor on 3.1
        Mbt = convertCharsToStrings(Mbt);   
        
        if contains(str,'1.10')
            PLFidx = strfind(str,'1.10');
            str(PLFidx:PLFidx+3)=PLF;
        else
            PLFidx = strfind(str,'1.35');
            str(PLFidx:PLFidx+3)=PLF;
        end   
        
        %iMbtEnd = 0;
        
        iMbtStart = strfind(str,'Abs')+3;
        Temp = strfind(str(iMbtStart:end),' ');
        for i = 1:length(Temp)
            if Temp(i+1)-Temp(i)>1
                iMbtEnd = Temp(i+1)-2+iMbtStart;
                break
            end
        end    
        if length(iMbtStart:iMbtEnd)~=strlength(Mbt)
            for i=1:(length(iMbtStart:iMbtEnd)-strlength(Mbt))
                Mbt=' '+Mbt;
            end    
        end
        str(iMbtStart:iMbtEnd)=Mbt;
        
    
end

function [Mbt, PLF] = MbtVal(Content)
    
    nInput = length(Content);  
    for iInput = 1:nInput
        [Offsetline(iInput),~]=FindLine(Content{iInput}{1},'#3.3 Characteristic');
        tmpstr=strread(Content{iInput}{1}{Offsetline(iInput)+3},'%s');
        if ~strcmp(strread(tmpstr{5},'%s'),'-')
            ValArrPLF11(iInput) = strread(tmpstr{5},'%f');
        else
            ValArrPLF11(iInput) = NaN;
        end
        [Offsetline(iInput),~]=FindLine(Content{iInput}{1},'#3.4 Characteristic');
        tmpstr=strread(Content{iInput}{1}{Offsetline(iInput)+3},'%s');
        if ~strcmp(strread(tmpstr{5},'%s'),'-')
            ValArrPLF135(iInput) = strread(tmpstr{5},'%f');
        else
            ValArrPLF135(iInput) = NaN;
        end
        maxPLF11 = max(abs(ValArrPLF11));
        maxPLF135= max(abs(ValArrPLF135));
        if maxPLF11*1.1>maxPLF135*1.35
            
            Mbt = ConvertToScientific(maxPLF11);
            PLF = '1.10';
        else
            Mbt = ConvertToScientific(maxPLF135);
            PLF = '1.35';
        end
        
        
    end
end

function res = ConvertToScientific(Mbt)
    for i =  1:10
   
    b = mod(Mbt,10);
    Mbt=Mbt/10;
        if(Mbt<1)
            res = convertCharsToStrings(num2str(b, i))+convertCharsToStrings('E+0')+convertCharsToStrings(num2str(i-1));
        break
        end
    end
end
