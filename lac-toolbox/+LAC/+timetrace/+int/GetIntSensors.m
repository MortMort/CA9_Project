function [SensorSym, SensorDesc, AddOut] = GetIntSensors(IntFile,GenInfo, UserSettings)
% GetIntSensors retrieves information from a sensor list which describes the contents of *.int files.
% In this context sensor lists are files describing the contents of *.int files from:
%   
%   - Vestas standard measurement system (used for prototype measurements)
%     (Data are NOT calibrated, calibration info is in the sensor list called CaliList)
%
%   - Risoe measurement system (The data are not originally in the int format, but they are converted to this format)
%     (Data are calibrated) 
%
%   - Vestas Turbine Simulator (VTS)
%     (Data are calibrated) 
%
%  The are two type of sensor list formats, the first format (Calilist) is different from the last two.
%
%  This function is used in connection with VDAT
%
%  Syntax:  [SensorSym, SensorDesc, AddOut] = GetIntSensors(IntFile, GenInfo, UserSettings);
%
%  Inputs:	
%
%         IntFile         : String specifying the filename of the *.int file
%                           The sensorlist file is selected with a standard Open File GUI
%         
%         GenInfo         : Struct containing general info about the *.int file. Use readint to obtain this.
%
%         UserSettings    : Struct with user settings. 
%                           UserSettings.SensorListConfig can be 'Always Ask' or 'Auto Detection'
%
%
%  Outputs:
%
%         SensorSymbol    : char array containing the sensor symbols
%
%         SensorDesc      : char array containing the sensor descriptions
%
%         AddOut          : Struct containing additional outputs:
%                           AddOut.Header       Cell array of strings containing the Sensor list header
%                           AddOut.Gain         Vector containing the gain factors (for later calibration)
%                           AddOut.Offset       Vector containing the offset values (for later calibration)
%                           AddOut.Unit         Cell array of strings containing the measurement units for each sensor
%                           AddOut.Name         Cell array of strings containing sensor symbols
%                           AddOut.Description  Cell array of strings containing sensor descriptions
%                           AddOut.ErrorString  String for error handling, if:
%                                                - [] The file was read succesfully
%                                                - ['The Specified file: ' SensorFile ' could not be opened'];
%                           AddOut.SensListType String describing which of the two formats the files belongs to:
%                                               'CaliList' or 'SensorList'
%
%                           For sensor list of the Calilist type only:  
%                           AddOut.ChannelNo    Vector containing the channel numbers 
%                                               (specifying which data logger the signal stems from)
%                           
% 
%          
%
%
%   Vestas Wind Systems A/S
%   PBC	12th of July 2002
%
% Revised by JEB, 23/7 2002, for use in VDAT
% Revised by JEB 23/12 2003, for use in VDAT 2.2
% Revised by UBL 4/4 2005, Feature added: Sensorlist see as a maximumlist

ErrorChkOk = 1;

