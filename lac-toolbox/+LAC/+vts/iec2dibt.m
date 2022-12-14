function iec2dibt(prepfile,varargin)
% function to create a DIBt prep file based on a input prep file. 
% -------------------------------------------------------------------------
% Description:  Reads a prep setup file and correct it according to the
%               DIBt iterpretation document 0038-8006.
%               Mk2 follows 0038-8006.V02
%               Mk3 follows 0038-8006.V05
%                 
% Inputs:       Prep input file using full path. If HH, WZ or GK is missing
%               the user is asked for inputs. 
%               By default the ALT and NSI is not applied.
%
% Example1:     iec2dibt('input_path')
% Example2:     iec2dibt('input_path','HH',100,'WZ',2,'GK',2,'ALT','NSI')
%
% Output:       The output is written in the same folder as the input file
%               A WND part file with corrected Vavg. Used in the prep file 
%               A DIBt corrected prep file

%% Read input
    useALT = 0;
    useNSI = 0;
    useMk2 = 0;
    [workdir, filename, ext]= fileparts(prepfile);
    prepfilename=[filename ext];
    cd(workdir);

    if nargin > 1
        for i=1:nargin-1
            n=varargin{i};
            if ischar(n)
                n=lower(n);
                switch n
                    case 'hh'
                        HH = varargin{i+1};
                    case 'wz'
                        WindZone = varargin{i+1};
                    case 'gk'
                        TerrainCategory = varargin{i+1};
                    case 'alt'
                        useALT = 1;
                    case 'nsi'
                        useNSI = 1;
                    case 'mk2'
                        useMk2 = 1;
                    case 'mk3'
                        useMk2 = 0;
                    otherwise
                        outfolder = varargin{i};
                end
            end
        end
    end
    % read prep input file
    fid=fopen(prepfile,'r');
    PrepC = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    
    % get Vrat from prep file
    iline = find(strncmpi('Vrat',PrepC{1},length('Vrat'))==1,1);
    C = strsplit_LMT(PrepC{1}{iline});
    Vrat = str2num(C{2});
    
    % input for WpDIBt script
    Vrat = 2.*round(Vrat/2); % round to neares even number.
    N_dec1 = 2;
    N_dec2 = 3;
    k = 2;

    if exist('HH','var') && exist('WindZone','var') && exist('TerrainCategory','var')
            
    else
        %ask for input Mk version
        choice = questdlg('Select Mk version','Mk version','Mk2','Mk3','Mk3');
        switch choice
            case 'Mk2'
                useMk2 = 1;
            case 'Mk3'
                useMk2 = 0;
        end
        
        %ask for input HH, WZ, GK
        name={'HH','WZ','GK'};
        promt={'Enter hub height','Select wind zone: [1=WZ1, 2=WZ2, 3=WZ3, 4=WZ4]','Select terain category: [1=GK1, 2=GK2, 3=GK3, 4=GK4]'};
        for i=1:length(name)
            answer = inputdlg(promt{i},name{i});
            input(i)=str2num(answer{1});
        end
        
        choice = questdlg('Use Alternative approach?','ALT approach','Yes','No','No');
        switch choice
            case 'Yes'
                useALT = 1;
            case 'No'
                useALT = 0;
        end
        
        choice = questdlg('Use NSI climate?','NSI climate','Yes','No','No');
        switch choice
            case 'Yes'
                useNSI = 1;
            case 'No'
                useNSI = 0;
        end

        HH = input(1);
        WindZone = input(2);
        TerrainCategory = input(3);
    end
    % get setup change definitions
    DIBt = struct;
    DIBt = GetDIBtInterpretation(useMk2);    
    
    DIBt.HH = HH;
    DIBt.WZ = WindZone;
    DIBt.GK = TerrainCategory;
    DIBt.Vrat = Vrat;

    
    
    OutStruct = WpDIBt2012_no_gui('HH', DIBt.HH, 'WindZone', DIBt.WZ, 'TerrainCategory', ...
            DIBt.GK, 'Vrat', DIBt.Vrat, 'N_dec1', N_dec1, 'N_dec2', N_dec2, 'k', k, 'Hours_ice', DIBt.IceH);
    
    if ~useALT
        % normal DIBt
        DIBt.clm.V50 = OutStruct.OutStructCalculateDIBtWindSpeeds.V50;
        DIBt.clm.VE50 = OutStruct.OutStructCalculateDIBtWindSpeeds.VE50;
        DIBt.clm.V1 = OutStruct.OutStructCalculateDIBtWindSpeeds.V1;
        DIBt.clm.VE1 = OutStruct.OutStructCalculateDIBtWindSpeeds.VE1;
        DIBt.clm.TI = OutStruct.OutStructCalculateDIBtWindSpeeds.TI;
        if ~useNSI
            DIBt.clm.Vavg = OutStruct.OutStructCalculateDIBtWindSpeeds.Vave;
            DIBt.clm.Frac = OutStruct.frac;
        else
            DIBt.clm.Vavg = OutStruct.OutStructCalculateDIBtWindSpeeds.VaveNSI;
            DIBt.clm.Frac = OutStruct.fracNSI;            
        end    
    else
        % Alternative DIBt
        DIBt.clm.V50 = OutStruct.OutStructCalculateDIBtWindSpeeds.AV50;
        DIBt.clm.VE50 = OutStruct.OutStructCalculateDIBtWindSpeeds.AVE50;
        DIBt.clm.V1 = OutStruct.OutStructCalculateDIBtWindSpeeds.AV1;
        DIBt.clm.VE1 = OutStruct.OutStructCalculateDIBtWindSpeeds.AVE1;
        DIBt.clm.TI = OutStruct.OutStructCalculateDIBtWindSpeeds.ATI;
        if ~useNSI
            DIBt.clm.Vavg = OutStruct.OutStructCalculateDIBtWindSpeeds.AVave;
            DIBt.clm.Frac = OutStruct.Afrac;
        else
            DIBt.clm.Vavg = OutStruct.OutStructCalculateDIBtWindSpeeds.AVaveNSI;
            DIBt.clm.Frac = OutStruct.AfracNSI;            
        end
    end
   
    % correct DIBt frac change
    DIBt.DLC(1).name = sprintf('%s%d',DIBt.DLC(1).name,Vrat);
    DIBt.DLC(1).val = DIBt.clm.Frac;
    
    for i = 1:length(DIBt.DLC)
        if strcmp(DIBt.DLC(i).type,'TI50')
            DIBt.DLC(i).val = DIBt.clm.TI;
        end
    end

    
    DIBt.name = sprintf('WZ%dGK%d',WindZone,TerrainCategory);
    WNDfilename = sprintf('DIBt%d_2012_GK%d',WindZone,TerrainCategory);
    miscstr='';
    if useALT
        DIBt.name = sprintf('%s_ALT',DIBt.name);
        WNDfilename = sprintf('%s_ALT',WNDfilename);
        miscstr = sprintf('%s ALT',miscstr);
    end
    if useNSI
        DIBt.name = sprintf('%s_NSI',DIBt.name);
        WNDfilename = sprintf('%s_NSI',WNDfilename);
        miscstr = sprintf('%s NSI',miscstr);
    end
    hhstr = sprintf('%0.1f',HH);
    hhstrc = strrep(hhstr, '.', '_');
    WNDfilename = sprintf('%s_HH%s.001',WNDfilename,hhstrc);
    WNDfile = fullfile(workdir,WNDfilename);
    
    WriteWNDfile(WNDfile,DIBt,hhstr,miscstr);

    % write new prep file
    % rename prep file to DIBt naming
    idx0=strfind(lower(filename),'iec');
    if isempty(idx0)%find DIBt
        idx0=strfind(lower(filename),'dibt');
    end
    if ~isempty(idx0)%rename
        idx1 = strfind(lower(filename),'_');
        [val idx]=max(idx1>idx0);
        skey=filename(idx0:idx1(idx)-1);
        newprepfile = strrep(filename, skey, DIBt.name);
        if strcmp(filename,newprepfile)
            newprepfile = DIBt.name;
        end
        newprepfile = sprintf('%s%s',newprepfile,ext);
    else
        newprepfile = sprintf('%s_%s%s',filename,DIBt.name,ext);
    end
    
    PrepC = ChangePrepfile(PrepC,DIBt,WNDfile);
    
    WritePrepfile(fullfile(workdir,newprepfile),PrepC);

