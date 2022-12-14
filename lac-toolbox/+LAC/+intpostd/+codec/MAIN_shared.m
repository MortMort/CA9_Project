%MAIN - MAIN object reading intpostD mainloads file
%
% Syntax:  mainObj = LAC.intpostd.codec.MAIN(CoderObj)
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    mainObj   - Mainloads object containing all properties of the blade
%
% Methods
%
% Example:
%    mainObj = LAC.intpostd.convert(mainloadsfilename,'MAIN')
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert, LAC.intpostd.convert

classdef MAIN_shared < handle
    
    properties %(SetObservable)
        filename char
        Date
        Type = 'MainLoad'
        intpostdVersion char
        sectionName
        decodeSections
        references
        notes cell
        windConditions = struct('Standard','','Class','','Iref','','I90','','MeanWindSpeed','','V50','','V1','','shapeFactor','')
        operationalSpeeds = struct('Vin','','Vout','','Vinmax','','Vrat','','Vma','');
        turbineData = struct('TurbineName','','ConverterType','','RotorRadius','','HubHeight','','NumberOfBlades','','BladeType','','HubConing','','TiltAngle','','BladeRootConing','','BladeRootSweepAngle','','BladeMass','','HubMass','','RotorMass','','NacelleMass','','HubCentre','','NacelleCoG','','NominalPower','','RotorSpeed','','GeneratorSpeed','','ConverterOverspeed','','VOGLimit','','GearRatio','','ErrorLevelTYCdeactivated','','ErrorLevelTYCactivated','','DesignLifetime','','TowerFrequency','')
        comments char
    end
    
    methods (Static)
        function s = decode(Coder,classType)
            s = LAC.intpostd.codec.(classType);
            s.Date = datestr(now());
            if ~isempty(Coder.search('Automated Generation of Load Spectrum'))
                s.Type = 'MainLoad';
                s.intpostdVersion = cell2mat(Coder.search('IntPostD'));
            elseif ~isempty(Coder.search('Automated generation of combined/compared load spectrum'))
                s.Type = 'MaxMainLoad';
            else
                error('Could not recognize file as a MainLoads.txt or MaxMainLoads.txt file')
            end

            s.filename = Coder.getSource;
            %% References
            Coder.search('#1  REFERENCES');
            Coder.get; Coder.get; Coder.get;
            switch s.Type
                case 'MaxMainLoad'
                    s.references.vtsPaths = [];
                    s.references.intpostdPaths = [];
                    vtsPath = Coder.get('whole');
                    intpostdPath = Coder.get('whole');
                    while ~isempty(strtrim(vtsPath))
                        s.references.vtsPaths{end+1,1} = cell2mat(strtrim(regexp(vtsPath,'(?<=\[[0-9]\]\s+VTS Calculation Path:).*','match')));
                        s.references.intpostdPaths{end+1,1} = cell2mat(strtrim(regexp(intpostdPath,'(?<=Intpostd Path:).*','match')));
                        try
                            vtsPath = Coder.get('whole');
                            intpostdPath = Coder.get('whole');
                        catch % if file does not end with an empty line catch the error and set to '';
                            vtsPath = '';
                            intpostdPath = '';
                        end
                    end
                case 'MainLoad'
                    linestr = Coder.get('whole');
                    s.references.vtsPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Calculation Path:).*','match')));
                    linestr = Coder.get('whole');
                    s.references.intPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Sensor & Intfile Path:).*','match')));
                    linestr = Coder.get('whole');
                    s.references.frqPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Frequency File:).*','match')));
                    linestr = Coder.get('whole');
                    s.references.masPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Master File:).*','match')));
                    linestr = Coder.get('whole');
                    s.references.pitchVTZPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Pitch CTR VTZ File:).*','match')));
                    linestr = Coder.get('whole');
                    s.references.prodVTZPath = cell2mat(strtrim(regexp(linestr,'(?<=VTS Prod CTR VTZ File:).*','match')));
            end
            %% Notes
            if ~isempty(Coder.search('#2  NOTES'))
                Coder.get; Coder.get; Coder.get;
                linestr = Coder.get('whole');
                while ~isempty(strtrim(linestr))
                    s.notes{end+1,1} = cell2mat(strtrim(regexp(linestr,'(?<=#2\.[0-9]+).*','match')));
                    linestr = Coder.get('whole');
                    if ~isempty(linestr)
                       sameNote = ~strcmp(linestr(1),'#');
                    else 
                        sameNote=false;
                    end
                    while sameNote
                        s.notes{end,1} = sprintf('%s %s',s.notes{end},strtrim(linestr));
                        linestr = Coder.get('whole');
                        sameNote = (~isempty(strtrim(linestr)) && ~strcmp(linestr(1),'#'));
                    end
                end
            end
            %% Climate sections
            fieldNames = fields(s.windConditions);
            Coder.search('#3.1');
            Coder.get;
            linestr = Coder.get('whole');
            for k=1:length(fieldNames)
                s.windConditions.(fieldNames{k}) = cell2mat(strtrim(regexp(linestr,'(?<=\s{2,}).*','match')));
                try
                    linestr = Coder.get('whole');
                catch % if file does not end with an empty line catch the error and set to '';
                    linestr = '';
                end
            end
            
            fieldNames = fields(s.operationalSpeeds);
            Coder.search('#3.2');
            Coder.get;
            linestr = Coder.get('whole');
            for k=1:length(fieldNames)
                s.operationalSpeeds.(fieldNames{k}) = cell2mat(strtrim(regexp(linestr,'(?<=\s{2,}).*','match')));
                try
                    linestr = Coder.get('whole');
                catch % if file does not end with an empty line catch the error and set to '';
                    linestr = '';
                end
            end
            
            %% Turbine data
            fieldNames = fields(s.turbineData);
            Coder.search('#4.1');
            Coder.get;
            linestr = Coder.get('whole');
            for k=1:length(fieldNames)
                s.turbineData.(fieldNames{k}) = cell2mat(strtrim(regexp(linestr,'(?<=\s{2,}).*','match')));
                try
                    linestr = Coder.get('whole');
                catch % if file does not end with an empty line catch the error and set to '';
                    linestr = '';
                end
            end
            
            %% Load sections
            s.decodeSections = {'#5.1', '#5.2', '#5.3', '#5.4'...
                '#6.1', '#6.2', '#6.3', '#6.4', '#6.5', '#6.6', '#6.7'...
                '#7.1', '#7.2', '#7.3', '#7.4'...
                '#8.1', '#8.2'...
                '#9.1', '#9.2'...
                '#10.1'};
            s.sectionName = s.getSectionNames();
            
            for decodeID=1:length(s.decodeSections)
                Coder.search(s.decodeSections{decodeID});
                if ~isempty(Coder.search(s.decodeSections{decodeID}))
                    Coder.get; Coder.get; linestr = Coder.get('whole');
                    senData = [];
                    if decodeID == 20
                        maxLines = 3;                        
                    else
                        maxLines = 100;
                    end
                    lineNo = 1;
                    while ~isempty(strtrim(linestr)) && lineNo <= maxLines
                        C = textscan(linestr,'%s');
                        senData = s.addToSenData(senData,C,decodeID);
                        try
                            linestr = Coder.get('whole');
                        catch % if file does not end with an empty line catch the error and set to '';
                            linestr = '';
                        end
                        lineNo = lineNo+1;
                    end
                    
                    s.(s.sectionName{decodeID}) = senData;
                end
            end
            Coder.skip(-1); % Go back one line...
            s.comments = Coder.getRemaininglines();
        end
    end
    
    methods
        function help(self)
            help LAC.intpostd.codec.MAIN
        end
        
        function encode(self,filename)
            f = fopen(filename,'w+');
            % intro
            
            switch self.Type
                case 'MainLoad'
                    fprintf(f,'\n%s\n',self.intpostdVersion);
                    fprintf(f,'%s\n\n','ML Module');
                    fprintf(f,'  VESTAS WIND SYSTEMS A/S\n');
                    fprintf(f,'  - Automated Generation of Load Spectrum\n\n\n');
                case 'MaxMainLoad'
                    fprintf(f,'\nCombineLoads4\n');
                    fprintf(f,'%s\n\n',datestr(now));
                    fprintf(f,'  VESTAS WIND SYSTEMS A/S\n');
                    fprintf(f,'  - Automated generation of combined/compared load spectrum\n\n\n');
            end
            % References
            fprintf(f,'-------------------------------------------------------------------------\n');
            fprintf(f,'#1  REFERENCES\n');
            fprintf(f,'-------------------------------------------------------------------------\n\n');
            switch self.Type
                case 'MainLoad'
                    fprintf(f,'VTS Calculation Path:      %s\n',self.references.vtsPath);
                    fprintf(f,'VTS Sensor & Intfile Path: %s\n',self.references.intPath);
                    fprintf(f,'VTS Frequency File:        %s\n',self.references.frqPath);
                    fprintf(f,'VTS Master File:           %s\n',self.references.masPath);
                    fprintf(f,'VTS Pitch CTR VTZ File:    %s\n',self.references.pitchVTZPath);
                    fprintf(f,'VTS Prod CTR VTZ File:     %s\n',self.references.prodVTZPath);
                case 'MaxMainLoad'
                    for i = 1:length(self.references.vtsPaths)
                        fprintf(f,'[%0.0f] VTS Calculation Path:  %s\n',i,self.references.vtsPaths{i});
                        fprintf(f,'    Intpostd Path:         %s\n',self.references.intpostdPaths{i});
                    end
            end
            
            fprintf(f,'\n\n');
            % Notes
            if ~isempty(self.notes)
                fprintf(f,'-------------------------------------------------------------------------\n');
                fprintf(f,'#2  NOTES \n');
                fprintf(f,'-------------------------------------------------------------------------\n\n');
                for i = 1:length(self.notes)
                    fprintf(f,'#2.%02d %s\n',i,self.notes{i});
                end
                fprintf(f,'\n\n');
            end
            % Climate conditions
            fprintf(f,'-------------------------------------------------------------------------\n');
            fprintf(f,'#3  CLIMATE CONDITIONS\n');
            fprintf(f,'-------------------------------------------------------------------------\n\n');
            fprintf(f,'#3.1 IEC Wind Conditions\n');
            fprintf(f,'Standard                                             %s\n',self.windConditions.Standard);
            fprintf(f,'Class                                                            %s\n',self.windConditions.Class);
            fprintf(f,'Turbulence intensity at 15m/s - Iref,                           %s\n',self.windConditions.Iref);
            fprintf(f,'Turbulence intensity at 15m/s - I90 (90%% quantile),             %s\n',self.windConditions.I90);
            fprintf(f,'Mean wind speed at hub height                                 %s\n',self.windConditions.MeanWindSpeed);
            fprintf(f,'50 Year mean wind speed (10min avg.), V50                    %s\n',self.windConditions.V50);
            fprintf(f,'1 Year mean wind speed (10min avg.), V1                      %s\n',self.windConditions.V1);
            fprintf(f,'Weibull shape factor k                                            %s\n\n\n',self.windConditions.shapeFactor);
            
            fprintf(f,'#3.2 Operational Wind Speeds\n');
            fprintf(f,'Cut in wind speed, Vin                                        %s\n',self.operationalSpeeds.Vin);
            fprintf(f,'Cut out wind speed, Vout                                     %s\n',self.operationalSpeeds.Vout);
            fprintf(f,'Maximum start wind speed, Vinmax                             %s\n',self.operationalSpeeds.Vinmax);
            fprintf(f,'Rated wind speed, Vrat                                       %s\n',self.operationalSpeeds.Vrat);
            fprintf(f,'Max. maintenance wind speed, Vma                             %s\n',self.operationalSpeeds.Vma);
            
            % Turbine data
            fprintf(f,'\n\n');
            fprintf(f,'-------------------------------------------------------------------------\n');
            fprintf(f,'#4  TURBINE DATA\n');
            fprintf(f,'-------------------------------------------------------------------------\n\n');
            fprintf(f,'#4.1 Main Turbine Data\n');
            fprintf(f,'Turbine name                                         %s\n',self.turbineData.TurbineName);
            fprintf(f,'Converter type                                                      %s\n',self.turbineData.ConverterType);
            fprintf(f,'Rotor radius                                                   %s\n',self.turbineData.RotorRadius);
            fprintf(f,'Hub height                                                       %s\n',self.turbineData.HubHeight);
            fprintf(f,'Number of blades                                                   %s\n',self.turbineData.NumberOfBlades);
            fprintf(f,'Blade type                                            %s\n',self.turbineData.BladeType);
            fprintf(f,'Hub coning                                                   %s\n',self.turbineData.HubConing);
            fprintf(f,'Tilt angle                                                    %s\n',self.turbineData.TiltAngle);
            fprintf(f,'Blade root coning                                             %s\n',self.turbineData.BladeRootConing);
            fprintf(f,'Blade root sweep angle                                        %s\n',self.turbineData.BladeRootSweepAngle);
            fprintf(f,'Blade mass (nominal, mfac = 1.00)                             %s\n',self.turbineData.BladeMass);
            fprintf(f,'Hub mass                                                      %s\n',self.turbineData.HubMass);
            fprintf(f,'Rotor mass (mfac: 1.000 1.004 1.000)                         %s\n',self.turbineData.RotorMass);
            fprintf(f,'Nacelle mass                                                 %s\n',self.turbineData.NacelleMass);
            fprintf(f,'Hub centre relative to K (tilted axis, downw. pos.)           %s\n',self.turbineData.HubCentre);
            fprintf(f,'Nacelle CoG relative to K (tilted axis, downw. pos.)           %s\n',self.turbineData.NacelleCoG);
            fprintf(f,'Nominal power                                                  %s\n',self.turbineData.NominalPower);
            fprintf(f,'Rotor speed, nominal                                          %s\n',self.turbineData.RotorSpeed);
            fprintf(f,'Generator speed, nominal                                       %s\n',self.turbineData.GeneratorSpeed);
            fprintf(f,'Converter Overspeed alarm level                                %s\n',self.turbineData.ConverterOverspeed);
            fprintf(f,'VOG limit                                                   %s\n',self.turbineData.VOGLimit);
            fprintf(f,'Gear ratio                                                     %s\n',self.turbineData.GearRatio);
            fprintf(f,'Error level at which TYC is deactivated                     %s\n',self.turbineData.ErrorLevelTYCdeactivated);
            fprintf(f,'Error level at which TYC is activated                       %s\n',self.turbineData.ErrorLevelTYCactivated);
            fprintf(f,'Design lifetime                                               %s\n',self.turbineData.DesignLifetime);
            fprintf(f,'Tower Frequency from Eig-file                               %s\n',self.turbineData.TowerFrequency);
            fprintf(f,'\n\n');
            % Blade loads
            secNo = [1 4];
            sectionNamesToPrint = {'Extreme Flapwise Moment (-Mx)','Extreme Edgewise Moment (My)','Equivalent Flapwise Moment (-Mx, Neq=1E7)','Equivalent Edgewise Moment (My, Neq=1E7)'};
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#5  BLADE LOADS');
            % Hub, blade bearing and pitch system loads
            secNo = [secNo(2)+1 secNo(2)+7];
            sectionNamesToPrint = {'Extreme Hub Loads','Equivalent Hub Loads (Neq=1E7)','Extreme Blade Bearing Loads (kip moment)','Equivalent Blade Bearing LRD (1E7 pitch degrees) for blade with smallest pitch offset (blade: 2; PitchOffset:0deg)','Extreme Pitch Cylinder Force incl. PLF (Excl. Pitch Lock LCs)','Extreme Pitch Moment incl. PLF (Only Pitch Lock LCs)','Equivalent Pitch Cylinder Force (Neq=1E7)'};            
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#6  HUB, BLADE BEARING AND PITCH SYSTEM LOADS');
            % Drive train loads
            secNo = [secNo(2)+1 secNo(2)+4];
            sectionNamesToPrint = {'Extreme Loads at Main Bearing','Extreme Rotor Lock Loads','Equivalent Loads at Main Bearing (Neq=1E7)','Equivalent Gear Bearing LDD (Teq=20years -> 6.3072E8s) - LRD (Eq rev: 1e6)'};
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#7  DRIVE TRAIN LOADS');
            % Tower/nacelle interface loads
            secNo = [secNo(2)+1 secNo(2)+2];
            sectionNamesToPrint = {'Extreme Loads At Nacelle/Tower Interface','Equivalent Loads at Nacelle/Tower Interface (Neq=1E7)'};
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#8  TOWER/NACELLE INTERFACE LOADS');
            % Tower loads at foundation level
            secNo = [secNo(2)+1 secNo(2)+2];
            sectionNamesToPrint = {'Extreme Resultant Tower Moment at Foundation Level','Equivalent Tower Moment at Foundation Level (Neq=1E7)'};
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#9  TOWER LOADS AT FOUNDATION LEVEL');
            % Tower loads at foundation level
            secNo = [secNo(2)+1 secNo(2)+1];
            sectionNamesToPrint = {'Extreme Blade Deflection in Front of Tower (incl. PLF)'};
            self.printBladeLoads(f,secNo(1):secNo(2),sectionNamesToPrint,'#10 BLADE-TOWER CLEARANCE',true);                
            
            % Write any comments
            fprintf(f,'%s\n',self.comments);

            fclose(f);            
        end
    end
    
    methods (Abstract, Access=protected)
        sectionNames = getSectionNames(self)
        senData = addToSenData(self,senData,C,decodeID);
        printBladeLoads(self,fid,sectionNumbers,sectionNamesToPrint,header,finalSection)
    end
    
    methods (Abstract)
        addRobustificationFactors(self,RF);
    end   
    
end