% Find expected path to sensorfile ( = path to *.int file)
SepIx = max(findstr(IntFile,'\')); % index for last directory seperator
if ~isempty(SepIx)
    SensorFilePath = IntFile(1:SepIx);
else
    SensorFilePath = pwd;
end


% -------------------------------------------------------------------------------------------------
% New code, VDAT 2.1.04 and later
% -------------------------------------------------------------------------------------------------

switch UserSettings.SensorListConfig
    case 'Always Ask' % manual selection
        [FileName,Path]=getfiles('*.*','Select Sensor/Cali List file',SensorFilePath);
        if FileName == 0 % if "Cancel"
            for n=1:GenInfo.NoOfChannels
                SensorDescCell(n)={['Undef' num2str(n)]};
            end
            SensorDesc=char(SensorDescCell);
            SensorSym=SensorDesc;
            AddOut=[]; % file was not read due to cancelling
            return
        else
            SensorFile = strcat(Path, FileName);
        end
        
    case 'Auto Detection'
        DirResult1 = dir([SensorFilePath '*.cal']);
        DirResult2 = dir([SensorFilePath '*sensor*']);
        
        nSensorFile = length(DirResult1) + length(DirResult2); % no. of possible sensor files/ cali-lists
        
        switch nSensorFile
            case 0  % 0 files found. Same code as 'Always Ask'
                [FileName,Path]=getfiles('*.*','Select Sensor/Cali List file',SensorFilePath);
                if FileName == 0 % if "Cancel"
                    for n=1:GenInfo.NoOfChannels
                        SensorDescCell(n)={['Undef' num2str(n)]};
                    end
                    SensorDesc=char(SensorDescCell);
                    SensorSym=SensorDesc;
                    AddOut=[]; % file was not read due to cancelling
                    return
                else
                    SensorFile = strcat(Path, FileName);
                end
                
            case 1 % exactly 1 file found, use that file
                if length(DirResult1)==1 % a '*.cal' file has been found
                    FileName = DirResult1.name;
                else % a '*sensor*.*' file has been found
                    FileName = DirResult2.name;
                end
                SensorFile = strcat(SensorFilePath, FileName);
                
            otherwise % if more than 1 file was found
                if length(DirResult1)==0 % only '*sensor*.*' files present, put '*sensor*.*' first in file specification 
                    SensorFileSpec = {'*sensor*.*', 'Sensor-list (*sensor*.*)'; '*.cal', 'Cali-list (*.cal)'};
                else  % if '*.cal' files exist, put them first in the list
                    SensorFileSpec = {'*.cal', 'Cali-list (*.cal)'; '*sensor*.*', 'Sensor-list (*sensor*.*)'};
                end
                [FileName, Path] = getfiles(SensorFileSpec, 'Select Sensor/Cali List file',SensorFilePath);
                if FileName == 0 % if "Cancel"
                    for n=1:GenInfo.NoOfChannels
                        SensorDescCell(n)={['Undef' num2str(n)]};
                    end
                    SensorDesc=char(SensorDescCell);
                    SensorSym=SensorDesc;
                    AddOut=[]; % file was not read due to cancelling
                    return
                else
                    SensorFile = strcat(Path, FileName);
                end
                
        end % end switch nSensorFile
      
end % end switch UserSettings.SensorListConfig


% ------------------------------------------------------------------------------------------------
% end New code, VDAT 2.1.04 and later
% ------------------------------------------------------------------------------------------------

%FID=fopen(strtrim(SensorFile),'r'); 
%tmp = textscan(FID,'%s',2,'delimiter', '\n');
%tmp = textscan(FID,'%d %f %f %f %f %s %s %[^\n]',-1);
%fclose(FID)
%TBD: Need to optimize speed performance here

fptr=fopen(deblank(SensorFile),'r'); 

if fptr ~= -1       % If the file was successfully opened
    %FILE READING 
    % IDENTIFY THE NUMBER OF HEADER LINES AND READ THEM
    LastHeaderLineNotReached=1;
    Nheader=0; % No. of lines in header, initialisation
    NheaderMax=10; % Maximum no of headerlines
    while LastHeaderLineNotReached
        Nheader=Nheader+1;
        tmpline = fgetl(fptr);
        tmpline = deblank(tmpline);
        Header(Nheader)={tmpline}; 
        LastLineUK=(findstr(lower(tmpline),'no') & findstr(lower(tmpline),'offset') & findstr(lower(tmpline),'name')); if isempty(LastLineUK); LastLineUK=0;end;
        LastLineDK=(findstr(lower(tmpline),'no') & findstr(lower(tmpline),'offset') & findstr(lower(tmpline),'navn')); if isempty(LastLineUK); LastLineDK=0;end;
        if isempty(findstr('sensor',lower(SensorFile))) % if file name does not consist the string 'sensor', then assume it is a cali-list
            SensListType='CaliList';
         else
            SensListType='SensorList';
        end
        if  LastLineUK | LastLineDK % then last headerline is reached
            LastHeaderLineNotReached=0;
        end
        if Nheader>NheaderMax % then it is assumed that the header is not of the right format
            ErrorTxt(1)={'The sensor list header is not of the correct format, Either is:'};
            ErrorTxt(2)={[' * The max. no. of header lines (' num2str(NheaderMax) ') exceeded or']};
            ErrorTxt(3)={' * The last headerline does not contain the following keywords: "no", "unit" and "name"'};
            Herrdlg = errordlg(ErrorTxt,'ERROR : Inconsistent sensorlist / cali-list','modal');
            fclose(fptr);
            for n=1:GenInfo.NoOfChannels
                SensorDescCell(n)={['Undef' num2str(n)]};
            end
            SensorDesc=char(SensorDescCell);
            SensorSym=SensorDesc;
            AddOut.ErrorString='Inconsistent sensorlist / cali-list'; 
            return
        end
    end
    fclose(fptr);
    
    % -----------------------------------
    % Old Code VDAT 2.1.03 and earlier, VDAT 2.5 and later 
    % -----------------------------------
    % IDENTIFY WHICH SESNSORLIST TYPE IS BEING READ
     if ~isempty(findstr('calilist',lower(char(Header(1))))) % the sensorlist type if it is a calilist must contain the word calilist in the 1st headerline
         SensListType='CaliList';
     else
         SensListType='SensorList';
     end
    % ---------------------------------------
    % end Old Code VDAT 2.1.03 and earlier, VDAT 2.5 and later
    % ---------------------------------------

    % -----------------------------------
    % New code VDAT 2.1.04 and later (2.4) 
    % Old code is better, UBL
    % -----------------------------------
    % IDENTIFY SENSORLIST TYPE 
%    if isempty(findstr('sensor',lower(SensorFile))) % if file name does not consist the string 'sensor', then assume it is a cali-list
%        SensListType='CaliList';
%    else
%        SensListType='SensorList';
%    end
    % -----------------------------------
    % end New code VDAT 2.1.04 and later (2.4)
    % -----------------------------------
    
    % READ THE SENSOR INFORMATION
    % The sensorlist must contain 8 columns of information and the first 5 must be numbers and the last 3 must be strings !
    % Columns 6 and 7 Unit and Symbol respectively must not contain spaces !
    switch SensListType
    case 'CaliList' 
        % AddOut.No added by UBL
        [AddOut.No,AddOut.Offset,AddOut.Gain,AddOut.ChannelNo,AddOut.Unit,AddOut.Name,AddOut.Description]=...
            textread_compiler(SensorFile,'%f %*f %f %f %f %[^ ] %[^ ] %s  ','delimiter','\n','headerlines',Nheader);
        % -----------------------------------
        % Added code VDAT 2.5 and later, by ubl
        % sorting according to the GenInfo.CrossrefTable
        % Adding unknown channels
        % Removing extra channels
        % -----------------------------------
        
        AddOutTMP = AddOut;
        clear('AddOut');
        for iCount=1:GenInfo.NoOfChannels,
            if sum(GenInfo.CrossrefTable(iCount) == AddOutTMP.No) == 0,
                AddOut.No(iCount) = GenInfo.CrossrefTable(iCount);
                AddOut.Offset(iCount) = 0;
                AddOut.Gain(iCount) = 1;
                AddOut.ChannelNo(iCount) = GenInfo.CrossrefTable(iCount);
                AddOut.Unit(iCount) = {'V'};
                AddOut.Name(iCount) = {['Undef' num2str(GenInfo.CrossrefTable(iCount))]};
                AddOut.Description(iCount) = {['Undefined Description ch' num2str(GenInfo.CrossrefTable(iCount))]};
                
            elseif sum(GenInfo.CrossrefTable(iCount) == AddOutTMP.No) == 1,
                jCount = (GenInfo.CrossrefTable(iCount) == AddOutTMP.No).*([1:length(AddOutTMP.No)]');
                jCount(jCount == 0) = [];
                
                AddOut.No(iCount) = GenInfo.CrossrefTable(iCount);
                AddOut.Offset(iCount) = AddOutTMP.Offset(jCount);
                AddOut.Gain(iCount) = AddOutTMP.Gain(jCount);
                AddOut.ChannelNo(iCount) = AddOutTMP.ChannelNo(jCount);
                AddOut.Unit(iCount) = AddOutTMP.Unit(jCount);
                AddOut.Name(iCount) = AddOutTMP.Name(jCount);
                AddOut.Description(iCount) = AddOutTMP.Description(jCount);
            else
                AddOut.No(iCount) = GenInfo.CrossrefTable(iCount);
                AddOut.Offset(iCount) = 0;
                AddOut.Gain(iCount) = 1;
                AddOut.ChannelNo(iCount) = GenInfo.CrossrefTable(iCount);
                AddOut.Unit(iCount) = {'V'};
                AddOut.Name(iCount) = {['Err' num2str(GenInfo.CrossrefTable(iCount))]};
                AddOut.Description(iCount) = {['Sensor-file ERROR ch' num2str(GenInfo.CrossrefTable(iCount))]};
                ErrorChkOk = 0;
                s = strvcat(['Two or more, channel No are alike in the Calilist'],['See ch. no. ',num2str(GenInfo.CrossrefTable(iCount))],' and correct the problem!');
                    
            end;
        end
        % -----------------------------------
        % Added code VDAT 2.4.1 and later, by ubl
        % -----------------------------------
        
        % PBC051129 this is added since the below must be 20x1 vectors and this they are not in the offcial VDAT 2.4.1 release
        AddOut.No=AddOut.No';
        AddOut.Offset=AddOut.Offset';
        AddOut.Gain=AddOut.Gain';
        AddOut.ChannelNo=AddOut.ChannelNo';
        AddOut.Unit=AddOut.Unit';
        AddOut.Name=AddOut.Name';
        AddOut.Description=AddOut.Description';
        % end of PBC051129 note 
        for i=1:length(AddOut.Gain) % for each channel
            SensorDescTmp(i)={[deblank(char(AddOut.Unit(i))) ' ' deblank(char(AddOut.Description(i))) ' (' num2str(AddOut.ChannelNo(i)) ')']};
        end
    case 'SensorList' %
        [AddOut.Gain,AddOut.Offset,AddOut.Unit,AddOut.Name,AddOut.Description]=...
            LAC.timetrace.int.textread_compiler(SensorFile,'%*f %f %f %*f %*f %[^ ] %[^ ] %s  ','delimiter','\n','headerlines',Nheader);
        %SensorDesc=[deblank(AddOut.Unit) ' ' deblank(AddOut.Description)];
        for i=1:length(AddOut.Gain) % for each channel
            SensorDescTmp(i)={[deblank(char(AddOut.Unit(i))) ' ' deblank(char(AddOut.Description(i)))]};
        end
    end
    AddOut.Header=Header;
    AddOut.SensListType=SensListType;
    AddOut.SensorFile = SensorFile;
    SensorDesc=strvcat(SensorDescTmp); % convert from cell array to char array
    SensorSym=char(AddOut.Name);    
    AddOut.ErrorString=[]; % file succesfully read
    
else % the file could not be opened
    for n=1:GenInfo.NoOfChannels
        SensorDescCell(n)={['Undef' num2str(n)]};
    end
    SensorDesc=char(SensorDescCell);
    SensorSym=SensorDesc;
    AddOut.ErrorString=['The Specified file: ' IntFile ' could not be opened']; 
end


% Error checking, make sure that :
% - no. of channels in int-file and sensorlist / cali-list is the same
% - all sensor symbols are unique
% if not, make some 'Undef' sensors
% ErrorChkOk = 1; moved to the top
if GenInfo.NoOfChannels ~= length(AddOut.Gain) 
    s1 = (['No. of channels in int-file is ' num2str(GenInfo.NoOfChannels) ]);
    s2 = (['No. of channels in sensorlist / cali-list is ' num2str(length(AddOut.Gain)) ]);
    s3 = ' ';
    s4 = 'Data has not been calibrated !';
    s5 = ' ';
    s = strvcat(s1, s2, s3, s4, s5);
    ErrorChkOk = 0;
end
%if length(unique(SensorSym,'rows')) ~= length(SensorSym(:,1)) /PBC041104 this is replaced
%by the below because if there is only one sensor e.g. Vhub then
%length(unique(SensorSym,'rows')) is 4 and not equal to length(SensorSym(:,1)) eventhough
%the sensors are unique, there is only one !
if length(cellstr(unique(SensorSym,'rows'))) ~= length(SensorSym(:,1))
    s1 = (['No. of channels in sensorlist / cali-list is ' num2str(length(AddOut.Gain)) ]);
    s2 = (['No. of detected, unique sensor symbols is only ' num2str(length(unique(SensorSym,'rows'))) ]);
    s3 = ' ';
    s4 = 'Check sensorlist / cali-list format, ';
    s5 = 'e.g. check spacing between colomns.';
    s6 = ' ';
    s7 = 'Data has not been calibrated !';
    s8 = ' ';
    s9 = 'The Following Sensors are represented more than once:';
    [UniqueSym,UniqueSymIx,dum]=unique(SensorSym,'rows');
    DoubleSymIx=setxor(sort(UniqueSymIx)',[1:1:length(SensorSym(:,1))]);
    for i=1:length(DoubleSymIx)
        TmpIx=strmatch(SensorSym(DoubleSymIx(i),:),{SensorSym})';
        DoubleSymIxStr=num2str(TmpIx);
        s10(i,:)={[SensorSym(DoubleSymIx(i),:) ' are in lines: ' DoubleSymIxStr ]};
    end
    s10 = unique(s10);
    s = strvcat(s1, s2, s3, s4, s5, s6, s7,s8,s9,char(s10));
    ErrorChkOk = 0;    
end
if ErrorChkOk == 0
    uiwait(errordlg(s,'ERROR : Inconsistent sensorlist / cali-list','modal'));
    for n=1:GenInfo.NoOfChannels
        SensorDescCell(n)={['Undef' num2str(n)]};
    end
    SensorDesc=char(SensorDescCell);
    SensorSym=SensorDesc;
    AddOut.ErrorString='Inconsistent sensorlist / cali-list'; 
end
% end error checking