end

function DIBt = GetDIBtInterpretation(useMk2)
%% DIBt load case definition changes
% s=structure 

% changes to load cases
% s.DLC().name          = string
% s.DLC().type          = 'hour' / 'freq' / 'TI50' / 'PLF' / 'opt' /
% s.DLC().val           = value /string
% s.DLC().optname       = string

% changes to option
% s.OPT().name          = string
% s.OPT().val           = value
% s.OPT().sval          = % search to replace val

DIBt=struct;
DIBt.IceH = 3360;

DIBt.DLC(1).name = '11';
DIBt.DLC(1).type = 'frac';
DIBt.DLC(1).val = 'dummy';

if useMk2
    DIBt.DLC(2).name = '12IcVice';
    DIBt.DLC(2).type = 'hour';
    DIBt.DLC(2).val = 3360;
    
    DIBt.DLC(3).name = '21RPY';
    DIBt.DLC(3).type = 'opt';
    DIBt.DLC(3).optstr = 'time 0.01 120 10 100';
    
    DIBt.DLC(4).name = '21YE30Vr';
    DIBt.DLC(4).type = 'hour';
    DIBt.DLC(4).val = 200;
    
    DIBt.DLC(5).name = '2YE18Vo';
    DIBt.DLC(5).type = 'hour';
    DIBt.DLC(5).val = 40;
    
    DIBt.DLC(5).name = '22VOGVr';
    DIBt.DLC(5).type = 'freq';
    DIBt.DLC(5).val = 140;
    
    DIBt.DLC(5).name = '22VOGVo';
    DIBt.DLC(5).type = 'freq';
    DIBt.DLC(5).val = 60;
    
    DIBt.DLC(6).name = '31PRVr';
    DIBt.DLC(6).type = 'freq';
    DIBt.DLC(6).val = 1000;
    
    DIBt.DLC(7).name = '41RPVr';
    DIBt.DLC(7).type = 'freq';
    DIBt.DLC(7).val = 500;
    
    DIBt.DLC(8).name = '41RPVo';
    DIBt.DLC(8).type = 'freq';
    DIBt.DLC(8).val = 500;

    DIBt.DLC(9).name = '41RCSVr';
    DIBt.DLC(9).type = 'freq';
    DIBt.DLC(9).val = 500;
    
    DIBt.DLC(10).name = '41RCSVo';
    DIBt.DLC(10).type = 'freq';
    DIBt.DLC(10).val = 500;
    
    DIBt.DLC(11).name = '61E50a000';
    DIBt.DLC(11).type = 'PLF';
    DIBt.DLC(11).val = 1.50;
    
    DIBt.DLC(12).name = '61E50';
    DIBt.DLC(12).type = 'TI50';
    DIBt.DLC(12).val = 0; %dummy value

    DIBt.DLC(13).name = '62E50';
    DIBt.DLC(13).type = 'TI50';
    DIBt.DLC(13).val = 0; %dummy value

    DIBt.DLC(14).name = '63E1';
    DIBt.DLC(14).type = 'TI50';
    DIBt.DLC(14).val = 0; %dummy value

    DIBt.DLC(15).name = '71Pmbr';
    DIBt.DLC(15).type = 'TI50';
    DIBt.DLC(15).val = 0; %dummy value

    DIBt.DLC(16).name = '82LTPT';
    DIBt.DLC(16).type = 'TI50';
    DIBt.DLC(16).val = 0; %dummy value
