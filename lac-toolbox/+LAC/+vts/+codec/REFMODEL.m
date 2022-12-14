classdef REFMODEL < LAC.vts.codec.Part_Common & handle
    methods (Static)
        function s = decode(VTSCoder)
            VTSCoder.rewind();
            s = eval(mfilename('class'));
            
            [s.FileName] = VTSCoder.getSource();
            [s.Type] = mfilename;
            
            [s.Header] = VTSCoder.get(true);
            [s.TurbulenceFiles] = VTSCoder.get();
            [s.Rotor]           = VTSCoder.get();
            [s.OffOnshore]      = VTSCoder.get();
            [s.ConverterSystem] = VTSCoder.get();
            [s.PartsFolder]     = VTSCoder.get();
            [s.NameErrorFile]   = VTSCoder.get();
            [s.Flex5]           = VTSCoder.get();
            [s.Flex5Ver]        = VTSCoder.get();
            
            VTSCoder.search('COMPONENTS');
            VTSCoder.skip(1);
            % Clear Map
            s.Files = containers.Map; %MIPOI change
            for i = 1:50
                [parttype, filename] = VTSCoder.getFile();
                if length(parttype) == 3
                    s.Files(parttype) = filename; % preffered use
                    parttype = strrep(parttype,'_',''); % for backward compability only
                    s.(parttype) = filename; % for backward compability only
                else
                    break
                end
            end
            
            VTSCoder.search('GENERAL INPUT');
            VTSCoder.skip(1);
            [~, s.tgust,~] = VTSCoder.get(2);
            [~, s.Prompt,~] = VTSCoder.get(2);
            [~, s.Hhub,~] = VTSCoder.get(2);
            [~, s.PiAvg,~] = VTSCoder.get(2);
            [~, s.YawPos, s.YawOp, s.YawSlip, s.tbd3,~] = VTSCoder.get(2);
            [~, s.PRINTOP, s.NPRINT, s.FILOP, s.NFIL,~] = VTSCoder.get(2);
            [~, s.dt, s.simtime, s.tAvg, s.t0,~] = VTSCoder.get(2);
            [~, s.BladeDOF1, s.BladeDOF2, s.BladeDOF3, s.BladeDOF4, s.BladeDOF5, s.BladeDOF6, s.BladeDamper, s.BladeTorsion,~] = VTSCoder.get(2);
            [~, s.DOF13, s.DOF14, s.DOF15, s.ND, s.Rot,~] = VTSCoder.get(2);
            [~, s.DOF11, s.DOF12, s.DmprX, s.DmprY, s.DmprZ,~] = VTSCoder.get(2);
            [~, s.DOFDownwind1, s.DOFDownwind2, s.DOFDownwind3, s.DOFDownwind4,~] = VTSCoder.get(2);
            [~, s.DOFLateral1, s.DOFLateral2, s.DOFLateral3, s.DOFLateral4,~] = VTSCoder.get(2);
            [~, s.DOF, s.Damper,~] = VTSCoder.get(2);
            [~, s.DOFX, s.DOFY, s.DOFZ, s.DOFRotX, s.DOFRotY, s.DOFRotZ,~] = VTSCoder.get(2);
            [~, s.DynWake, s.DynWTCfak,~] = VTSCoder.get(2);
            [~, s.PPO,~] = VTSCoder.get(2);
            
            VTSCoder.search('WIND SPEEDS');
            VTSCoder.skip(1);
            s.WindSpeeds = containers.Map;
            for i = 1:50
                [type, value,~] = VTSCoder.get(2);
                if isempty(type)
                    continue
                elseif strcmpi(type,'LOAD')
                    break
                else
                    s.WindSpeeds(type) = str2double(value);
                end
            end
            
            %VTSCoder.skip(1); % LOAD CASES
            [s.comments] = VTSCoder.getRemaininglines();
            
            s = s.convertAllToNumeric();
            
            LoadCasesFull = strread(s.comments,'%s','delimiter','\n');
            
            FoundLoadCase = false;
            LCnum = 0;
            LCline = 0;
            for line = 1:length(LoadCasesFull)
                if FoundLoadCase
                    LCline = LCline + 1;
                    s.LoadCases{LCnum}{LCline} = LoadCasesFull{line};
                end
                
                if length(strtrim(LoadCasesFull{line})) > 4 & min([~strcmp(LoadCasesFull{line}(1),'*') ~strcmp(LoadCasesFull{line}(1:3),'end') ~strcmp(LoadCasesFull{line}(1:5),'begin') ])  & FoundLoadCase == false
                    LCnum = LCnum + 1;
                    LCline = LCline + 1;
                    s.LoadCases{LCnum}{LCline} = LoadCasesFull{line};
                    FoundLoadCase = true;
                    dummy = strread(LoadCasesFull{line},'%s');
                    s.LoadCaseNames{LCnum} = dummy{1};
                end
                
                if LCline == 3
                    FoundLoadCase = false;
                    LCline = 0;
                end
            end
        end
    end
    
    methods
        function status = encode(self, filename)
            VTSCoder = LAC.codec.CodecTXT(filename);
            VTSCoder.rewind();
            
            VTSCoder.initialize('part',mfilename, self.getAttributes());
            self = self.convertAllToString();
            
            VTSCoder.setProperty(self.Header);
            VTSCoder.setProperty(self.TurbulenceFiles);
            VTSCoder.setProperty(self.Rotor);
            VTSCoder.setProperty(self.OffOnshore);
            VTSCoder.setProperty(self.ConverterSystem);
            VTSCoder.setProperty({self.PartsFolder}, 27,'library component files');
            VTSCoder.setProperty({self.NameErrorFile}, 27,'name error file');
            VTSCoder.setProperty({self.Flex5}, 27,'name flex5 program');
            VTSCoder.setProperty(self.Flex5Ver);
            
            VTSCoder.setLine('');
            VTSCoder.setLine('COMPONENTS');
            
            fields = self.Files.keys;
            for i=1:length(fields)
                if ~isempty(self.Files(fields{i}))
                    VTSCoder.setFile(fields{i},4,self.Files(fields{i}));
                end
            end
            
            VTSCoder.setLine('');
            VTSCoder.setLine('');
            VTSCoder.setLine('GENERAL INPUT');
            VTSCoder.setPropertyReversed({self.tgust},  13, 'tgust');
            VTSCoder.setPropertyReversed({self.Prompt}, 13, 'Prompt', '            runtime error prompting');
            VTSCoder.setPropertyReversed({self.Hhub},   13, 'Hhub', '            Hub height');
            VTSCoder.setPropertyReversed({self.PiAvg},  13, 'PiAvg', '           Pitch angle');
            VTSCoder.setPropertyReversed({self.YawPos, self.YawOp, self.YawSlip, self.tbd3},  13, 'YawSys', '            YawPos YawOp YawSlip');
            VTSCoder.setPropertyReversed({self.PRINTOP, self.NPRINT, self.FILOP, self.NFIL},  13, 'Print', '            PRINTOP NPRINT FILOP NFIL');
            VTSCoder.setPropertyReversed({self.dt, self.simtime, self.tAvg, self.t0},  13, 'Time', '            dt simtime tAvg t0');
            VTSCoder.setPropertyReversed({self.BladeDOF1, self.BladeDOF2, self.BladeDOF3, self.BladeDOF4, self.BladeDOF5, self.BladeDOF6, self.BladeDamper, self.BladeTorsion},   13, 'BldDyn', '            Blade DOF 1-8 (blade mode 1-6, damper, torsion)');
            VTSCoder.setPropertyReversed({self.DOF13, self.DOF14, self.DOF15, self.ND, self.Rot},  13, 'DrtDyn', '            DOF 13-15,ND, Rot');
            VTSCoder.setPropertyReversed({self.DOF11, self.DOF12, self.DmprX, self.DmprY, self.DmprZ},  13, 'NacDyn', '            DOF 11,12 Dmpr xyz');
            VTSCoder.setPropertyReversed({self.DOFDownwind1, self.DOFDownwind2, self.DOFDownwind3, self.DOFDownwind4},  13, 'TwrDynDw', '            DOF Downwind 1,2,3,4');
            VTSCoder.setPropertyReversed({self.DOFLateral1, self.DOFLateral2, self.DOFLateral3, self.DOFLateral4},  13, 'TwrDynLa', '            DOF Lateral 1,2,3,4');
            VTSCoder.setPropertyReversed({self.DOF, self.Damper},  13, 'TwrDynDa', '            DOF Damper');
            VTSCoder.setPropertyReversed({self.DOFX, self.DOFY, self.DOFZ, self.DOFRotX, self.DOFRotY, self.DOFRotZ},  13, 'FndDyn', '            DOF 1-6 (X Y Z RotX RotY RotZ)');
            VTSCoder.setPropertyReversed({self.DynWake, self.DynWTCfak},  13, 'DynWake', '            DynWake DynWTCfak');
            
            VTSCoder.setLine('');
            VTSCoder.setLine('');
            VTSCoder.setLine('');
            VTSCoder.setLine('WIND SPEEDS');
            
            wndcomments = self.getWindSpeeedSectionComments();
            fields = self.WindSpeeds.keys;
            for i=1:length(fields)
                comment = '';
                if wndcomments.isKey(fields{i})
                    comment = ['       ' wndcomments(fields{i})];
                end
                VTSCoder.setPropertyReversed({num2str(self.WindSpeeds(fields{i}))},  13, fields{i}, comment);
            end
            
            VTSCoder.setLine('');
            VTSCoder.setLine('');
            % LOAD CASES here
            VTSCoder.setLine('LOAD CASES');
            VTSCoder.setRemaininglines(self.comments);
            
            status = VTSCoder.save();
        end
    end
    
    methods %(Access=protected)
        function myattributes = getAttributes(self)
            
            %check matlab version
            [a dateb]  = version;
            datebnum = datenum(dateb);
            
            myattributes = struct();
            
            mco = metaclass(self);
            if datebnum > 734174
                myproperties = {mco.PropertyList(strcmpi({mco.PropertyList.SetAccess},'public')).Name};
            else
                for i = 1 : length(mco.Properties)
                    idx = 0;
                    if strcmpi(mco.Properties{i}.SetAccess,'public')
                        idx = idx + 1;
                        myproperties{i} = mco.Properties{i}.Name;
                    end
                end
            end
            myproperties = myproperties(~strcmpi(myproperties,'Files'));
            myproperties = myproperties(~strcmpi(myproperties,'WindSpeeds'));
            
            %mytables = {'LoadCases'};
            mytables = {};
            myfiles = {'WND','SEA','BLD','HBX','HUB','DRT','BRK','GEN','CNV','NAC','YAW','TWR','FND','PIT','CTR','SEN','VRB','_PL','HWC'};
            
            myattributes.properties = myproperties;
            myattributes.tables = mytables;
            myattributes.files = myfiles;
        end
        
        function self = addloadcases(self,lctextfile)
            
            loadcases = LAC.codec.CodecTXT(lctextfile);
            txt = loadcases.getRemaininglines;
            self.comments = sprintf('%s\n%s' ,self.comments, txt);
        end
        function self = dlc11loadcases(self,wsp,seedstr)
            steps = diff(wsp);
            wspLow = wsp - [steps(1) steps]./2;
            wspHi  = wsp + [steps steps(end)]./2;
            self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 1.1: NORMAL PRODUCTION');
            for iWS = 1:length(wsp)
                % Write to txt-file with following format replacing:
                % WSP, QUANT, SEED WSP, FRQ and ITURB with the computed values
                % line1 = '11WSPqQUANT Prod. Wdir=0'
                % line2 = 'ntm SEED Freq FRQ LF 1.35'
                % line3 = '0.1 2 WSP 0 turb ITURB'
                self.comments = sprintf('%s\n11%02.0fa Prod. %.0f-%.0f m/s Wdir=-6 \n',self.comments,wsp(iWS),wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%sntm %s Weib %.0f %.0f 0.5 LF 1.35\n',self.comments,seedstr,wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%s0.1 2 %.1f -6\n',self.comments,wsp(iWS));
            end
            for iWS = 1:length(wsp)
                % Write to txt-file with following format replacing:
                % WSP, QUANT, SEED WSP, FRQ and ITURB with the computed values
                % line1 = '11WSPqQUANT Prod. Wdir=0'
                % line2 = 'ntm SEED Freq FRQ LF 1.35'
                % line3 = '0.1 2 WSP 0 turb ITURB'
                self.comments = sprintf('%s\n11%02.0fb Prod. %.0f-%.0f m/s Wdir=6 \n',self.comments,wsp(iWS),wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%sntm %s Weib %.0f %.0f 0.5 LF 1.35\n',self.comments,seedstr,wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%s0.1 2 %.1f 6\n',self.comments,wsp(iWS));
            end
            
        end
        function self = fle_loadcases(self,wsp,seedstr)
            steps = diff(wsp);
            wspLow = wsp - [steps(1) steps]./2;
            wspHi  = wsp + [steps steps(end)]./2;
            self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 1.1: NORMAL PRODUCTION');
            for iWS = 1:length(wsp)
                % Write to txt-file with following format replacing:
                % WSP, QUANT, SEED WSP, FRQ and ITURB with the computed values
                % line1 = '11WSPqQUANT Prod. Wdir=0'
                % line2 = 'ntm SEED Freq FRQ LF 1.35'
                % line3 = '0.1 2 WSP 0 turb ITURB'
                self.comments = sprintf('%s\n11%02.0f Prod. %.0f-%.0f m/s Wdir=0 \n',self.comments,wsp(iWS),wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%sntm %s Weib %.0f %.0f 0.5 LF 1.35\n',self.comments,seedstr,wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%s0.1 2 %.1f 0\n',self.comments,wsp(iWS));
            end
        end
        function self = dlc94loadcases(self,wsp,seedstr)
            self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 9.4: Power Curve');
            for iWS = 1:length(wsp)
                % Write to txt-file with following format replacing:
                % WSP, QUANT, SEED WSP, FRQ and ITURB with the computed values
                % line1 = '11WSPqQUANT Prod. Wdir=0'
                % line2 = 'ntm SEED Freq FRQ LF 1.35'
                % line3 = '0.1 2 WSP 0 turb ITURB'
                self.comments = sprintf('%s\n94_%2.1f_ \n',self.comments,wsp(iWS));
                self.comments = sprintf('%sntm %s freq 0 LF 0\n',self.comments,seedstr);
                if isempty(self.PPO)
                    self.comments = sprintf('%s0.1 2 %2.1f 0 rho 1.225 turb 0.1 vexp 0.15 slope 0\n',self.comments,wsp(iWS));
                else
                    PPO_string = sprintf('GenPowerScaleTable %s',self.PPO);
                    self.comments = sprintf('%s0.1 2 %2.1f 0 rho 1.225 turb 0.1 vexp 0.15 slope 0 %s\n',self.comments,wsp(iWS),PPO_string);
                end
                
            end
            
            
        end
        function self = seedreduction(self,nseeds)
            self.comments = '';
            for iLC = 1:length(self.LoadCases)
                if strncmp(self.LoadCases{iLC}{2},'ntm',3)||strncmp(self.LoadCases{iLC}{2},'etm',3)
                    stridx = strfind(self.LoadCases{iLC}{2},' ');
                    self.LoadCases{iLC}{2} = [self.LoadCases{iLC}{2}(1:stridx(1)) '1' self.LoadCases{iLC}{2}(stridx(2):stridx(3)) num2str(nseeds) self.LoadCases{iLC}{2}(stridx(4):end)];
                end
                self.comments = sprintf('%s\n%s' ,self.comments, strjoin_LMT(self.LoadCases{iLC},'\n'));
            end
        end
        function self = fle22prodloadcases(self,wsp,seedstr,dddamp)
            steps = diff(wsp);
            wspLow = wsp - [steps(1) steps]./2;
            wspHi  = wsp + [steps steps(end)]./2;
            self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 1.1: NORMAL PRODUCTION - FLE22 with dd damping applied and no vertical wind shear');
            for iWS = 1:length(wsp)
                % Write to txt-file with following format replacing:
                % WSP, QUANT, SEED WSP, FRQ and ITURB with the computed values
                % line1 = '11WSPqQUANT Prod. Wdir=0'
                % line2 = 'ntm SEED Freq FRQ LF 1.35'
                % line3 = '0.1 2 WSP 0 turb ITURB'
                self.comments = sprintf('%s\n11%02.0fa Prod. %.0f-%.0f m/s Wdir=0 \n',self.comments,wsp(iWS),wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%sntm %s Weib %.0f %.0f 0.5 LF 1.35\n',self.comments,seedstr,wspLow(iWS),wspHi(iWS));
                self.comments = sprintf('%s0.1 2 %.1f 0 vexp 0 dd 49 %.1f \n',self.comments,wsp(iWS),dddamp);
            end
            
        end
        function self = fle22idleloadcases(self,idlePower,seedstr)
            
            if idlePower
                self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 6.1: IDLING AT VE50 - Idle Power available');
                azim0=0:30:90;
                wdir=2:2:8;
                
                self.comments = sprintf('%s\n\n %s\n',self.comments,'beginfamily -');
                for iWD = length(wdir):-1:1
                    for iAz = 1:length(azim0)
                        % Write to txt-file with following replacing:
                        self.comments = sprintf('%s\n61E50a%03.0f%03.0f Idling at V50 + turb \n',self.comments,wdir(iWD),azim0(iAz));
                        self.comments = sprintf('%sntm %s Freq 0 LF 1.35\n',self.comments,seedstr);
                        self.comments = sprintf('%s0.2 0 V50 -%.1f azim0 %.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,wdir(iWD),azim0(iAz));
                    end
                end
                self.comments = sprintf('%s\n\n %s\n',self.comments,'endfamily');
                
                self.comments = sprintf('%s\n\n %s\n',self.comments,'beginfamily -');
                for iAz = 1:length(azim0)
                    % Write to txt-file with following replacing:
                    self.comments = sprintf('%s\n61E50a%03.0f%03.0f Idling at V50 + turb \n',self.comments,0,azim0(iAz));
                    self.comments = sprintf('%sntm %s Freq 0 LF 1.35\n',self.comments,seedstr);
                    self.comments = sprintf('%s0.2 0 V50 %.1f azim0 %.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,0,azim0(iAz));
                end
                self.comments = sprintf('%s\n\n %s\n',self.comments,'endfamily');
                
                self.comments = sprintf('%s\n\n %s\n',self.comments,'beginfamily -');
                for iWD = 1:length(wdir)
                    for iAz = 1:length(azim0)
                        % Write to txt-file with following replacing:
                        self.comments = sprintf('%s\n61E50b%03.0f%03.0f Idling at V50 + turb \n',self.comments,wdir(iWD),azim0(iAz));
                        self.comments = sprintf('%sntm %s Freq 0 LF 1.35\n',self.comments,seedstr);
                        self.comments = sprintf('%s0.2 0 V50 %.1f azim0 %.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,wdir(iWD),azim0(iAz));
                    end
                end
                self.comments = sprintf('%s\n\n %s\n',self.comments,'endfamily');
                
                
            else
                
                self.comments = sprintf('%s\n\n%s\n',self.comments,'***** IEC 6.2: IDLING AT VE50 - LOSS OF ELECTRICAL NETWORK CONNECTION');
                wdir=10:10:170;
                
                for iWD = length(wdir):-1:1
                    % Write to txt-file with following replacing:
                    self.comments = sprintf('%s\n62E50a%03.0f Idling at V50 + turb \n',self.comments,wdir(iWD));
                    self.comments = sprintf('%sntm %s Freq 0 LF 1.1\n',self.comments,seedstr);
                    self.comments = sprintf('%s0.2 0 V50 -%.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,wdir(iWD));
                end
                for iWD = 1:length(wdir)
                    % Write to txt-file with following replacing:
                    self.comments = sprintf('%s\n62E50b%03.0f Idling at V50 + turb \n',self.comments,wdir(iWD));
                    self.comments = sprintf('%sntm %s Freq 0 LF 1.1\n',self.comments,seedstr);
                    self.comments = sprintf('%s0.2 0 V50 %.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,wdir(iWD));
                end
                % Write to txt-file with following replacing:
                self.comments = sprintf('%s\n62E50b%03.0f Idling at V50 + turb \n',self.comments,180);
                self.comments = sprintf('%sntm %s Freq 0 LF 1.1\n',self.comments,seedstr);
                self.comments = sprintf('%s0.2 0 V50 %.1f pitch0 9999 95 95 95  profdat STANDSTILL vexp 0.11 turb 0.11 rho 1.225 time 0.01 600 10 300 \n',self.comments,180);
                
                
            end
            
        end
        
    end
    
    
    
    properties
        Header
        TurbulenceFiles
        Rotor
        OffOnshore
        ConverterSystem
        PartsFolder
        NameErrorFile
        Flex5
        Flex5Ver
        
        % COMPONENTS
        Files = containers.Map({'WND','SEA','BLD','HBX','HUB','DRT','BRK','GEN','CNV','NAC','YAW','TWR','FND','PIT','CTR','_PL','SEN','VRB','ERR','HWC'},{'','','','','','','','','','','','','','','','','','','',''}) % preffered use
        WND, SEA, BLD, HBX, HUB, DRT, BRK, GEN, CNV, NAC, YAW, TWR, FND, PIT, CTR, PL, SEN, VRB, ERR, HWC  % for backward compability only
        
        % GENERAL INPUT
        tgust
        Prompt
        Hhub
        PiAvg
        YawPos
        YawOp
        YawSlip
        tbd3
        PRINTOP,NPRINT,FILOP,NFIL
        dt, simtime,tAvg, t0
        BladeDOF1, BladeDOF2, BladeDOF3, BladeDOF4, BladeDOF5, BladeDOF6
        BladeDamper, BladeTorsion
        DOF13, DOF14, DOF15, ND, Rot
        DOF11, DOF12, DmprX, DmprY, DmprZ
        DOFDownwind1, DOFDownwind2, DOFDownwind3, DOFDownwind4
        DOFLateral1, DOFLateral2, DOFLateral3, DOFLateral4
        DOF, Damper
        DOFX, DOFY, DOFZ, DOFRotX, DOFRotY, DOFRotZ
        DynWake, DynWTCfak
        PPO
        
        
        % WIND SPEEDS
        WindSpeeds
        
        % LOAD CASES
        LoadCases = {}
        LoadCaseNames = {}
        
        comments
    end
    
    methods
        function output = arePartsValid()
            % Examine if all part files exist
            output = true;
            for k = self.parts
                if ~exist(char(k),'file')
                    output = false;
                end
            end
        end
        
        function output = findPart(searchstring)
            cnt = 0;
            for k = self.Type
                cnt = cnt+1;
                if strfind(char(k), searchstring)
                    output = char(self.parts(cnt));
                    break
                end
            end
        end
        
        function output = findType(searchstring)
            cnt = 0;
            for k = self.parts
                cnt = cnt+1;
                if strfind(char(k), searchstring)
                    output = char(self.Type(cnt));
                    break
                end
            end
        end
    end
    
    methods %(Access=private)
        % TBD: Move functionality to FileManipulator class
        %s.decodeParts(s.components, s.PartsFolder, refmodelfolder)
        %         function [output, Type] = decodeParts(~, data, partsfolder, refmodelfolder)
        %             names = data.keys;
        %             tempparts = cell(length(names),1);
        %             for i=1:length(names)
        %                 tmp = data(names{i});
        %
        %                 if isempty(regexp(tmp, '(:|\\\\)', 'once'))
        %                     name = strrep(names{i}, 'underscore', '_');
        %                     tempparts{i} = strcat(partsfolder, name, '\', tmp);
        %                 else
        %                     tempparts{i} = tmp;
        %                 end
        %                 if ~isempty(regexp(tempparts{i}, '\.\.','once'))
        %                     % Convert relative path to absolute path
        %                     [a,b,c] = fileparts(tempparts{i});
        %                     tempparts{i} = fullfile(a,[b c]);
        %
        %                     if ~isempty(regexp(tempparts{i}, '\.\.','once'))
        %                         % Parts folder might be relative to refmodel file
        %                         [a,b,c] = fileparts([refmodelfolder '\' tempparts{i}]);
        %                         tempparts{i} = fullfile(a,[b c]);
        %                     end
        %                 end
        %
        %                 if ~isempty(strfind(tempparts{i},'://'))
        %                     tempparts{i} = strrep(tempparts{i}, '\', '/');
        %                 end
        % %                 tempparts{i,2} = names(i);
        %                   Type{i} = strrep(names{i}, 'underscore', '_');
        %             end
        %             output = tempparts';
        %         end
        
        %         function output = decodeFlex5(s)
        %             output = strcat(s.flex5folder, s.Flex5Filename, '.exe');
        %         end
        
        %         function output = decodeComponentsSection(~, FID, line_obj)
        %             output = containers.Map;
        %             for i = 1:50
        %                 [name, value] = line_obj.decode(FID);
        %
        %                 if ~strcmpi(name, 'GENERAL')
        %                     if length(name) == 3
        %                         %name = strrep(name, '_', 'underscore');
        %                         %name = strrep(name, '.', 'dot');
        %                         %output.(name) = value;
        %                         output(name) = value;
        %                     else
        %                         error('codec.ReferenceModel:decodeComponentsSection', 'Invalid formated Compoenents section in refmodel');
        %                     end
        %                 else
        %                     fseek(FID, -15, 'cof'); % Rewind to start of "GENERAL INPUT" line
        %                     break;
        %                 end
        %             end
        %         end
        
        %         function encodeComponentsSection(~, FID, line_obj, mystruct)
        %             names = mystruct.keys;
        %             for i = 1:length(names)
        %                 line_obj.encode(FID, sprintf('%-3s', names{i}), mystruct(names{i}));
        %             end
        %         end
        %
        %         function output = decodeWindSpeeedSection(~, FID, line_obj)
        %             for i = 1:50
        %                 [name, value] = line_obj.decode(FID);
        %                 if ~strcmpi(name, 'LOAD')
        %                     name = strrep(name, '-', 'minus');
        %                     name = strrep(name, '+', 'plus');
        %                     output.(name) = value;
        %                 else
        %                     fseek(FID, -12, 'cof'); % Rewind to start of "LOAD CASES" line
        %                     break;
        %                 end
        %             end
        %         end
        
        function output = getWindSpeeedSectionComments(self)
            output = containers.Map;
            output('vminp')    = 'minimum wind speed gives 20% power';
            output('vrat')     = 'rated wind speed';
            output('Vrminus2') = 'rated wind speed - 2m/s';
            output('Vrplus2')  = 'rated wind speed + 2m/s';
            output('vma')      = 'maintenance wind speed';
            output('vma1')     = 'maintenance wind speed when working in nacelle';
            output('vinmax')   = 'max cut-in wind speed';
            output('vout')     = 'cut out wind speed';
            output('V50')      = 'Vref, IEC-3, 50 year 10 minute mean, turbulent';
            output('Ve50')     = '1.4 x Vref, 50 year, 3 sec. gust';
            output('V1')       = 'IEC-3, 1 year 10 minute mean, turbulent, 0.8 x Vref';
            output('Ve1')      = '1.4 x V1, 1 year, 3 sec. gust';
        end
        
        %         function text = trimEmptyLines(~, text)
        %             text = {deblank(text{:})};
        %             while ~isempty(text{1}) && isempty(text{1}{end})
        %                 text{1}(end) = [];
        %             end
        %         end
    end
end

