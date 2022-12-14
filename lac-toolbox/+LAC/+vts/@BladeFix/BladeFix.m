classdef BladeFix < handle
    %BladeFix A tool to take you through the blade file related part of the blade iteration process.
    % see guideline on http://wiki.tsw.vestas.net/x/DYIYCw
    %
    % Syntax:
    %   Automatic mode- BladeFix.Run(inputFile)
    %   Manual mode - bladeFix = BladeFix(inputFile)
    %
    %--- Automatic mode- BladeFix.Run(inputFile) ---
    %    inputFile - A .txt input file which keeps the information needed
    %    to run the BladeFix tool. Look at DMS 0080-7307 for instructions.
    %
    % --- Manual mode - bladeFix = BladeFix(inputStruct) ---
    % Required constructor inputs:
    %    inputStruct - A struct with char arrays with at least the following
    %    information:
    %       BLDFileName:   Name of the new blade file
    %       BLDTemplate:   Name of the blade file template to be used (a
    %                      full path)
    %       FlexExportCSV: Name of the FlexExport .csv fileto be used (a
    %                      full path)
    %       PrepFile:      Name of the PrepFile to be used for twist correction
    %                      (a full path)
    %       AeroInpFile:   Name of the Pyro .inp file to be used as target
    %                      hot twist (a full path)
    %
    %  Methods on BladeFix which may be called in manual mode:
    %    BLD_1_WriteNewBLDFile() - Writes the new BLD file with all the
    %    necessary corrections.
    %    BLD_2a_SetupColdTwistIteration() - Sets up a VTS simulation to
    %    determine the hot twist using the current BLD file. It is possible
    %    run it directly from the method.
    %    BLD_2b_CheckColdTwist() - Checks the difference between the VTS hot
    %    twist and the perfect twist defined in the PyRo .inp file.
    %    BLD_3_CompareBLD() - Compares the properties with the previous blade
    %    if such a blade exist.
    %    BLD_4_runPyro() - Runs the .inp Pyro file in order to get Cp/Ct tables
    %    for the CtrlInput update.
    %
    
    properties
        pyroVersion = 'w:\SOURCE\pyro.bat'
    end
    
    properties (SetAccess = private, GetAccess = public)
        inputs=struct('BLDFileName',[],'BLDTemplate',[],'FlexExportCSV',[],'PrepFile',[],'AeroInpFile',[],'tags',{},'specialTags',{})
        newBLDfile
        newBLDfileExtended
        twistSimulationFolder
        finalBladeReached = false;
        twistIteration = 0;
        finalFolder
        
    end
    
    methods (Access = public)
        function self = BladeFix(inputStruct)
            self.inputs = inputStruct;
            self.checkInputs();

            % create final results folder
            self.finalFolder = fullfile(self.inputs.OutputFolder,'FinalResult');
            if ~isdir(self.finalFolder)
                mkdir(self.finalFolder);
            end
        end
        
        BLD_1_WriteNewBLDFile(self)
        BLD_2a_SetupColdTwistIteration(self)
        acceptableTwist = BLD_2b_CheckColdTwist(self)
        BLD_3_CompareBLD(self)
        BLD_4_runPyro(self)
    end
    
    methods (Static)
        function Run(inputFile)
            % Run(inputFile) Automatic run of BladeFix process.
            % Takes you through the blade file related part of the
            % blade iteration process (DMS 0080-7307). This includes:
            %
            % 1. Creating the BLD file.
            %    Incl. all the necessary corrections, such as shear center,
            %    root edgewise coning sweep, pitch offsets, torsional stiffness
            %    correction factors.
            % 2. Running an iteratative process of correcting the cold twist of the
            %    blade to match the hot twist defined in the Pyro .inp file at
            %    the defined hot twist wind speed (7.5 m/s is default).
            % 3. Comparing the final blade properties with the previous blade if
            %    such a blade exists.
            % 4. Running the pyro .inp file to get the .out file required for
            %    controller updates of to the Cp/Ct tables.
            %
            % Inputs:
            %    inputFile - A .txt input file which keeps the information needed
            %    to run the BladeFix tool. Look at DMS 0080-7307 for instructions.
            %
            inputStruct = LAC.vts.BladeFix.readBladeFixInputFile(inputFile);
            self = LAC.vts.BladeFix(inputStruct);
            BLD_1_WriteNewBLDFile(self)
            
            coldTwistIteration = true;
            
            while coldTwistIteration
                answer = questdlg(sprintf('Run VTS simulation for cold twist iteration number %0.0f',self.twistIteration),'Run iteration','Yes','No','Yes');
                switch answer
                    case 'Yes'
                        fprintf('Running simulation \n');
                        self.BLD_2a_SetupColdTwistIteration()                        
                    otherwise
                        break
                end
                acceptableTwist = self.BLD_2b_CheckColdTwist();
                coldTwistIteration = ~acceptableTwist;
            end
            
            answer = questdlg('Compare blade with previous BLD?','Compare BLD','Yes','No','Yes');
            switch answer
                case 'Yes'
                    self.BLD_3_CompareBLD()
            end
            self.BLD_4_runPyro()
            
        end
    end
    
    methods (Access = private)
        
        function checkInputs(self)
            % checkInputs checks the required inputs given in the input file.
            requiredFields = {'BLDFileName','BLDFileNameExtended','BLDTemplate','OutputFolder',...
                'RotorDiameter','FlexExportCSV','PreviousBlade','PrepFile','HotTwistWindSpeed',...
                'AeroInpFile','TwistCorrectionFromRadii','TwistCriterionDeg','OutputSensors','PhiOutLimit','OTCfile','ShearCenterCorrection'};
            
            for i = 1:length(requiredFields)
                switch requiredFields{i}
                    case 'OutputFolder'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.OutputFolder = pwd;
                        elseif ~(exist(self.inputs.OutputFolder,'dir')==7)
                            mkdir(self.inputs.OutputFolder)
                        end
                    case 'OutputSensors'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.OutputSensors = 'Standard output';
                        else 
                            self.inputs.OutputSensors = self.inputs.OutputSensors;
                            assert(ismember(self.inputs.OutputSensors,{'Same as input BLD','Only 0','Standard output','Extended output','FlexExport and vts'}),...
                                'OutputSensors should be one of these: ''Same as input BLD'',''Only 0'',''Standard output'',''Extended output'',''FlexExport and vts''')
                        end
                    case 'HotTwistWindSpeed'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.HotTwistWindSpeed = 7.5;
                        else
                            self.inputs.HotTwistWindSpeed = str2double(self.inputs.HotTwistWindSpeed);
                            validateattributes(self.inputs.HotTwistWindSpeed,{'numeric'},{'scalar','finite','positive'})
                        end
                    case {'BLDTemplate','FlexExportCSV','PrepFile','AeroInpFile'}
                        if isempty(self.inputs.(requiredFields{i}))
                            error('%s does not exist in inputStruct',requiredFields{i})
                        else
                            assert(exist(self.inputs.(requiredFields{i}),'file')==2,'%s %s does not exist.',requiredFields{i},self.inputs.(requiredFields{i}))
                        end
                    case 'BLDFileName'
                        assert(~isempty(self.inputs.(requiredFields{i})),'%s does not exist in inputStruct',requiredFields{i});
                        validateattributes(self.inputs.BLDFileName,{'char'},{'row'})
                        [pathstr,~,ext] = fileparts(self.inputs.BLDFileName);
                        assert(isempty(pathstr),'''BLDFileName'' should not include the path');
                        assert(~isempty(ext),'''BLDFileName'' should include an extension like e.g. ''.001''');
                        assert(~isempty(regexp(ext,'^\.\d\d\d$', 'once')) && regexp(ext,'^\.\d\d\d$')==1,'''BLDFileName'' should include an extension with the usual part file numeric format like ''.001''.');

                    case 'RotorDiameter'
                        if ~isfield(self.inputs,requiredFields{i})
                            objFlxExp = LAC.vts.convert(self.inputs.FlexExportCSV,'BLD_FLXEXP');
                            self.inputs.RotorDiameter = objFlxExp.SectionTable.R(end)*2;
                        elseif ischar(self.inputs.RotorDiameter)
                            self.inputs.RotorDiameter = str2double(self.inputs.RotorDiameter);
                        end
                    case 'PreviousBlade'
                        if ~isfield(self.inputs,requiredFields{i})
                            try
                                self.inputs.PreviousBlade = self.inputs.specialTags.CommentsFromPreviousBlade;
                            catch
                                self.inputs.PreviousBlade = '';
                            end
                        else
                            assert(exist(self.inputs.PreviousBlade,'file')==2,'checkInputs:AssertError','PreviousBlade %s does not exist.',self.inputs.PreviousBlade);
                        end
                    case 'TwistCorrectionFromRadii'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.TwistCorrectionFromRadii = 0;
                        elseif ischar(self.inputs.TwistCorrectionFromRadii)
                            self.inputs.TwistCorrectionFromRadii = str2double(self.inputs.TwistCorrectionFromRadii);
                        end
                    case 'TwistCriterionDeg'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.TwistCriterionDeg = 0.1;
                        elseif ischar(self.inputs.TwistCriterionDeg)
                            self.inputs.TwistCriterionDeg = str2double(self.inputs.TwistCriterionDeg);
                        end

                        if self.inputs.TwistCriterionDeg ~= 0.1
                            warning('backtrace','off')
                            warning('Twist criterion is set to %1.2f deg. This is different from the suggested 0.10 deg in the blade iteration guideline DMS 0080-7307.',self.inputs.TwistCriterionDeg)
                            warning('backtrace','on')
                        end
                     case 'PhiOutLimit'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.PhiOutLimit = 1000;
                        else 
                            self.inputs.PhiOutLimit = str2double(self.inputs.PhiOutLimit);
                        end
                    case 'OTCfile'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.OTCfile = '';
                        else 
                            self.inputs.OTCfile = self.inputs.OTCfile;
                        end
                    case 'ShearCenterCorrection'
                        if ~isfield(self.inputs,requiredFields{i})
                            self.inputs.ShearCenterCorrection = '';
                        else 
                            self.inputs.ShearCenterCorrection = self.inputs.ShearCenterCorrection;
                        end
                end
            end
            [~,fileName,extension]=fileparts(self.inputs.BLDFileName);
            self.inputs.BLDFileNameExtended = [fileName,'_extended',extension];
        end
        
    end
    methods (Static)
        
        function testResults = runUnitTests()
            
            import matlab.unittest.TestRunner
            suite = testsuite('LAC.vts.tests.BladeFixTest');
            runner = TestRunner.withTextOutput('Verbosity',3);
            results = runner.run(suite);
            testResults = table(results);
        end
        
        function PyroInput = ConvertPyroInput(INPfile)
            % ConvertPyroInput reads the Radius Chord Twist Thickness table in the .inp file.
            file = LAC.codec.CodecTXT(INPfile);
            data = file.getData();
            lineNumber = find(contains(data,'Radius') & contains(data,'Chord') & contains(data,'Twist') & contains(data,'Thickness'));
            parameters = strsplit_LMT(strtrim(data{lineNumber}));
            lineNumber = lineNumber+1;
            
            matrix = [];
            while ~strcmp(strtrim(data{lineNumber}),'')
                line = strsplit_LMT(strtrim(data{lineNumber}));
                new_line = str2double(line);
                    if isnan(new_line(1))
                        break;
                    else
                        matrix(end+1,:) = new_line;
                    end
               lineNumber = lineNumber+1;
            end
            
            PyroInput.parameters = parameters;
            PyroInput.matrix = matrix;
        end
        
        function inputStruct = readBladeFixInputFile(inputFile)
            % readBladeFixInputFile reads the input .txt file which has the format as specified in DMS 0080-7307.
            
            file = LAC.codec.CodecTXT(inputFile);
            data = file.getData;
            
            % * * tags
            blockStart = find(~cellfun(@isempty,regexp(data,'^\*\*(?!/)')));
            blockEnd = find(~cellfun(@isempty,regexp(data,'^\*\*/')));
            dataBlock = data(blockStart+1:blockEnd-1);
            tagLines = find(~cellfun(@isempty,regexp(dataBlock,'\*\w+\*')));
            for i = 1:length(tagLines)
                tagName = cell2mat(regexp(dataBlock{tagLines(i)},'\*\w+\*','match'));
                tagEnd = regexp(dataBlock{tagLines(i)},'\*\w+\*','end');
                comments = regexp(dataBlock{tagLines(i)},'%', 'once');
                if ~isempty(comments)
                    remainingLine = dataBlock{tagLines(i)}(tagEnd+1:comments-1);
                else
                    remainingLine = dataBlock{tagLines(i)}(tagEnd+1:end);
                end
                inputStruct.(tagName(2:end-1)) = strtrim(remainingLine);
            end
            
            % < > tags
            blockStart = find(~cellfun(@isempty,regexp(data,'^<<(?!/)')));
            blockEnd = find(~cellfun(@isempty,regexp(data,'^<</')));
            dataBlock = data(blockStart+1:blockEnd-1);
            tagLinesStart = find(~cellfun(@isempty,regexp(dataBlock,'<\w+>')));
            tagLinesEnd = find(~cellfun(@isempty,regexp(dataBlock,'</\w+>')));
            for i = 1:length(tagLinesStart)
                tagName = cell2mat(regexp(dataBlock{tagLinesStart(i)},'<\w+>','match'));
                if tagLinesStart(i) == tagLinesEnd(i)
                    startID = regexp(dataBlock{tagLinesStart(i)},'<\w+>','end')+1;
                    endID = regexp(dataBlock{tagLinesEnd(i)},'</\w+>','start')-1;
                    inputStruct.tags.(tagName(2:end-1)) = {dataBlock{tagLinesStart(i)}(startID:endID)};
                else
                    startID = regexp(dataBlock{tagLinesStart(i)},'<\w+>','end')+1;
                    endID = regexp(dataBlock{tagLinesEnd(i)},'</\w+>','start')-1;
                    inputStruct.tags.(tagName(2:end-1)) = [{dataBlock{tagLinesStart(i)}(startID:end)}; {dataBlock{tagLinesStart(i)+1:tagLinesEnd(i)-1}}; {dataBlock{tagLinesEnd(i)}(1:endID)}];
                end
                
                if any(~cellfun(@isempty,regexp(inputStruct.tags.(tagName(2:end-1)),'\*\w+\*')))
                    startID = regexp(inputStruct.tags.(tagName(2:end-1)),'\*\w+\*','start');
                    endID = regexp(inputStruct.tags.(tagName(2:end-1)),'\*\w+\*','end');
                    for j = 1:length(startID)
                        if ~isempty(startID{j})
                            inputStruct.tags.(tagName(2:end-1)){j} = [inputStruct.tags.(tagName(2:end-1)){j}(1:startID{j}-1) ...
                                inputStruct.(inputStruct.tags.(tagName(2:end-1)){j}(startID{j}+1:endID{j}-1)) ...
                                inputStruct.tags.(tagName(2:end-1)){j}(endID{j}+1:end)];
                        end
                    end
                end
                
            end
            
            % [ ] tags
            blockStart = find(~cellfun(@isempty,regexp(data,'^\[\[(?!/)')));
            blockEnd = find(~cellfun(@isempty,regexp(data,'^\[\[/')));
            dataBlock = data(blockStart+1:blockEnd-1);
            tagLinesStart = find(~cellfun(@isempty,regexp(dataBlock,'\[\w+\]')));
            tagLinesEnd = find(~cellfun(@isempty,regexp(dataBlock,'\[/\w+\]')));
            for i = 1:length(tagLinesStart)
                tagName = cell2mat(regexp(dataBlock{tagLinesStart(i)},'\[\w+\]','match'));
                if tagLinesStart(i) == tagLinesEnd(i)
                    startID = regexp(dataBlock{tagLinesStart(i)},'\[\w+\]','end')+1;
                    endID = regexp(dataBlock{tagLinesEnd(i)},'\[/\w+\]','start')-1;
                    inputStruct.specialTags.(tagName(2:end-1)) = strsplit_LMT(strtrim(dataBlock{tagLinesStart(i)}(startID:endID)),' ');
                else
                    startID = regexp(dataBlock{tagLinesStart(i)},'\[\w+\]','end')+1;
                    endID = regexp(dataBlock{tagLinesEnd(i)},'\[/\w+\]','start')-1;
                    for j = tagLinesStart(i):tagLinesEnd(i)
                        if j==tagLinesStart(i)
                            if ~isempty(strtrim(dataBlock{j}(startID:end)))
                                inputStruct.specialTags.(tagName(2:end-1)) = strsplit_LMT(strtrim(dataBlock{j}(startID:end)),' ');
                            else
                                inputStruct.specialTags.(tagName(2:end-1)) =[];
                            end
                        elseif j>tagLinesStart(i) && j<tagLinesEnd(i)
                            inputStruct.specialTags.(tagName(2:end-1)) = [inputStruct.specialTags.(tagName(2:end-1)) ; strsplit_LMT(strtrim(dataBlock{j}),' ')];
                        else
                            if ~isempty(strtrim(dataBlock{j}(1:endID)))
                                inputStruct.specialTags.(tagName(2:end-1)) = [inputStruct.specialTags.(tagName(2:end-1)) ; strsplit_LMT(strtrim(dataBlock{j}(1:endID)),' ')];
                            end
                        end
                    end
                end
                
                if any(reshape(~cellfun(@isempty,regexp(inputStruct.specialTags.(tagName(2:end-1)),'\*\w+\*')),[],1))
                    startID = regexp(inputStruct.specialTags.(tagName(2:end-1)),'\*\w+\*','start');
                    endID = regexp(inputStruct.specialTags.(tagName(2:end-1)),'\*\w+\*','end');
                    for j = 1:numel(startID)
                        if ~isempty(startID{j})
                            inputStruct.specialTags.(tagName(2:end-1)){j} = [inputStruct.specialTags.(tagName(2:end-1)){j}(1:startID{j}-1) ...
                                inputStruct.(inputStruct.specialTags.(tagName(2:end-1)){j}(startID{j}+1:endID{j}-1)) ...
                                inputStruct.specialTags.(tagName(2:end-1)){j}(endID{j}+1:end)];
                        end
                    end
                end
                
            end
            
        end
        
        function newFileContent = insertTagsInTemplate(filePath,inputs)
            % insertTagsInTemplate insert the tags in the template file
            file = LAC.codec.CodecTXT(filePath);
            fileContent = file.getData;
            
            lineNumber=1;
            while lineNumber <= size(fileContent,1)
                currentLine = fileContent{lineNumber};
                
                if ~isempty(regexp(currentLine,'<\w+>'))
                    tagNames = regexp(currentLine,'<\w+>','match');
                    startIDs = regexp(currentLine,'<\w+>','start');
                    endIDs = regexp(currentLine,'<\w+>','end');
                    while ~isempty(tagNames)
                            tagName = tagNames{1}(2:end-1);
                            for i = 1:size(inputs.tags.(tagName),1)
                                charArray = inputs.tags.(tagName){i};
                                if i == 1
                                    fileContent{lineNumber} = [fileContent{lineNumber}(1:startIDs(1)-1) charArray fileContent{lineNumber}(endIDs(1)+1:end)];
                                else
                                    fileContent = [fileContent(1:lineNumber); charArray; fileContent(lineNumber+1:end)];
                                    lineNumber = lineNumber + 1;
                                end
                            end
                        currentLine = fileContent{lineNumber};
                        tagNames = regexp(currentLine,'<\w+>','match');
                        startIDs = regexp(currentLine,'<\w+>','start');
                        endIDs = regexp(currentLine,'<\w+>','end');
                    end
                elseif ~isempty(regexp(currentLine,'\[\w+\]'))
                    tagName = cell2mat(regexp(currentLine,'\[\w+\]','match'));
                    switch tagName
                        case '[ProfileDataSets]'
                            profiles = inputs.specialTags.(tagName(2:end-1));
                            
                            for i = 1:size(profiles,1)
                                if i == 1
                                    fileContent{lineNumber} = sprintf('%0.0f%90s',size(profiles,1),'Number of profile data sets');
                                end
                                fileContent = [fileContent(1:lineNumber); sprintf('%s %s',profiles{i,1},profiles{i,2}) ; fileContent(lineNumber+1:end)];
                                lineNumber = lineNumber + 1;
                                
                            end
                        case '[NoiseEquations]'
                            % Add noise parameters.
                            nequations = size(inputs.specialTags.(tagName(2:end-1)),1);
                            noiseEquations = {};
                            noiseEquations{end+1,1} = sprintf('%3d%60s%s', nequations, ' ', 'Number of noise equations');
                            
                            for iNoise=1:nequations
                                
                                % Read.
                                csv_reader_noise = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
                                csv_reader_noise.ReadFile(inputs.specialTags.(tagName(2:end-1)){iNoise,2});
                                % Set parameters.
                                NoiseEquationVersion = csv_reader_noise.get_value_by_name('NoiseEquationVersion');
                                NoiseEquationName = csv_reader_noise.LineItems(1,2).Comments;
                                nradi= csv_reader_noise.get_value_by_name('Number of radii (one per line)');
                                Radius = csv_reader_noise.get_value_by_name('Radius[%]');
                                A1 = csv_reader_noise.get_value_by_name('A1');
                                A2 = csv_reader_noise.get_value_by_name('A2');
                                AoASwitch = csv_reader_noise.get_value_by_name('AoASwitch[deg]');
                                B1 = csv_reader_noise.get_value_by_name('B1');
                                Cmodified1 = csv_reader_noise.get_value_by_name('Cmodified1');
                                Cconst1 = csv_reader_noise.get_value_by_name('Cconst1');
                                D1 = csv_reader_noise.get_value_by_name('D1');
                                Dref1 = csv_reader_noise.get_value_by_name('Dref1');
                                B2 = csv_reader_noise.get_value_by_name('B2');
                                Cmodified2 = csv_reader_noise.get_value_by_name('Cmodified2');
                                Cconst2 = csv_reader_noise.get_value_by_name('Cconst2');
                                D2 = csv_reader_noise.get_value_by_name('D2');
                                Dref2 = csv_reader_noise.get_value_by_name('Dref2');
                                %
                                noiseEquations{end+1,1} = sprintf(inputs.specialTags.(tagName(2:end-1)){iNoise,1});
                                %                     commentString{end+1} = sprintf('%s', NoiseEquationName);
                                noiseEquations{end+1,1} = sprintf('%s%3d', '  NoiseEquationVersion', NoiseEquationVersion);
                                noiseEquations{end+1,1} = sprintf('%3d%77s%s', nradi, ' ', 'Number of radii (one per line)');
                                noiseEquations{end+1,1} = sprintf('%7.2f%7.2f%7.2f%7.2f%52s%s', Radius, A1, A2, AoASwitch, ' ', 'Radius[%] A1 A2 AoASwitch[deg]');
                                noiseEquations{end+1,1} = sprintf('%7.2f%7.2f%7.2f%7.2f%7.2f%7.2f%7.2f%7.2f%7.2f%7.2f%10s%s', B1, Cmodified1, Cconst1, D1, Dref1, B2, Cmodified2, Cconst2, D2, Dref2, ' ', 'B1 Cmodified1 Cconst1 D1 Dref1 B2 Cmodified2 Cconst2 D2 Dref2');
                            end
                            
                            for i = 1:size(noiseEquations,1)
                                if i == 1
                                    fileContent{lineNumber} = noiseEquations{i};
                                else
                                    fileContent = [fileContent(1:lineNumber); noiseEquations(i) ; fileContent(lineNumber+1:end)];
                                    lineNumber = lineNumber + 1;
                                end
                            end
                            
                        case '[CommentsFromPreviousBlade]'
                            previousBLD = LAC.vts.convert(inputs.specialTags.CommentsFromPreviousBlade{1},'BLD');
                            comments = previousBLD.comments();
                            
                            if ~isempty(comments)
                                for i = 1:size(comments,1)
                                    if i == 1
                                        fileContent{lineNumber} = comments{i};
                                    else
                                        fileContent = [fileContent(1:lineNumber); comments(i) ; fileContent(lineNumber+1:end)];
                                        lineNumber = lineNumber + 1;
                                    end
                                end
                            else
                                fileContent{lineNumber} = '';
                            end
                            
                        otherwise
                            
                    end
                end
                lineNumber = lineNumber+1;
            end
            newFileContent = fileContent;
        end
        
    end
end