else  
    DIBt.DLC(2).name = '12IceFvrat';
    DIBt.DLC(2).type = 'hour';
    DIBt.DLC(2).val = 3360;
    
    DIBt.DLC(3).name = '31PRVr';
    DIBt.DLC(3).type = 'freq';
    DIBt.DLC(3).val = 1000;

    DIBt.DLC(4).name = '41RPVr';
    DIBt.DLC(4).type = 'freq';
    DIBt.DLC(4).val = 500;

    DIBt.DLC(5).name = '41RCSVr';
    DIBt.DLC(5).type = 'freq';
    DIBt.DLC(5).val = 500;

    DIBt.DLC(6).name = '61E50a000';
    DIBt.DLC(6).type = 'PLF';
    DIBt.DLC(6).val = 1.50;

    DIBt.DLC(7).name = '61E50';
    DIBt.DLC(7).type = 'TI50';
    DIBt.DLC(7).val = 0; %dummy value

    DIBt.DLC(8).name = '62E50';
    DIBt.DLC(8).type = 'TI50';
    DIBt.DLC(8).val = 0; %dummy value

    DIBt.DLC(9).name = '63E11';
    DIBt.DLC(9).type = 'TI50';
    DIBt.DLC(9).val = 0; %dummy value

    DIBt.DLC(10).name = '71Pmbr';
    DIBt.DLC(10).type = 'TI50';
    DIBt.DLC(10).val = 0; %dummy value

    DIBt.DLC(11).name = '82LTPT';
    DIBt.DLC(11).type = 'TI50';
    DIBt.DLC(11).val = 0; %dummy value
    
    DIBt.OPT(1).name = 'rho' % search for option
    DIBt.OPT(1).val = '1.273'; %search val to replace
    DIBt.OPT(1).sval = '1.325'; % search to replace val
end
end


