%BLD - BLD object reading VTS blade file
%Optional file header info (to give more details about the function than in the H1 line)
%Optional file header info (to give more details about the function than in the H1 line)
%Optional file header info (to give more details about the function than in the H1 line)
%
% Syntax:  bldObj = LAC.vts.codec.BLD(CoderObj)
%
% Inputs:
%    CoderObj - Description
%
% Outputs:
%    bldObj   - Blade object containing all properties of the blade
%
% Methods
%    bldObj.computeMass()
%    bldObj.compareProperties(bldObj)
%    bldObj.plotProperties(bldObj)
%
% Example:
%    bldObj = LAC.vts.convert(bladeFilename,'BLD')
%    bldObj = LAC.vts.convert(bladeFilename)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: LAC.vts.convert,

classdef BLD % < handle % < matlab.mixin.Copyable
    properties %(SetObservable)
        filename char
        bladeName
        Header
        StallModel
        NumberOfProfileDataSets
        Profile
        ProfileData
        Logd
        B,Gamma,Tilt,X_dr_tip
        GammaRootFlap,GammaRootEdge
        md
        rd,kd,Ybdmax,Khi_Klo
        structuralPitch
        nCrossSections
        PiOff
        AzOff
        KFfac
        KEfac
        KTfac
        mfac
        Jfac
        dfac
        SectionTableNrOfFields
        Retype,MFric0,mu,DL,c_fric
        unknown1
        comments
        SectionTable
