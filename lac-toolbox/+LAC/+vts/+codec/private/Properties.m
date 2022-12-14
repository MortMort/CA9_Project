classdef Properties < handle
    methods
        function self = Properties(input) % input comes from ReferenceModel.decode()
                                          %       or self.get() from other refmodel
            switch(class(input))
                case 'containers.Map'
                    self.mdlproperties = input;
                case 'codec.ReferenceModel'
                    self.decode(input);
            end
        end
        
        function output = get(self, varargin)
            if nargin == 1
                output = self.mdlproperties;
            else
                output = self.mdlproperties(varargin{1});
            end
        end
        
        function set(self, name, value)
            self.mdlproperties(name) = value;
        end
        
        function status = verify(self)
            % Are properties valid? CTR release, MkType, WindClass,     
            tmp.MkType          = codec.MkType().verify(self.mdlproperties('MkType'));
            tmp.WindClass       = codec.WindClass().verify(self.mdlproperties('WindClass'));
            tmp.CTRRelease      = codec.CTRRelease().verify(self.mdlproperties('ControlRelease'),self.mdlproperties('ControlReleaseDate'));
            tmp.TowerCode       = true;  %self.mdlproperties('TowerCode')
            %tmp.Flex5Filename   = ~strcmpi(self.mdlproperties('Flex5Filename'),'ILLEGAL');
            tmp.Rotor           = ~strcmpi(self.mdlproperties('Rotor'), 'UNKNOWN');
            tmp.ConverterSystem = ~strcmpi(self.mdlproperties('ConverterSystem'), 'UNKNOWN');
            tmp.HubHeight       = ~strcmpi(self.mdlproperties('HubHeight'), 'UNKNOWN');
            tmp.GridFreq        = ~strcmpi(self.mdlproperties('GridFreq'), 'UNKNOWN');
            tmp.GenSpeed        = ~strcmpi(self.mdlproperties('GenSpeed'), 'UNKNOWN');
            tmp.NominalPower    = ~strcmpi(self.mdlproperties('NominalPower'), 'UNKNOWN');
            tmp.GearRatio       = ~strcmpi(self.mdlproperties('GearRatio'), 'UNKNOWN');
            status = all(cell2mat(struct2cell(tmp)));
            if ~status
                idx = find(cell2mat(struct2cell(tmp))==0);
                names = fields(tmp);
                names = names(idx);
                for i=1:length(names)
                    % TBD: We should probably return the problems instead
                    % of dispaying them!!
                    try
                        disp(['!!Invalid property ' names{i} ' = ' self.mdlproperties(names{i})])
                    catch
                        disp(['!!Invalid property ' names{i} ' = ' self.mdlproperties('ControlRelease') ' + ' self.mdlproperties('ControlReleaseDate')]);
                    end
                end
            end
        end
        
        function status = compare(self, other)
            status = isequal(self.mdlproperties,other);
        end
        
        function output = getRefModelFilename(self)
            %Example: V112_3075_GS_50_1450_IEC3A_113.3_119_EU_Mk0
            myTowerCode = '';
            if self.mdlproperties.isKey('TowerCode')
                if ~isempty(self.mdlproperties('TowerCode'))
                    myTowerCode = ['_' self.mdlproperties('TowerCode')];
                end
            end
            
            output = sprintf('V%s_%s_%s_%s_%s_%s_%s_%s%s_%s.txt', ...
                             self.mdlproperties('Rotor'), ...
                             self.mdlproperties('NominalPower'), ...
                             self.mdlproperties('ConverterSystem'), ...
                             self.mdlproperties('GridFreq'), ...
                             self.mdlproperties('GenSpeed'), ...
                             self.mdlproperties('WindClass'), ...
                             self.mdlproperties('GearRatio'), ...
                             self.mdlproperties('HubHeight'), ...
                             myTowerCode, ...
                             self.mdlproperties('MkType'));
        end
    end
    
    methods(Access=private)
        function decode(self, s)
            % map properties into right names
            self.mdlproperties = containers.Map;
            self.mdlproperties('Rotor') = s.Rotor;
            self.mdlproperties('ConverterSystem') = s.ConverterSystem;
            self.mdlproperties('HubHeight') = num2str(str2double(s.Hhub));
            
            self.mdlproperties('GridFreq') = 'UNKNOWN';
            self.mdlproperties('GenSpeed') = 'UNKNOWN';
            tmp = s.GEN;
            if isfield(tmp, 'Fnet')
                self.mdlproperties('GridFreq') = num2str(str2double(tmp.Fnet));
                self.mdlproperties('GenSpeed') = num2str(str2double(tmp.GenRpmRtd));
            end
            
            self.mdlproperties('NominalPower') = 'UNKNOWN';
            self.mdlproperties('GearRatio') = 'UNKNOWN';
            tmp = s.CTR;
            %if isfield(s, 'CTR') && isfield(s.CTR, 'ProductionController')
            if isfield(tmp, 'ProductionController')
                self.mdlproperties('NominalPower') = tmp.ProductionController.getParameter('Px_PoRS_NomPowDelta');
                if ~isempty(tmp.ProductionController.getParameter('Px_LDO_PowSetpoint'))
                    self.mdlproperties('NominalPower') = tmp.ProductionController.getParameter('Px_LDO_PowSetpoint');
                end
                self.mdlproperties('GearRatio') = tmp.ProductionController.getParameter('Px_LSO_GearRatio');
            end
            
            
            self.mdlproperties('ControlRelease') = 'UNKNOWN';
            self.mdlproperties('ControlReleaseDate') = 'UNKNOWN';
            if isfield(tmp,'AuxDLL')
                obj = codec.Part_CTR();
                prodctrldll = obj.getIncludedFile(tmp.AuxDLL, 'ProductionControllerDLL');
                pitchctrldll = obj.getIncludedFile(tmp.AuxDLL, 'PitchControllerDLL');
                if isfield(prodctrldll,'FileName') && isfield(pitchctrldll,'FileName')
                    res1 = regexp(prodctrldll.FileName,'[0-9]{6,8}','match');
                    res2 = regexp(prodctrldll.FileName,'[0-9]{2,4}\.[0-9]{2}','match');
                    res3 = regexp(pitchctrldll.FileName,'[0-9]{6,8}','match');
                    res4 = regexp(pitchctrldll.FileName,'[0-9]{2,4}\.[0-9]{2}','match');
                    if length(res1)>=1 && length(res2)>=1 && length(res3)>=1 && length(res4)>=1
                        if strcmpi(char(res1{end}), datestr(datenum(char(res1{end}),'yyyymmdd'),'yyyymmdd'))
                            self.mdlproperties('ControlReleaseDate') = char(res1{end});
                        end
                        if ~isempty(strfind(datestr(datenum(char(res2{end}),'yyyy.mm'),'yyyy.mm'), char(res2{end})))
                            self.mdlproperties('ControlRelease') = datestr(datenum(char(res2{end}),'yyyy.mm'),'yyyy.mm');
                        end
                    end
                end
            end
            