function WriteWNDfile(WNDfile,sDIBt,hhstr,str)
    DIBt = sDIBt;
    fid=fopen(WNDfile,'w');
    fprintf(fid,'DIBt%d GK%d%s %s %s %s\r\n',DIBt.WZ,DIBt.GK,str,hhstr,upper(getenv('username')),datestr(now,'yyyy-mm-dd'));
    fprintf(fid,'ieced3    1                            reference standard, windpar\r\n');
    fprintf(fid,'ieced3 1 0.16 2                        iecgust windpar, iecgust turbpar, a (dummy if IECed3)\r\n');
    fprintf(fid,'ieced3 0.16 2 0                        Turbulence standard, turbpar, a (dummy if IECed3), additional factor\r\n');
    fprintf(fid,'0.0  0.0  3    5                       Iparked Ipark0, row spacing, park spacing\r\n');
    fprintf(fid,'0.7   0.5                              I2,I3\r\n');
    fprintf(fid,'8                                      Terrain slope\r\n');
    fprintf(fid,'0.2                                    Wind shear exponent\r\n');
    fprintf(fid,'1.225 1.225                            rhoext rhofat\r\n');
    fprintf(fid,'%3.2f   2.0   20                        Vav	k	lifetime (for Weibull Calculation)\r\n\r\n',DIBt.clm.Vavg);
    fprintf(fid,'Original data:\r\nChecked:\r\n');
    fprintf(fid,'%s \r\n',upper(getenv('username')));
    fclose(fid);
end

function WritePrepfile(file,PrepC)
    fid=fopen(file,'w');
    [nrows,ncols] = size(PrepC{1});
    for row = 1:nrows
        fprintf(fid,'%s\r\n',char(PrepC{1}(row)));
    end
    fclose(fid);
end    