%         SectionTable = struct('R',[], 'EI_Flap',[], 'EI_Edge',[], 'GIp',[], 'm',[], 'J',[], 'Xcog',[], 'Xshc',[],...
%             'UF0',[], 'UE0',[], 'C',[], 't_C',[], 'beta',[], ...
%                     'p_ang',[], 'Yac_C',[], 'PhiOut',[], 'dy_m',[], 'dy_e',[], 'dx_c',[], 'dy_c',[], 'EA',[], 'dy_pitch',[], 'Out',{});
        
        numberOfNoiseEquations
        NoiseEquations
        SVN_reference
        SVN_revision
        AeroINP
        AeroOut
    end
    
    methods (Static)
        function s = decode(Coder)
            file_data   = Coder.readFile;
            fileContent = file_data{1};
            s = eval(mfilename('class'));
            
            [s.filename] = Coder.getSource;
            
            %% Read file contents
            
            % Write bladeName
            s.bladeName=fileContent{1};
            
            % Read stall model
            data=textscan(fileContent{2},'%f',1);
            s.StallModel.Model=data{1};
            switch  s.StallModel.Model
                case 0 % No dynamic stall
                    
                case 1 % Flx5Øye
                    data=textscan(fileContent{2},'%f %f %f %f %f %f',1);
                    % Format data;
                    s.StallModel.dCLda=data{2};
                    s.StallModel.dCLdaS=data{3};
                    s.StallModel.AlfS=data{4};
                    s.StallModel.Alfrund=data{5};
                    s.StallModel.Taufak=data{6};
                case 2 % AutoØye
                    data=textscan(fileContent{2},'%f %f',1);
                    s.StallModel.Taufak=data{2};
                case 3 % Risø
                    data=textscan(fileContent{2},repmat('%f ',1,13),1);
                    s.StallModel.A1=data{2};
                    s.StallModel.A2=data{3};
                    s.StallModel.b1=data{4};
                    s.StallModel.b2=data{5};
                    s.StallModel.TauF=data{6};
                    s.StallModel.TauP=data{7};
                    s.StallModel.SigL=data{8};
                    s.StallModel.SigLh=data{9};
                    s.StallModel.SigM=data{10};
                    s.StallModel.Factor_Ast=data{11};
                    s.StallModel.Factor_CDCorr_ALFA=data{12};
                    s.StallModel.Factor_CDCorr_f=data{13};
                otherwise
                    warning('StallModel not recognized by LAC.vts.codec.BLD')
            end
            
            
            % Read profile data files
            data=textscan(fileContent{3},'%f',1);
            nProfileDataFiles=data{1};
            s.NumberOfProfileDataSets = nProfileDataFiles;
            % Format
            for i=1:nProfileDataFiles
                data=textscan(fileContent{3+i},'%s %s',1);
                s.ProfileData.(data{1}{1})=data{2}{1};
            end
            % Define position variable
            filePos=3+nProfileDataFiles;
            
            % Read Logd
            data=textscan(fileContent{filePos+1},'%f');
            s.Logd=data{1};
            
            % Read B Gamma Tilt X-dr.tip
            data=textscan(fileContent{filePos+2},'%f %f %f %f %f');
            s.B=data{1};
            s.Gamma=data{2};
            s.Tilt=data{3};
            s.X_dr_tip(1)=data{4};
            if ~isempty(data{5})
                s.X_dr_tip(2)=data{5};
            end
            
            % Read GammaRootFlap GammaRootEdge
            data=textscan(fileContent{filePos+3},'%f %f');
            s.GammaRootFlap=data{1};
            s.GammaRootEdge=data{2};
            
            % Read rd; md1; md2; md3; kd; Ybdmax; Khi/Klo
            data=textscan(fileContent{filePos+4},'%f %f %f %f %f %f %f','CollectOutput',1);
            s.rd=data{1}(1);
            s.md=data{1}(2:4);
            s.kd=data{1}(5);
            s.Ybdmax=data{1}(6);
            s.Khi_Klo=data{1}(7);
            
            % Read structuralPitch
            data=textscan(fileContent{filePos+5},'%f');
            s.structuralPitch=data{1};
            
            % Read PiOff
            data=textscan(fileContent{filePos+6},'%f');
            s.PiOff=data{1};
            
            % Read AzOff
            data=textscan(fileContent{filePos+7},'%f');
            s.AzOff=data{1};
            
            % Read KFfac
            data=textscan(fileContent{filePos+8},'%f');
            s.KFfac=data{1};
            
            % Read KEfac
            data=textscan(fileContent{filePos+9},'%f');
            s.KEfac=data{1};
            
            % Read KTfac
            data=textscan(fileContent{filePos+10},'%f');
            s.KTfac=data{1};
            
            % Read mfac
            data=textscan(fileContent{filePos+11},'%f');
            s.mfac=data{1};
            
            % Read Jfac
            data=textscan(fileContent{filePos+12},'%f');
            s.Jfac=data{1};
            
            % Read dfac
            data=textscan(fileContent{filePos+13},'%f');
            s.dfac=data{1};
            
            % Read nCrossSections
            data=textscan(fileContent{filePos+14},'%f',1);
            s.nCrossSections=data{1};
            
            % Read SectionTable
            %frewind(FID);
            %data=textscan(FID,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %[^\n]',s.nCrossSections,'headerLines',filePos+17,'whitespace','\t\n');
            headings = textscan(fileContent{filePos+16}, '%s');
            s.SectionTableNrOfFields = length(headings{1});
            formatStr = [];
            for i=1:s.SectionTableNrOfFields-1
                formatStr = [formatStr '%f '];
            end
            formatStr = [formatStr '%[^\n]'];
            
            % Format into fields
            names16={ 'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'Yac_C' 'PhiOut' 'Out'};
            names17={ 'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'p_ang' 'Yac_C' 'PhiOut' 'Out'};
            names23={ 'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'p_ang' 'Yac_C' 'PhiOut' 'dy_m' 'dy_e' 'dx_c' 'dy_c' 'EA' 'dy_pitch' 'Out'};
            
            for iLine = 1 : s.nCrossSections
                data=textscan(fileContent{iLine+filePos+17}, formatStr,'whitespace','\t\n');
                
                switch s.SectionTableNrOfFields
                    case 16
                        for i=1:s.SectionTableNrOfFields
                            s.SectionTable.(names16{i})(iLine,1)=data{i};
                        end
                    case 17
                        for i=1:s.SectionTableNrOfFields
                            s.SectionTable.(names17{i})(iLine,1)=data{i};
                        end
                    case 23
                        for i=1:s.SectionTableNrOfFields
                            s.SectionTable.(names23{i})(iLine,1)=data{i};
                        end
                end
                
            end
            
            if isfield(s.SectionTable,'Out') % might not be present if nCrossSections == 0
                % Remove \n from out column
                s.SectionTable.Out=strtrim(s.SectionTable.Out);
                s.SectionTable.Out=regexprep(s.SectionTable.Out,'\t',' ');
            end
            
            filePos=filePos+17+s.nCrossSections;
            
            % Read Retype; MFric0; mu; DL; c
            data=textscan(fileContent{filePos+1},'%f %f %f %f %f',1);
            s.Retype=data{1};
            s.MFric0=data{2};
            s.mu=data{3};
            s.DL=data{4};
            s.c_fric=data{5};
            filePos = filePos+1;
            
            % Read noise equations
            if ~cellfun(@isempty,regexp(fileContent{filePos+1},'^\d+\s','match'))
                s.numberOfNoiseEquations = cellfun(@(x) str2double(x),regexp(fileContent{filePos+1},'^\d+','match'));
                filePos = filePos+1;
                for iNoise = 1:s.numberOfNoiseEquations
                    s.NoiseEquations{iNoise}.Name =  cell2mat(regexp(fileContent{filePos+1},'^\w+','match'));
                    filePos = filePos+1;
                    s.NoiseEquations{iNoise}.Version =  cellfun(@(x) str2double(x),regexp(fileContent{filePos+1},'(?<=NoiseEquationVersion\s+)\d','match'));
                    
                    % Handle for legacy
                    if isempty(s.NoiseEquations{iNoise}.Version)
                        s.NoiseEquations{iNoise}.Version = 0;
                    else
                        filePos = filePos+1;
                    end
                    
                    s.NoiseEquations{iNoise}.NumberOfRadii =  cellfun(@(x) str2double(x),regexp(fileContent{filePos+1},'(?<=^\s*)\d+','match'));
                    filePos = filePos+1;
                    
                    for iRadii = 1:s.NoiseEquations{iNoise}.NumberOfRadii
                        switch s.NoiseEquations{iNoise}.Version
                            case 0
                                values = strsplit_LMT(cell2mat(regexp(fileContent{filePos+1},'(?<=^\s*)\d*\.*\d*\s+-?\d*\.*\d*','match')));
                            case 1
                                values = strsplit_LMT(cell2mat(regexp(fileContent{filePos+1},'(?<=^\s*)\d*\.*\d*\s+-?\d*\.*\d*\s+-?\d*\.*\d*\s+-?\d*\.*\d*','match')));
                            otherwise
                                error('NoiseEquationVersion not known');
                        end
                        s.NoiseEquations{iNoise}.Radii(iRadii).Radius = str2double(values{1});
                        s.NoiseEquations{iNoise}.Radii(iRadii).A = values(2:end);
                        filePos = filePos+1;
                    end
                    
                    switch s.NoiseEquations{iNoise}.Version
                        case 0
                            values = strsplit_LMT(cell2mat(regexp(fileContent{filePos+1},['(?<=^\s*)',repmat('-?\d*\.*\d*\s+',1,4),'\d*\.*\d*'],'match')));
                        case 1
                            values = strsplit_LMT(cell2mat(regexp(fileContent{filePos+1},['(?<=^\s*)',repmat('-?\d*\.*\d*\s+',1,9),'\d*\.*\d*'],'match')));
                        otherwise
                            error('NoiseEquationVersion not known');
                    end
                    s.NoiseEquations{iNoise}.BCD = values;
                    filePos = filePos+1;
                end
            end
            
            remainingLines = fileContent(filePos+1:end);
            
            % read SVN reference and Aero .INP and .OUT references if present.
            regularExpressions = {'(?<=^\s*)SVN reference:' '(?<=^\s*)SVN rev.:' '(?<=^\s*)Aero-file Reference \(\.inp\):' '(?<=^\s*)Aero-file Reference \(\.out\):'};
            parameterNames = { 'SVN_reference' 'SVN_revision' 'AeroINP' 'AeroOut'};
            
            for iParameter = 1:length(parameterNames)
                lineNumber = find(~cellfun(@isempty,regexp(remainingLines,regularExpressions{iParameter})));
                if ~isempty(lineNumber)
                   line = remainingLines{lineNumber};
                   remainingLines(lineNumber) = []; % deleting from remaining lines.
                   s.(parameterNames{iParameter}) = cell2mat(regexp(line,['(?<=(',regularExpressions{iParameter},')\s*)\S+'],'match'));
                end
            end
            
            % delete any leading empty lines
            while ~isempty(remainingLines) && strcmp(strtrim(remainingLines{1}),'');
                remainingLines(1) =[];
            end
            
            % Read any comments
            s.comments = remainingLines;
            
        end
    end
    
    methods
        function help(self)
            help LAC.vts.codec.BLD
        end
%         function obj = BLD()
%             addlistener(obj,'SectionTable','PostSet',@obj.setPropEvt);
%         end
%         function setPropEvt(obj,src,evnt)
%             disp ('Pre-set event triggered')
%             obj.SectionTable
%             % ...
%         end
        function encode(self,filename)
            fid = fopen(filename,'wt');
            % Write bladeName
            fprintf(fid,'%s\n',self.bladeName);
            
            % Write stall model
            switch  self.StallModel.Model
                case {0,4,5} % No dynamic stall
                    fprintf(fid,'%g ',self.StallModel.Model);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t Model\n');
                case 1 % Flx5Øye
                    fprintf(fid,'%g %g %g %g %g %g ',[self.StallModel.Model self.StallModel.dCLda self.StallModel.dCLdaS self.StallModel.AlfS self.StallModel.Alfrund self.StallModel.Taufak]);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t Model dCLda dCLdaS AlfS Alfrund Taufak\n');
                case 2 % AutoØye
                    fprintf(fid,'%g %g ',[self.StallModel.Model self.StallModel.Taufak]);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t Model Taufak\n');
                case 3 % Risø
                    fprintf(fid,repmat('%g ',1,13),[self.StallModel.Model self.StallModel.A1 self.StallModel.A2 self.StallModel.b1 self.StallModel.b2 self.StallModel.TauF self.StallModel.TauP self.StallModel.SigL self.StallModel.SigLh self.StallModel.SigM self.StallModel.Factor_Ast self.StallModel.Factor_CDCorr_ALFA self.StallModel.Factor_CDCorr_f]);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t Model A1 A2 b1 b2 TauF TauP SigL SigLh SigM Factor_Ast Factor_CDCorr_ALFA Factor_CDCorr_f\n');
                otherwise
                    warning('StallModel not recognized by LAC.vts.codec.BLD')
            end
            
            % Write profile data files
            pro_name=fieldnames(self.ProfileData);
            fprintf(fid,'%i \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t Number of profile data sets\n',length(pro_name));
            for iProfile = 1:length(pro_name)
                fprintf(fid,'%s\t %s\n',pro_name{iProfile},self.ProfileData.(pro_name{iProfile}));
            end
            
            % Write Logd
            fprintf(fid,'%6.3f',self.Logd);
            fprintf(fid,'\t\t\t\t LogD for blade DOF 1-8 (Blade mode 1-6, blade damper, Quasistatic torsion)\n');
            
            % Write B Gamma Tilt X-dr.tip
            fprintf(fid,'%i %4.2f %4.2f %4.3f %4.1f\t',[self.B self.Gamma self.Tilt],self.X_dr_tip);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t B; Gamma; Tilt; Rtipcut Delta3(0 for a non-teeter system) \n');
            % Write GammaRootFlap GammaRootEdge
            fprintf(fid,'%5.3f\t%5.3f',self.GammaRootFlap,self.GammaRootEdge);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t GammaRootFlap GammaRootEdge \n');
            % Write rd; md1; md2; md3; kd; Ybdmax; Khi/Klo
            fprintf(fid,'%6.2f\t',self.rd,self.md,self.kd,self.Ybdmax,self.Khi_Klo);
            fprintf(fid,' Rbd Mbd11 Mbd12 Mbd22 Kbd Ybdmax Khi/Klo \n');
            
            % Write structuralPitch
            fprintf(fid,'%4.2f\t',self.structuralPitch);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t Structural pitch \n');
            
            % Write PiOff
            fprintf(fid,'%6.2f\t',self.PiOff);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t PiOff1 PiOff2 PiOff3 \n');
            
            % Write AzOff
            fprintf(fid,'%6.2f\t',self.AzOff);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t AzOff1 AzOff2 AzOff3 \n');
            
            % Write KFfac
            fprintf(fid,'%6.4f\t',self.KFfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t KFfac1 KFfac2 KFfac3 \n');
            
            % Write KEfac
            fprintf(fid,'%6.4f\t',self.KEfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t KEfac1 KEfac2 KEfac3 \n');
            
            % Write KTfac
            fprintf(fid,'%6.4f\t',self.KTfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t KTFac1 KTFac2 KTfac3 \n');
            
            % Write mfac
            fprintf(fid,'%6.4f\t',self.mfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t mfac1 mfac2 mfac3 \n');
            
            % Write Jfac
            fprintf(fid,'%6.4f\t',self.Jfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t Jfac1 Jfac2 Jfac3 \n');
            
            % Write dfac
            fprintf(fid,'%6.4f\t',self.dfac);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t dfac1 dfac2 dfac3 \n');
            
            % Write nCrossSections
            fprintf(fid,'%i\t',self.nCrossSections);
            fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t nCrossSections \n');
            
            % Format into fields
            names16={ 'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'Yac_C' 'PhiOut' 'Out'};
            
            names17={ 'R' 'EI_2' 'EI_1' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'p_ang' 'Yac_C' 'PhiOut' 'Out'};
            
            names23={ 'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'p_ang' 'Yac_C' 'PhiOut' 'dy_m' 'dy_e' 'dx_c' 'dy_c' 'EA' 'dy_pitch' 'Out'};
            
            
            % Write SectionTable
            switch self.SectionTableNrOfFields
                case 16
                    fprintf(fid,'----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    fprintf(fid,'%s\t\t\t',names16{:});
                    fprintf(fid,'\n----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    for i=1:self.nCrossSections
                        fprintf(fid,'%6.3f\t %4.2e\t %4.2e\t %4.2e\t %7.1f\t %7.1f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t %6.2f\t %5.2f\t %4.2f\t %6.2f\t %s',...
                            self.SectionTable.R(i),self.SectionTable.EI_Flap(i),self.SectionTable.EI_Edge(i),self.SectionTable.GIp(i),self.SectionTable.m(i),self.SectionTable.J(i),...
                            self.SectionTable.Xcog(i),self.SectionTable.Xshc(i),self.SectionTable.UF0(i),self.SectionTable.UE0(i),...
                            self.SectionTable.C(i),self.SectionTable.t_C(i),self.SectionTable.beta(i),self.SectionTable.Yac_C(i),...
                            self.SectionTable.PhiOut(i),self.SectionTable.Out{i});
                        fprintf(fid,'\n');
                    end
                    
                case 17
                    fprintf(fid,'----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    fprintf(fid,'%s\t\t\t',names17{:});
                    fprintf(fid,'\n----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    for i=1:self.nCrossSections
                        fprintf(fid,'%6.3f\t %4.2e\t %4.2e\t %4.2e\t %7.1f\t %7.1f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t %6.2f\t %5.2f\t %6.2f\t %4.2f\t %6.2f\t %s',...
                            self.SectionTable.R(i),self.SectionTable.EI_Flap(i),self.SectionTable.EI_Edge(i),self.SectionTable.GIp(i),self.SectionTable.m(i),self.SectionTable.J(i),...
                            self.SectionTable.Xcog(i),self.SectionTable.Xshc(i),self.SectionTable.UF0(i),self.SectionTable.UE0(i),...
                            self.SectionTable.C(i),self.SectionTable.t_C(i),self.SectionTable.beta(i), self.SectionTable.p_ang(i), ...
                            self.SectionTable.Yac_C(i),self.SectionTable.PhiOut(i),self.SectionTable.Out{i});
                        fprintf(fid,'\n');
                    end
                    
                case 23
                    fprintf(fid,'----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    fprintf(fid,'%s\t\t\t',names23{:});
                    fprintf(fid,'\n----------------------------------------------------------------------------------------------------------------------------------------------------------------\n');
                    for i=1:self.nCrossSections
                        formatStr = [           '%6.3f\t %4.2e\t %4.2e\t %4.2e\t %7.1f\t '];
                        formatStr = [formatStr, '%7.1f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t '];
                        formatStr = [formatStr, '%7.3f\t %6.2f\t %5.2f\t %6.2f\t %4.2f\t'];
                        formatStr = [formatStr, '%6.2f\t %7.3f\t %7.3f\t %7.3f\t %7.3f\t %4.2e\t %7.3f\t %s'];
                        fprintf(fid,formatStr, ...
                            self.SectionTable.R(i),self.SectionTable.EI_Flap(i),self.SectionTable.EI_Edge(i),self.SectionTable.GIp(i),self.SectionTable.m(i),self.SectionTable.J(i),...
                            self.SectionTable.Xcog(i),self.SectionTable.Xshc(i),self.SectionTable.UF0(i),self.SectionTable.UE0(i),...
                            self.SectionTable.C(i),self.SectionTable.t_C(i),self.SectionTable.beta(i), self.SectionTable.p_ang(i), ...
                            self.SectionTable.Yac_C(i),self.SectionTable.PhiOut(i),self.SectionTable.dy_m(i),self.SectionTable.dy_e(i), ...
                            self.SectionTable.dx_c(i),self.SectionTable.dy_c(i),self.SectionTable.EA(i),self.SectionTable.dy_pitch(i),self.SectionTable.Out{i});
                        fprintf(fid,'\n');
                    end
            end
            
            % Write Retype; MFric0; mu; DL
            fprintf(fid,'%1.0f\t %4.2e\t %6.4f\t %8.2f\t %8.1f',self.Retype,self.MFric0,self.mu,self.DL,self.c_fric);
            fprintf(fid,'\t Retype; MFric0 [Nm];mu;DL [m] \n');
            
            % Write Noise equations if present
            for iNoise = 1: self.numberOfNoiseEquations
                if iNoise == 1
                    % Number of noise equations
                    fprintf(fid,'%i\t',self.numberOfNoiseEquations);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tNumber of noise equations\n');
                end
                    fprintf(fid,'%s\n',self.NoiseEquations{iNoise}.Name);
                    fprintf(fid,'\tNoiseEquationVersion %i\n',self.NoiseEquations{iNoise}.Version);
                    fprintf(fid,'\t%i',self.NoiseEquations{iNoise}.NumberOfRadii);
                    fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tNumber of radii (one per line)\n');

                    for iRadii = 1:self.NoiseEquations{iNoise}.NumberOfRadii
                        fprintf(fid,'\t%1.2f',self.NoiseEquations{iNoise}.Radii(iRadii).Radius);
                        fprintf(fid,'\t%s',self.NoiseEquations{iNoise}.Radii(iRadii).A{:});
                        switch self.NoiseEquations{iNoise}.Version
                            case 0
                                fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t%s\n','Radius[%] A');
                            case 1
                                fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t%s\n','Radius[%] A1 A2 AoASwitch[deg]');
                            otherwise
                                error('NoiseEquationVersion not known');
                        end
                    end
                    fprintf(fid,'\t%s',self.NoiseEquations{iNoise}.BCD{:});
                    switch self.NoiseEquations{iNoise}.Version
                            case 0
                                fprintf(fid,'\t\t\t\t\t\t\t\t\t\t\t%s\n','B Cmodified Cconst D Dref');
                            case 1
                                fprintf(fid,'\t\t\t\t\t%s\n','B1 Cmodified1 Cconst1 D1 Dref1 B2 Cmodified2 Cconst2 D2 Dref2');
                            otherwise
                                error('NoiseEquationVersion not known');
                    end
            end
            
            if ~isempty(self.SVN_reference)
                fprintf(fid,'\nSVN reference: %s\n',self.SVN_reference);
            end
            if ~isempty(self.SVN_revision)
                fprintf(fid,'SVN rev.: %s\n',self.SVN_revision);
            end
            
            if ~isempty(self.AeroINP)
                fprintf(fid,'\nAero-file Reference (.inp): %s\n',self.AeroINP);
            end
            if ~isempty(self.AeroOut)
                fprintf(fid,'Aero-file Reference (.out): %s\n\n',self.AeroOut);
            end
            
            % Write any comments
            for i=1:length(self.comments)
                fprintf(fid,'%s',self.comments{i});
                fprintf(fid,'\n');
            end
            fclose(fid);
        end
        
        function result = computeMass(self)
            %% Calculation of blade mass, mass moment and inertia, the same way it's done in VTS (from THK)
            GFT = zeros(size(self.SectionTable.R));
            GFR = zeros(size(self.SectionTable.R));
            
            dR   = diff(self.SectionTable.R);
            
            GFT(1)       = dR(1)/2;
            GFT(2:end-1) = (dR(1:end-1)+dR(2:end))/2;
            GFT(end)     = dR(end)/2;
            
            GFR(1)          = (self.SectionTable.R(1)/2 + dR(1)/6)*dR(1);
            GFR(2:end-1)    = (self.SectionTable.R(2:end-1)/2 + dR(2:end)/6).*dR(2:end) + ...
                              (self.SectionTable.R(1:end-2)/2 + dR(1:end-1)/3).*dR(1:end-1);
            GFR(end)        = (self.SectionTable.R(end-1)/2 + dR(end)/3).*dR(end);
            
            result.Mass        = sum(GFT.*self.SectionTable.m);
            result.Smom        = sum(GFR.*self.SectionTable.m);
            result.Smom1       = sum(GFT.*self.SectionTable.R.*self.SectionTable.m);
            result.Imom        = sum(GFR.*self.SectionTable.R.*self.SectionTable.m);
        end
        function hFig = plotProperties(self)
            hFig=figure;
            set(hFig,'color','white'); set(hFig, 'Position', [120 75 900 700]);
            
            % parameters = {'EI_Edge','EI_Flap','J','GIp','Xcog','Xshc','m','p_ang'};
            parameters = fieldnames(self.SectionTable);
            
            for iPar = 2:length(parameters)-2
                hAx(iPar-1) = subplot(ceil((length(parameters)-3)/2),2,iPar-1);
                plot(self.SectionTable.R,self.SectionTable.(parameters{iPar}),'k'); hold on; grid on;
                ylabel(strrep(parameters{iPar},'_',' '))
                if iPar == (length(parameters)-3) || iPar == (length(parameters)-2)
                    xlabel('Radius [m]')
                end
            end
            suptitle('Blade Properties')
            string = sprintf('Path to bladefile:\n%s',self.filename);
            txtBox = uicontrol('style','text');
            set(txtBox,'String',string)
            set(txtBox,'Position',[100,5,1000,40])
            set(txtBox,'BackgroundColor',[1,1,1])
            set(txtBox,'HorizontalAlignment','left')
            linkaxes(hAx','x');
        end
        function hFig=compareProperties(self,bldObj,method)
            % If a single BLD object is input, place it in a cell
            if ~iscell(bldObj); bldObj = {bldObj}; end
            lineColors = lines(length(bldObj));
            hFig=figure;
            set(hFig,'color','white'); set(hFig, 'Position', [120 75 1000 800]);
            parameters = fieldnames(self.SectionTable);
            if nargin==2 || strcmp(method,'absolute');
                % Plot this blade
                for iPar = 2:length(parameters)-2
                    hAx(iPar-1) = subplot(ceil((length(parameters)-3)/2),2,iPar-1);
                    plot(self.SectionTable.R,self.SectionTable.(parameters{iPar}),'k'); hold on;  grid on;
                    ylabel(strrep(parameters{iPar},'_',' '))
                    if iPar == (length(parameters)-3) || iPar == (length(parameters)-2)
                        xlabel('Radius [m]')
                    end
                end
                % Plot other blades
                for iBLD = 1:length(bldObj)
                    for iPar = 2:length(parameters)-2
                        subplot(ceil((length(parameters)-3)/2),2,iPar-1);
                        plot(bldObj{iBLD}.SectionTable.R,bldObj{iBLD}.SectionTable.(parameters{iPar}),'color',lineColors(iBLD,:)); hold on;
                    end
                end
                plotName = 'Blade Properties Comparison';
                hold off
            elseif strcmp(method,'relative');
                for iBLD = 1:length(bldObj)
                    for iPar = 2:length(parameters)-2
                        hAx(iPar-1) = subplot(ceil((length(parameters)-3)/2),2,iPar-1);
                        if max(strcmp({'p_ang','beta'},parameters{iPar}))
                            plot(self.SectionTable.R,interp1(bldObj{iBLD}.SectionTable.R,bldObj{iBLD}.SectionTable.(parameters{iPar}),self.SectionTable.R)-self.SectionTable.(parameters{iPar}),'color',lineColors(iBLD,:)); hold on; grid on;
                            ylabel([strrep(parameters{iPar},'_',' ') ' [deg]'])
                        elseif max(strcmp({'Xcog','Xshc'},parameters{iPar}))
                            relativetochord = (interp1(bldObj{iBLD}.SectionTable.R,bldObj{iBLD}.SectionTable.(parameters{iPar}),self.SectionTable.R)-self.SectionTable.(parameters{iPar}))./self.SectionTable.C*100;
                            plot(self.SectionTable.R,relativetochord,'color',lineColors(iBLD,:)); hold on; grid on;
                            ylabel([strrep(parameters{iPar},'_',' ') ' [%/C]'])
                        elseif max(strcmp({'t_C'},parameters{iPar}))
                            plot(self.SectionTable.R,interp1(bldObj{iBLD}.SectionTable.R,bldObj{iBLD}.SectionTable.(parameters{iPar}),self.SectionTable.R)-self.SectionTable.(parameters{iPar}),'color',lineColors(iBLD,:)); hold on; grid on;
                            ylabel([strrep(parameters{iPar},'_',' ') ' [t/C]'])
                        else
                            plot(self.SectionTable.R,(interp1(bldObj{iBLD}.SectionTable.R,bldObj{iBLD}.SectionTable.(parameters{iPar}),self.SectionTable.R)-self.SectionTable.(parameters{iPar}))./self.SectionTable.(parameters{iPar})*100,'color',lineColors(iBLD,:)); hold on; grid on;
                            ylabel([strrep(parameters{iPar},'_',' ') ' [%]'])
                        end
                        if iPar == (length(parameters)-3) || iPar == (length(parameters)-2)
                            xlabel('Radius [m]')
                        end
                    end
                end
                plotName = 'Blade Properties Comparison, Relative';
            end
            
            linkaxes(hAx','x');
            
            allAxes = [findall(hFig.Children,'Type','Axes'); findall(hFig.Children,'Type','uitable')];
            set(allAxes,'Units','Normalized');
            outerPositions = get(allAxes,'OuterPosition');
            if length(allAxes)>1
                outerPositions = cell2mat(outerPositions);
            end
            lowerPlotsID = find(outerPositions(:,2)<min(outerPositions(:,2))*1.05);
            for iAx = 1:length(allAxes)
                if any(iAx == lowerPlotsID)
                    newPositions = [outerPositions(iAx,1) outerPositions(iAx,2)+0.1*outerPositions(iAx,4)*length(bldObj) outerPositions(iAx,3) outerPositions(iAx,4)*0.9];
                else
                    newPositions = [outerPositions(iAx,1) outerPositions(iAx,2)+0.1*outerPositions(iAx,4) outerPositions(iAx,3) outerPositions(iAx,4)*0.9];
                end
               set(allAxes(iAx),'OuterPosition',newPositions);
            end
            
            pathText{1} = sprintf('\\color[rgb]{%f, %f, %f}%s\n',[0 0 0],strrep(strrep(self.filename,'\','\\'),'_','\_'));
            for i = 1:length(bldObj)
                if i<length(bldObj)
                    format = '\\color[rgb]{%f, %f, %f}%s\n';
                else
                   format = '\\color[rgb]{%f, %f, %f}%s';
                end
                pathText{end+1} = sprintf(format,lineColors(i,:),strrep(strrep(bldObj{i}.filename,'\','\\'),'_','\_'));
            end
            pathText = cell2mat(pathText);
          
            annotation(hFig,'textbox',[0.01 0.03 0.01 0.02*length(bldObj)],'String',...
              pathText,'FitBoxToText','on',...
              'FontSize',7);
          suptitle(plotName)
        end
        
        function self = addSection(self,R,Out,Phi)
            if ~isempty(find(self.SectionTable.R==R,1))
                error('Section at %4.2f already exist!',R)
            end
            
            idxInsert = find(self.SectionTable.R<R,1,'last');
            newR = [self.SectionTable.R(1:idxInsert); R; self.SectionTable.R(idxInsert+1:end)];
            
            fields    = fieldnames(self.SectionTable);
            validFields = {'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 'UE0' 'C' 't_C' 'beta' ...
                    'p_ang' 'Yac_C' 'PhiOut' 'dy_m' 'dy_e' 'dx_c' 'dy_c' 'EA' 'dy_pitch' 'EI_1' 'EI_2'};
            for iField = 1:length(fields)
                if max(strcmp(fields{iField},validFields))==1;
                    self.SectionTable.(fields{iField}) = interp1(self.SectionTable.R,self.SectionTable.(fields{iField}),newR);
                end
            end
            
            self.SectionTable.Out = [self.SectionTable.Out(1:idxInsert); Out; self.SectionTable.Out(idxInsert+1:end)];
            self.SectionTable.R   = newR;
            
            if nargin == 4
                self.SectionTable.PhiOut(idxInsert+1) = Phi;
            end
            
            self.nCrossSections = length(self.SectionTable.R);
        end
        
        function self = mergeProperty(self,bldObj,property)
        %MERGEPROPERTY - Merge a sectional property with another blade
        % Merge a property in the sectional table with another blade by
        % interpolating with the radius
        %
        % Syntax:  [self] = obj.mergeProperty(bldObj,property)
        %
        % Inputs:
        %    bldObj - Blade object where the property should be taken
        %    property - String with the property which should be replaced.
        %           'R' 'EI_Flap' 'EI_Edge' 'GIp' 'm' 'J' 'Xcog' 'Xshc' 'UF0' 
        %           'UE0' 'C' 't_C' 'beta' 'p_ang' 'Yac_C' 'PhiOut' 'dy_m' 
        %           'dy_e' 'dx_c' 'dy_c' 'EA' 'dy_pitch' 'Out'
        %
        % Outputs:
        %    self - The object is returned
        %
        % Example: 
        %    [self] = obj.mergeProperty(bldObj,property)
        %
        % Other m-files required: none
        % Subfunctions: none
        % MAT-files required: none
        %
        % See also: 
                self.SectionTable.(property) = interp1(bldObj.SectionTable.R,bldObj.SectionTable.(property),self.SectionTable.R);
        end
        
        function self = setOutput(self,dR,outputStr)
            radius = self.SectionTable.R(end);
            
            for iSection = 1:floor(radius)/dR
                idx = find(abs(self.SectionTable.R-dR*iSection)==min(abs(self.SectionTable.R-dR*iSection)),1,'first');
                self.SectionTable.Out{idx} = outputStr;
            end
            
            self.SectionTable.Out{end} = outputStr;
        end
        
        function bldObj = setStandardOutputSensors(bldObj,outputType)
        %setStandardOutputSensors - Set standard OUT sensors
        % Possibility to set the sensor output to some predefined standard
        % output types.
        %
        % Syntax:  bldObj = setStandardOutputSensors(bldObj,outputType)
        %
        % Inputs:
        %    bldObj - Blade object where output should be set
        %    outputType - char array. Three standard outputs are available:
        %       'Standard output': All forces/moments at root (6.123) station.
        %       (4.123) output is present at 20 stations with quadratic spacing 
        %       from root, i.e. stations = linspace(0,1,20).^2. All 
        %       outputs are printed at tip. Also (4.123 aoa) are printed at
        %       noise calculation radii stations.
        %       'Extended output' All possible sensor output at every
        %       station (6.123 aoa cl cd cm torsion v ux uy induction 
        %       LEpos TEpos).
        %       'No output' No output at all stations.
        %
        % Outputs:
        %    self - The object is returned
        %
        % Example: 
        %    [self] = obj.mergeProperty(bldObj,property)
        %
        % Other m-files required: none
        % Subfunctions: none
        % MAT-files required: none
        %
        % See also: 
            radii = (bldObj.SectionTable.R - bldObj.SectionTable.R(1))/((bldObj.SectionTable.R(end) - bldObj.SectionTable.R(1)));
            switch outputType
                case 'Standard output'
                    % quadratic spacing between stations
                    stationRatios = linspace(0,1,20).^2;                    
                    [~,stationIndices] = min(abs(radii-stationRatios));
                    stationIndices = unique(stationIndices);
                    
                    for i = 1:bldObj.nCrossSections
                        if i==1
                            bldObj.SectionTable.Out{i} = '6.123'; % All forces/moments at root.
                        elseif  i==bldObj.nCrossSections
                            bldObj.SectionTable.Out{i} = '6.123 aoa cl cd cm torsion v ux uy induction LEpos TEpos'; % Full at tip
                        elseif ismember(i,stationIndices)
                            bldObj.SectionTable.Out{i} = '4.123'; % standard output
                        else
                            bldObj.SectionTable.Out{i} = '0';
                        end
                    end
                    bldObj = addNoiseAoA(bldObj);
                    bldObj = addIntPostDInterpolationSensors(bldObj);
                    
                case 'Extended output'
                    for i=1:length(bldObj.SectionTable.R)
                        bldObj.SectionTable.Out{i} = '6.123 aoa cl cd cm torsion v ux uy induction LEpos TEpos';
                    end
                case 'No output'
                    for i=1:length(bldObj.SectionTable.R)
                        bldObj.SectionTable.Out{i} = '0';
                    end
                case 'Add noise sensors'
                    bldObj = addNoiseAoA(bldObj);
                case 'Add IntPostD interpolation sensors'
                    bldObj = addIntPostDInterpolationSensors(bldObj);
            end
            
            %% addNoiseAoA: Add AoA sensors for noise calculations
            function bldObj = addNoiseAoA(bldObj)
                %                 radii = (bldObj.SectionTable.R - bldObj.SectionTable.R(1))/((bldObj.SectionTable.R(end) - bldObj.SectionTable.R(1)));
                % Find stations closest to noise radii points.
                noiseStation = [];
                for iNoise = 1:bldObj.numberOfNoiseEquations
                    for iRadii = 1:bldObj.NoiseEquations{iNoise}.NumberOfRadii
                        noiseLocal = find(radii<bldObj.NoiseEquations{iNoise}.Radii(iRadii).Radius/100,1,'last');
                        noiseStation = [noiseStation noiseLocal noiseLocal+1]; % aoa at station before and after
                    end
                end
                
                for i = 1:bldObj.nCrossSections
                    if ismember(i,noiseStation) && ~contains(bldObj.SectionTable.Out{i},'aoa','IgnoreCase',true)
                        bldObj.SectionTable.Out{i} = [bldObj.SectionTable.Out{i} ' aoa'];
                    end
                end
            end
                     
            %% addIntPostDInterpolationSensors: Add sensors at closest stations to MainLoads interpolated sensors.
            function bldObj = addIntPostDInterpolationSensors(bldObj)
                %                radii = (bldObj.SectionTable.R - bldObj.SectionTable.R(1))/((bldObj.SectionTable.R(end) - bldObj.SectionTable.R(1)));
                stationRatios = ([2:8]-1)./8; % eight stations with equal distance (as in IntPostD MainLoads.txt)
                [~,stationIndices] = min(abs(radii-stationRatios));
                stationIndices = unique(stationIndices);
                
                for i = 1:bldObj.nCrossSections
                    if ismember(i,stationIndices)
                        bldObj.SectionTable.Out{i} = regexprep(bldObj.SectionTable.Out{i},'^[0-6]\.?[1-3]{0,3}','4.123');
                    end
                    if isempty(bldObj.SectionTable.Out{i})
                        bldObj.SectionTable.Out{i} = '0';
                    end
                end
            end
        end
    end
end