%             self.mdlproperties('Flex5Filename') = 'ILLEGAL';
%             FlexFolder = '\\dkrkbfile01\flex\SOURCE\';
%             %FlexFolder = 'W:\SOURCE\';
%             FlexFilename = [s.Flex5Filename '.exe'];
%             if exist([FlexFolder FlexFilename], 'file') == 2
%                 %Illegal: Vts002v05.exe
%                 %Legal  : Vts002v05xxx.exe
%                 %Legal  : Vts002v05_xxx.exe
%                 res = regexpi(FlexFilename,'vts[0-9]{3}_?v[0-9]{2}[0-9a-zA-Z_]+.exe','match');
%                 if ~isempty(res)
%                     self.mdlproperties('Flex5Filename') = [FlexFolder FlexFilename];
%                 end
%             end
            
            self.mdlproperties('MkType') = 'Unknown';
            if self.mdlproperties.isKey('GearRatio')
                self.mdlproperties('MkType') = codec.MkType.get(self.mdlproperties);
            end
            
            self.mdlproperties('WindClass') = 'Unknown';
            tmp = struct();
            tmp.Hhub = s.Hhub;
            tmp.WND = s.WND;
            tmp.WindSpeeds = s.WindSpeeds;
            if ~isempty(fields(tmp))
                obj = codec.WindClass();
                self.mdlproperties('WindClass') = obj.get(tmp);
            end
            
            %self.mdlproperties('TowerCode') = '';
            
            % Examples of filenames:
            % V100_1800_VCS_50_1680_IEC3B_113.1_95_IN_Mk7.5.txt
            % V110_2000_VCS_50_1680_IEC3A_112.8_95_EU_Mk10.txt
            % V110_2000_VCS_50_1680_IEC3A_112.8_125_EU_Mk10_r42.txt
            tmpfilename = sprintf('V%s_%s_%s_%s_%s_%s', ...
                                  self.mdlproperties('Rotor'), ...
                                  self.mdlproperties('NominalPower'), ...
                                  self.mdlproperties('ConverterSystem'), ...
                                  self.mdlproperties('GridFreq'), ...
                                  self.mdlproperties('GenSpeed'));
            
            [~, myfilename, myext] = fileparts(s.FileName);
            filenameok  = ~isempty(strfind(myfilename, tmpfilename));
            extensionok = strfind('.txt', myext);
            if filenameok && extensionok
                tmpfilename = regexprep(s.FileName, '_r[0-9]+[.]', '.');
                tmp = strsplit_LMT(tmpfilename, '_');
                if ~strcmpi(self.mdlproperties('HubHeight'),tmp{end-1})
                    self.mdlproperties('TowerCode') = tmp{end-1};
                end
                
                % Use MkType from filename to correct MkType, e.g.
                % Mk7.5/Mk8 + V100_1125_VCS_50_1310_IEC3B_113.1_95_IN_Mk7.5.txt
                % --> Mk7.5
                if isempty(strfind(s.FileName, self.mdlproperties('MkType')))
                    [~,mktypeFromFileName,~] = fileparts(tmp{end});
                    if ~isempty(strfind(self.mdlproperties('MkType'), mktypeFromFileName))
                        self.mdlproperties('MkType') = mktypeFromFileName;
                    end
                end
            end
        end
        
    end
    
    properties (Access = private)
        mdlproperties
    end
end
   