function PrepC = ChangePrepfile(PrepC,DIBt,WNDfilename)
    %% id line
    str = PrepC{1}(1);
    idx=cell2mat(strfind(lower(str),'iec'));
    if isempty(idx)%find DIBt
        idx=cell2mat(strfind(lower(str),'wz'));
    end
    if ~isempty(idx)%find DIBt
        idstr = sprintf('%s%s',str{1}(1:idx-1),DIBt.name);
        PrepC{1}{1} = char(idstr);
    end

    %% WND
    key='WND ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    str = sprintf('WND %s',WNDfilename); 
    PrepC{1}{keyline} = char(str);
    
    %% PL
    key='_PL ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    str = char(PrepC{1}(keyline));
    resS = findtokeninstring(str,'iec');
    if ~isempty(resS.idx)
        resS.strC{resS.idx} = strrep(lower(resS.strC{resS.idx}), 'iec', 'dibt');
        PrepC{1}{keyline} = char(strjoin_LMT(resS.strC));
    end
    
    %% V50
    key='V50 ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    strC = strsplit_LMT(char(PrepC{1}(keyline)));
    sstr = strC(2);
    rstr = sprintf('%1.1f',DIBt.clm.V50);
    str = strrep(char(PrepC{1}(keyline)), sstr, rstr); 
    PrepC{1}{keyline} = char(str);
    
    %% VE50
    key='VE50 ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    strC = strsplit_LMT(char(PrepC{1}(keyline)));
    sstr = strC(2);
    rstr = sprintf('%1.1f',DIBt.clm.VE50);
    str = strrep(char(PrepC{1}(keyline)), sstr, rstr); 
    PrepC{1}{keyline} = char(str);
    
    %% V1
    key='V1 ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    strC = strsplit_LMT(char(PrepC{1}(keyline)));
    sstr = strC(2);
    rstr = sprintf('%1.1f',DIBt.clm.V1);
    str = strrep(char(PrepC{1}(keyline)), sstr, rstr); 
    PrepC{1}{keyline} = char(str);
    
    %% VE1
    key='VE1 ';
    keyline = find(strncmpi(key,PrepC{1},length(key))==1,1);
    strC = strsplit_LMT(char(PrepC{1}(keyline)));
    sstr = strC(2);
    rstr = sprintf('%1.1f',DIBt.clm.VE1);
    str = strrep(char(PrepC{1}(keyline)), sstr, rstr); 
    PrepC{1}{keyline} = char(str);
    
    %% DLC changes
    for iDLC = 1:length(DIBt.DLC)
        IndexC = strfind(PrepC{1}, DIBt.DLC(iDLC).name);
        Indexline = find(not(cellfun('isempty', IndexC)));
        if isempty(Indexline)
            errstr = sprintf('Search key: %s not found',DIBt.DLC(iDLC).name);
            h = msgbox(errstr);
            waitfor(h)
        end
        for i = 1:length(Indexline)
            switch lower(DIBt.DLC(iDLC).type);
                case {'freq', 'hour'}
                    str = char(PrepC{1}(Indexline(i)+1));
                    resS = findtokeninstring(str,'freq');
                    if isempty(resS.idx) %try find hour
                        resS = findtokeninstring(str,'hour');
                    end  
                    resS.strC{resS.idx} = DIBt.DLC(iDLC).type;
                    resS.strC{resS.idx+1} = sprintf('%1.0f ',DIBt.DLC(iDLC).val); 
                    PrepC{1}{Indexline(i)+1} = char(strjoin_LMT(resS.strC));
                case 'plf'
                    str = char(PrepC{1}(Indexline(i)+1));
                    resS = findtokeninstring(str,'lf');
                    rstr = sprintf('%1.2f ',DIBt.DLC(iDLC).val);
                    resS.strC{resS.idx+1} = rstr;
                    PrepC{1}{Indexline(i)+1} = char(strjoin_LMT(resS.strC));
                case 'ti50'
                    str = char(PrepC{1}(Indexline(i)+2));
                    resS = findtokeninstring(str,'turb');
                    sstr = resS.strC(resS.idx+1);
                    rstr = sprintf('%1.3f ',DIBt.DLC(iDLC).val);
                    resS.strC{resS.idx+1} = rstr; 
                    PrepC{1}{Indexline(i)+2} = char(strjoin_LMT(resS.strC));
                case 'rho' 
                    str = char(PrepC{1}(Indexline(i)+2));
                    resS = findtokeninstring(char(PrepC{1}(Indexline(i)+2)),'rho');
                    sstr = resS.strC(resS.idx+1);
                    rstr = sprintf('%1.3f ',DIBt.DLC(iDLC).val);
                    resS.strC{resS.idx+1} = rstr; 
                    PrepC{1}{Indexline(i)+2} = char(strjoin_LMT(resS.strC));
                case 'frac'
                    str = char(PrepC{1}(Indexline(i)+1));
                    resS = findtokeninstring(str,'weib');
                    sstr = resS.strC(resS.idx+3);
                    rstr = sprintf('%1.2f ',DIBt.DLC(iDLC).val);
                    resS.strC{resS.idx+3} = rstr; 
                    PrepC{1}{Indexline(i)+1} = char(strjoin_LMT(resS.strC));
                case 'opt'
                    str = char(PrepC{1}(Indexline(i)+2));
                    optstrC = strsplit_LMT(DIBt.DLC(iDLC).optstr);
                    resS = findtokeninstring(str,optstrC{1});
                    if ~isempty(resS.idx) %replace option str
                        for j = 1:length(optstrC)
                            resS.strC{resS.idx-1+j} = optstrC{j};
                        end
                        str = char(strjoin_LMT(resS.strC));
                    else %append option str
                        str = sprintf('%s %s',str,DIBt.DLC(iDLC).optstr)
                    end
                    PrepC{1}{Indexline(i)+2} = char(str);
            end  
        end
    end
    
    if isfield(DIBt,'OPT')
        for iOPT = 1:length(DIBt.OPT)
            IndexC = strfind(PrepC{1}, DIBt.OPT(iOPT).name);
            Indexline = find(not(cellfun('isempty', IndexC)));
            if isempty(Indexline)
                errstr = sprintf('Search key: %s not found',DIBt.OPT(iOPT).name);
                h = msgbox(errstr);
                waitfor(h)
            end

            for i = 1:length(Indexline)
                str = char(PrepC{1}(Indexline(i)));
                resS = findtokeninstring(str,DIBt.OPT(iOPT).name);
                strC = strsplit_LMT(DIBt.OPT(iOPT).val);
                if isfield(DIBt.OPT(iOPT),'sval')
                    sstrC = strsplit_LMT(DIBt.OPT(iOPT).sval);
                end

                if resS.idx+length(strC) <= length(resS.strC)
                    for j = 1:length(strC)
                        if ~isfield(DIBt.OPT(iOPT),'sval') 
                            resS.strC{resS.idx+j} = strC{j};
                        else
                            if strcmp(resS.strC{resS.idx+j},sstrC{j})
                                resS.strC{resS.idx+j} = strC{j};
                            end
                        end         
                    end
                end
                PrepC{1}{Indexline(i)} = char(strjoin_LMT(resS.strC));
            end
        end
    end
end

function string = findtokeninstring(str,token)
    string = struct;
    strC = strsplit_LMT(str);
    keyC = cellfun(@(s) findstr(lower(char(s)),token), strC,'UniformOutput',false);
    keyI = find(not(cellfun('isempty', keyC)));
    string.strC = strC;
    string.idx = keyI;
end
