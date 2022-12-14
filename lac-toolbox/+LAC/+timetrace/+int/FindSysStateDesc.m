% Finds description of SysStates for vdf-files
% Internal VDAT function
%
% JEB, December 17, 2003

function [SysStateDesc ErrorString]=FindSysStateDesc(SysStateNos,GenInfo);

for n=1:length(SysStateNos)
    SysStateDesc(n,:)='(text N/A)'; % this will hopefully be overwritten later
end

load([fileparts(which('balonsite18')) '\private\mainconfig.mat'])  % just to get primary and alternative VMP directory names


[SysStateFiles,VmpSubDir,ReleaseDir]=VDAT.CompileSysStateFullPathName(GenInfo,UserSettings);



% find the file with SysState descriptions based on primary VMP directory
SysStateFile=SysStateFiles.VMPHomeDir;
fid = fopen(SysStateFile,'r');

% COMMENT BY RABAD : The code in this if-condition is taking long time when
% there are Syst-states. In future, this processing time has to be brought down
if fid==-1 % if not succesfull file open, try to open directory based on alternative VMP directory
    SysStateFile=SysStateFiles.AltVMPHomeDir;
    fid = fopen(SysStateFile,'r');
end

if fid~=-1  % if succesfull file open
    SysStatesInFile = [];
    try   % using try-catch just as a precaution, if file format is not as expected 
        SysStateCell = VDAT.textread_compiler(SysStateFile,'%s','delimiter','\n','whitespace','');  % read whole file into cell array
        SysStateStringArr=char(SysStateCell);                % convert to strings 
        SysStatesInFile = str2num(SysStateStringArr(:,1:3)); % the first 3 characters in each line, i.e. the sysstate numbers
        
        if ~isempty(SysStatesInFile) % if file format is 'strange', str2num gives an empty matrix
            SysStateIx = find(SysStatesInFile == SysStateNos);
            
            if ~isempty(SysStateIx) % SysStateIx can be [], if e.g. SysStateNos == 0
                SysStateDesc = SysStateStringArr(SysStateIx,5:end-1);  % the last character in each line is '!' or '|'
            end
        end
    catch
        % disp('Caught in try-catch in FindSysStateDesc');
        % disp(lasterr);
        % do nothing    
    end   % end try-catch statement
    fclose(fid);
    ErrorString=[];
    if isempty(SysStatesInFile) % if file could be opened but format is 'strange', str2num gives an empty matrix
        Estr(1)={'The file containing the sysstate descriptions was found to be of wrong format !' };
        Estr(2)={' '};
        Estr(3)={SysStateFile};
        Estr(4)={' '};
        Estr(5)={'Contact the SW Applications group in the Turbines R&D dept. to get the problem corrected' };
        ErrorString=Estr;
    end
elseif fid==-1
    Estr(1)={'The file containing the sysstate descriptions could not be found in either:' };
    Estr(2)={' '};
    Estr(3)={SysStateFiles.VMPHomeDir};
    Estr(4)={'or' };
    Estr(5)={SysStateFiles.AltVMPHomeDir};
    Estr(6)={' '};
    Estr(7)={'Refer to the VDAT Getting Quck Started Guide for information on which directories are default' };    
    Estr(8)={'If the problem persists (and you have acces to the default directories)'};
    Estr(9)={'contact the SW Applications group in the Turbines R&D dept. to get the problem corrected' };    
    ErrorString=Estr;
end

    