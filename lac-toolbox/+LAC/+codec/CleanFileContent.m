classdef CleanFileContent
    properties
        AddVersionToFileNames = [];          % Set to object of type RefModelReader
        ExportedFrom     = '';               % Example: (Exported from svn://filename@42)
        PartsFolder      = '..\parts\';       % [REPOSITORYPARTS]
        ProfilesFolder   = '..\..\profiles\';   % [REPOSITORYPROFILES]\
        ParametersFolder = '..\..\parameters\'; % [REPOSITORYPARAMETERS]\
        NewFileNames = [];                    % Set to output from RefModelReader.search()
    end
    
    methods
        function cleanedfile = clean(self, type, filename, varargin)
            switch(type)
                case 'refmodels'
                    cleanedfile = self.searchAndReplacePathsInRefModel(filename);
                case 'parts'
                    cleanedfile = self.searchAndReplacePathsInPart(filename, varargin{1});
                case 'profiles'
                    cleanedfile = self.searchAndReplacePathsInProfile(filename);
                case 'parameters'
                    cleanedfile = self.searchAndReplacePathsInParameter(filename);
                otherwise
                    error(['You tried to clean a unsupport type: ' type])
            end
        end
        
        function tmpfile = searchAndReplacePathsInRefModel(self, inputfilename)
            tmpfile = tempname;
            if ~strcmp(inputfilename, tmpfile)
                copyfile(inputfilename, tmpfile);
                fileattrib(tmpfile,'+w');
            end
            
            FID = lib.safefopen(tmpfile);
            if FID>0
                % Decode refmodel
                coder_refmodel = codec.ReferenceModel();
                refmodeldecoded = coder_refmodel.decode(FID);
                refmodeldecodedoriginal = refmodeldecoded;
                fclose(FID);
                
                % Clean error name file
                clean_obj = codec.CleanFileName();
                [folder,myfilename,ext] = fileparts(clean_obj.clean('parts', refmodeldecoded.NameErrorFile,'.'));
                if ~isempty(strfind(folder,'ERR'))
                    refmodeldecoded.NameErrorFile = [folder '\' myfilename ext];
                else
                    refmodeldecoded.NameErrorFile = ['ERR\' myfilename,ext];
                end
                refmodeldecoded = self.correctErrorNameFile(refmodeldecoded);
                
                % Clean parts folder
                refmodeldecoded.PartsFolder = self.PartsFolder;
                
                tmp = refmodeldecoded.components.keys;
                for i=1:length(tmp)
                    if ~isempty(self.NewFileNames)
                        % Correct part file name, if existing file found
                        existingpartdata = self.NewFileNames(find(strcmpi({self.NewFileNames.Type},tmp{i}),1));
                        if ~strcmpi(existingpartdata.MD5HashFileName,'None')
                            [~, tmpa, tmpb] = fileparts(existingpartdata.MD5HashFileName);
                            refmodeldecoded.components(tmp{i}) = [tmpa tmpb];
                        end
                    end
                    % Clean @version and _rXX in part names
                    [~,filename2,~] = fileparts(clean_obj.clean('parts', refmodeldecoded.components(tmp{i}),'.'));
                    refmodeldecoded.components(tmp{i}) = [filename2 '.txt'];
                end
                
                if ~isempty(self.AddVersionToFileNames)
                    % Add _rXX to part names
                    tmp = refmodeldecoded.components.keys;
                    for i=1:length(tmp)
                        partfile = self.AddVersionToFileNames.getFiles(tmp{i});
                        [~,partfilename, partfileext] = fileparts(partfile.name);
                        refmodeldecoded.components(tmp{i}) = [partfilename '_r' partfile.version '_' partfile.minorversion partfileext];
                    end
                    
                    NameErrorFile = self.AddVersionToFileNames.getFiles('ERR');
                    [tmpfolder, tmpname, tmpext] = fileparts(refmodeldecoded.NameErrorFile);
                    refmodeldecoded.NameErrorFile = [tmpfolder '\' tmpname '_r' NameErrorFile.version '_' NameErrorFile.minorversion tmpext];
                end
                
                % Remove "Exported from" 
                tmp = regexp(refmodeldecoded.Header,'(Exported from','split');
                refmodeldecoded.Header = strtrim(tmp{1});
                
                if ~isempty(self.ExportedFrom)
                    % Add "Exported from"
                    refmodeldecoded.Header = [refmodeldecoded.Header ' (Exported from ' self.ExportedFrom ')'];
                end
                
                %if ~isequal(refmodeldecodedoriginal,refmodeldecoded)
                    % Encode refmodel
                    [FID, status] = fopen(tmpfile,'wt');
                    if isempty(status)
                        coder_refmodel.encode(FID, refmodeldecoded);
                        fclose(FID);
                    end
                %end
                
                % Trim white space
                self.trimWhiteSpace(tmpfile);
            end
        end
        
        function tmpfile = searchAndReplacePathsInPart(self, filename, parttype)
            tmpfile = tempname;
            if ~strcmp(filename, tmpfile)
                if exist(filename, 'file') ~= 0
                    copyfile(filename, tmpfile, 'f');
                    fileattrib(tmpfile,'+w');
                end
            end
            
            coder_part = eval(['codec.Part_' upper(parttype) '();']);
            
            FID = lib.safefopen(tmpfile);
            if FID > 0
                partdecoded = coder_part.decode(FID);
                partdecodedoriginal = partdecoded;
                fclose(FID);
                
                % Clean profiles and parameters folders
                switch parttype
                    case 'BLD'
                        clean_obj = codec.CleanFileName();
                        for i=1:length(partdecoded.AuxDLL)
                            if ~isempty(self.NewFileNames)
                                % Correct part file name, if existing file found
                                existingprofiledata = self.NewFileNames(find(strcmpi({self.NewFileNames.Type},partdecoded.AuxDLL{i}.Type),1));
                                if ~strcmpi(existingprofiledata.MD5HashFileName,'None')
                                    [~, tmpa, tmpb] = fileparts(existingprofiledata.MD5HashFileName);
                                    partdecoded.AuxDLL{i}.FileName = [self.ProfilesFolder tmpa tmpb];
                                end
                            end
                            [~,tmpfilename,ext] = fileparts(clean_obj.clean('profiles',partdecoded.AuxDLL{i}.FileName,'.'));
                            partdecoded.AuxDLL{i}.FileName = [self.ProfilesFolder tmpfilename ext];
                        end
                    case 'CTR'
                        clean_obj = codec.CleanFileName();
                        for i=1:length(partdecoded.AuxDLL)
                            if ~isempty(self.NewFileNames)
                                % Correct part file name, if existing file found
                                existingparameterdata = self.NewFileNames(find(strcmpi({self.NewFileNames.Type},partdecoded.AuxDLL{i}.Type),1));
                                if ~strcmpi(existingparameterdata.MD5HashFileName,'None')
                                    [~, tmpa, tmpb] = fileparts(existingparameterdata.MD5HashFileName);
                                    partdecoded.AuxDLL{i}.FileName = [self.ProfilesFolder tmpa tmpb];
                                end
                            end
                            [~,tmpfilename,ext] = fileparts(clean_obj.clean('parameters',partdecoded.AuxDLL{i}.FileName,'.'));
                            partdecoded.AuxDLL{i}.FileName = [self.ParametersFolder tmpfilename ext];
                        end
                end
                
                if isfield(partdecoded,'AuxDLL')
                    if ~isempty(self.AddVersionToFileNames)
                        % Add _rXX to AuxDLL file names
                        for i=1:length(partdecoded.AuxDLL)
                            thefile = self.AddVersionToFileNames.getFiles(partdecoded.AuxDLL{i}.Type);
                            [folder,thefilename, thefileext] = fileparts(partdecoded.AuxDLL{i}.FileName);
                            if strcmpi(parttype,'CTR')
                                % Must not add version number to CTR, parameters must not have version+minorversion in filename
                                % Needed for backwards compability in VTS and prep
                                partdecoded.AuxDLL{i}.FileName = [folder '\' thefilename thefileext];
                                % BUGFIX: Other controllers than PitchControler starts with 'PitchCtrl_'. Prevents VTS from running
                                if isempty(regexpi(partdecoded.AuxDLL{i}.Type, '^PitchController','match'))
                                    partdecoded.AuxDLL{i}.FileName = regexprep(partdecoded.AuxDLL{i}.FileName, 'PitchCtrl_','');
                                end
                            else
                                partdecoded.AuxDLL{i}.FileName = [folder '\' thefilename '_r' thefile.version '_' thefile.minorversion thefileext];
                            end
                        end
                    end
                end
                
                % Remove "Exported from" 
                tmp = regexp(partdecoded.Header,'(Exported from','split');
                partdecoded.Header = strtrim(tmp{1});
                
                switch parttype
                    case '_PL'
                        % WORKAROUND: Needed for backwards compability with IntPostD. Store "Exported from" in second line.
                        % Remove "Exported from" from second line of _PL part
                        tmp = regexp(partdecoded.RemainingLines{1}{1},'(Exported from','split');
                        partdecoded.RemainingLines{1}{1} = strtrim(tmp{1});
                if ~isempty(self.ExportedFrom)
                    % Add "Exported from"
                            partdecoded.RemainingLines{1}{1} = [partdecoded.RemainingLines{1}{1} ' (Exported from ' self.ExportedFrom ')'];
                        end
                    otherwise
                        if ~isempty(self.ExportedFrom)
                            % Add "Exported from"
                    partdecoded.Header = [partdecoded.Header ' (Exported from ' self.ExportedFrom ')'];
                        end
                end
                
                %if ~isequal(partdecodedoriginal, partdecoded)
                    [FID, writestatus] = fopen(tmpfile,'wt');
                    if isempty(writestatus)
                        coder_part.encode(FID, partdecoded);
                        fclose(FID);
                    end
                %end
                
                % Trim white space
                self.trimWhiteSpace(tmpfile);
            end
        end
        
        function tmpfile = searchAndReplacePathsInProfile(self, filename)
            tmpfile = tempname;
            if ~strcmp(filename, tmpfile)
                if exist(filename, 'file') ~= 0
                    copyfile(filename, tmpfile, 'f');
                    fileattrib(tmpfile,'+w');
                end
            end
            
            FID = lib.safefopen(tmpfile);
            if FID>0
                filecontents = textscan(FID, '%s', -1, 'whitespace', '', 'delimiter', '\n');
                fclose(FID);
            
                % Remove "Exported from" 
                tmp = regexp(filecontents{1}(1),'(Exported from','split');
                filecontents{1}{1} = strtrim(tmp{1}{1});
                
                if ~isempty(self.ExportedFrom)
                    % Add "Exported from"
                    filecontents{1}{1} = [filecontents{1}{1} ' (Exported from ' self.ExportedFrom ')'];
                end
                
                % Trim whitespace at end of file
                filecontents = {deblank(filecontents{:})};
                while ~isempty(filecontents{1}) && isempty(filecontents{1}{end})
                    filecontents{1}(end) = [];
                end
                
                fileattrib(tmpfile,'+w');
                [FID, status] = fopen(tmpfile, 'wt'); % use 'wt' to get \r\n
                if isempty(status)
                    tmp = filecontents{1};
                    fprintf(FID, '%s\n', tmp{:});
                    fclose(FID);
                end
            end
        end
        
        function tmpfile = searchAndReplacePathsInParameter(self, filename)
            tmpfile = tempname;
            if ~strcmp(filename, tmpfile)
                if exist(filename, 'file') ~= 0
                    copyfile(filename, tmpfile, 'f');
                    fileattrib(tmpfile,'+w');
                end
            end
        end
        
        function refmodeldecoded = correctErrorNameFile(~, refmodeldecoded)
            % Workaround to make VRMM able to find error name file on "Save".
            % This is the case, if the existing refmodel file referes to non-exsitng file error name file.
            
            if ~exist(refmodeldecoded.NameErrorFile, 'file')
                [myfolder, myfilename, ext]  = fileparts(refmodeldecoded.NameErrorFile);
                errornamefile_corrected = fullfile(myfolder,'ERR',myfilename,ext);
                if exist(errornamefile_corrected, 'file')
                    index = find(strcmpi(refmodeldecoded.Type,'ERR'),1);
                    refmodeldecoded.parts{index} = errornamefile_corrected;
                end
            end
        end
        
        function trimWhiteSpace(~, filename)
            FID = lib.safefopen(filename);
            if FID>0
                text = textscan(FID, '%s', -1, 'whitespace', '', 'delimiter', '\n');
                fclose(FID);
                
                % remove trailing whitespaces
                % NOTICE!! Do not remove leading whitespaces
                text = {deblank(text{:})};
                
                % Remove empty lines at end of file
                while ~isempty(text{1}) && isempty(text{1}{end})
                    text{1}(end) = [];
                end
                
                [FID, status] = fopen(filename,'wt');
                if isempty(status)
                    fprintf(FID, '%s\n', text{1}{:});
                    fclose(FID);
                end
            end          
        end        
    end
end