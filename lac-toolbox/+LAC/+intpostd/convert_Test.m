classdef convert_Test < matlab.unittest.TestCase
    properties (Constant)
        testFolder = '\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\LMT-7840\testPartFiles\'
        file2codec = containers.Map({'DRT\DRTload.txt' 'EXT\Abs\*.xdo' 'EXT\Max\*.xpo' 'EXT\Min\*.xno' 'FND\FNDload.txt' 'LDD\*.ldd' 'MAIN\MainLoad.txt' 'MAIN\MainLoad.txt' 'MARKOV\*.mko' 'HUB\PITload.txt' 'RAIN\*.rfo' 'EXT\Sta\*.sst' 'TWR\TWRLoad.txt' 'User\Loads\USERload.txt'},...
            {'DRT' 'EXT' 'EXT' 'EXT' 'FND' 'LDD' 'MAIN' 'MAIN_v01' 'MKO' 'PIT' 'RFO' 'SST' 'TWR' 'USER'});
    end
    properties
        encode     = containers.Map({'DRT' 'EXT' 'FND' 'LDD' 'MAIN' 'MAIN_v01' 'MKO' 'PIT' 'RFO' 'SST' 'TWR' 'TWR_OFF' 'USER'},...
            {false,false,false,false,true,false,false,false,false,false,false,false,false});
        autoDectect =containers.Map({'DRT' 'EXT' 'FND' 'LDD' 'MAIN' 'MAIN_v01' 'MKO' 'PIT' 'RFO' 'SST' 'TWR' 'TWR_OFF' 'USER'},...
            {true,false,true,true,true,true,true,false,true,true,true,true,false});
        compileError = containers.Map
        skipFiles = {};
        
        skipEncode = {};
    end
    
    properties (TestParameter)
        files = {'2MW_1\Loads\Postloads\DRT\DRTload.txt'
            '2MW_1\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            '2MW_1\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            '2MW_1\Loads\Postloads\EXT\Min\0018_Omega.xno'
            '2MW_1\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            '2MW_1\Loads\Postloads\FND\FNDload.txt'
            '2MW_1\Loads\Postloads\HUB\PITload.txt'
            '2MW_1\Loads\Postloads\LDD\0018_Omega.ldd'
            '2MW_1\Loads\Postloads\MAIN\MainLoad.txt'
            '2MW_1\Loads\Postloads\MARKOV\0018_Omega.mko'
            '2MW_1\Loads\Postloads\RAIN\0018_Omega.rfo'
            '2MW_1\Loads\Postloads\TWR\TWRLoad.txt'
            '2MW_1\Loads\Postloads\User\Loads\USERload.txt'
            '2MW_2\Loads\Postloads\DRT\DRTload.txt'
            '2MW_2\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            '2MW_2\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            '2MW_2\Loads\Postloads\EXT\Min\0018_Omega.xno'
            '2MW_2\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            '2MW_2\Loads\Postloads\FND\FNDload.txt'
            '2MW_2\Loads\Postloads\HUB\PITload.txt'
            '2MW_2\Loads\Postloads\LDD\0018_Omega.ldd'
            '2MW_2\Loads\Postloads\MAIN\MainLoad.txt'
            '2MW_2\Loads\Postloads\MARKOV\0018_Omega.mko'
            '2MW_2\Loads\Postloads\RAIN\0018_Omega.rfo'
            '2MW_2\Loads\Postloads\TWR\TWRLoad.txt'
            '2MW_2\Loads\Postloads\User\Loads\USERload.txt'
            '3MW_4MW\Loads\Postloads\DRT\DRTload.txt'
            '3MW_4MW\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            '3MW_4MW\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            '3MW_4MW\Loads\Postloads\EXT\Min\0018_Omega.xno'
            '3MW_4MW\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            '3MW_4MW\Loads\Postloads\FND\FNDload.txt'
            '3MW_4MW\Loads\Postloads\HUB\PITload.txt'
            '3MW_4MW\Loads\Postloads\LDD\0018_Omega.ldd'
            '3MW_4MW\Loads\Postloads\MAIN\MainLoad.txt'
            '3MW_4MW\Loads\Postloads\MARKOV\0018_Omega.mko'
            '3MW_4MW\Loads\Postloads\RAIN\0018_Omega.rfo'
            '3MW_4MW\Loads\Postloads\TWR\TWRLoad.txt'
            '3MW_4MW\Loads\Postloads\User\Loads\USERload.txt'
            'Enventus\Loads\Postloads\DRT\DRTload.txt'
            'Enventus\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            'Enventus\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            'Enventus\Loads\Postloads\EXT\Min\0018_Omega.xno'
            'Enventus\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            'Enventus\Loads\Postloads\FND\FNDload.txt'
            'Enventus\Loads\Postloads\HUB\PITload.txt'
            'Enventus\Loads\Postloads\LDD\0018_Omega.ldd'
            'Enventus\Loads\Postloads\MAIN\MainLoad.txt'
            'Enventus\Loads\Postloads\MARKOV\0018_Omega.mko'
            'Enventus\Loads\Postloads\RAIN\0018_Omega.rfo'
            'Enventus\Loads\Postloads\TWR\TWRLoad.txt'
            'Enventus\Loads\Postloads\User\Loads\USERload.txt'
            'Localisation\Loads\Postloads\DRT\DRTload.txt'
            'Localisation\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            'Localisation\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            'Localisation\Loads\Postloads\EXT\Min\0018_Omega.xno'
            'Localisation\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            'Localisation\Loads\Postloads\FND\FNDload.txt'
            'Localisation\Loads\Postloads\HUB\PITload.txt'
            'Localisation\Loads\Postloads\LDD\0018_Omega.ldd'
            'Localisation\Loads\Postloads\MAIN\MainLoad.txt'
            'Localisation\Loads\Postloads\MARKOV\0018_Omega.mko'
            'Localisation\Loads\Postloads\RAIN\0018_Omega.rfo'
            'Localisation\Loads\Postloads\TWR\TWRLoad.txt'
            'Localisation\Loads\Postloads\User\Loads\USERload.txt'
            'Thor\Loads\Postloads\DRT\DRTload.txt'
            'Thor\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            'Thor\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            'Thor\Loads\Postloads\EXT\Min\0018_Omega.xno'
            'Thor\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            'Thor\Loads\Postloads\FND\FNDload.txt'
            'Thor\Loads\Postloads\HUB\PITload.txt'
            'Thor\Loads\Postloads\LDD\0018_Omega.ldd'
            'Thor\Loads\Postloads\MAIN\MainLoad.txt'
            'Thor\Loads\Postloads\MARKOV\0018_Omega.mko'
            'Thor\Loads\Postloads\RAIN\0018_Omega.rfo'
            'Thor\Loads\Postloads\TWR\TWRLoad.txt'
            'Thor\Loads\Postloads\User\Loads\USERload.txt'
            'Vidar\Loads\Postloads\DRT\DRTload.txt'
            'Vidar\Loads\Postloads\EXT\Abs\0018_Omega.xdo'
            'Vidar\Loads\Postloads\EXT\Max\0018_Omega.xpo'
            'Vidar\Loads\Postloads\EXT\Min\0018_Omega.xno'
            'Vidar\Loads\Postloads\EXT\Sta\0018_Omega.sst'
            'Vidar\Loads\Postloads\FND\FNDload.txt'
            'Vidar\Loads\Postloads\HUB\PITload.txt'
            'Vidar\Loads\Postloads\LDD\0018_Omega.ldd'
            'Vidar\Loads\Postloads\MAIN\MainLoad.txt'
            'Vidar\Loads\Postloads\MARKOV\0018_Omega.mko'
            'Vidar\Loads\Postloads\RAIN\0018_Omega.rfo'
            'Vidar\Loads\Postloads\TWR\TWRLoad.txt'
            'Vidar\Loads\Postloads\User\Loads\USERload.txt'}
        codecs = {'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER' 'DRT' 'EXT' 'EXT' 'EXT' 'SST' 'FND' 'PIT' 'LDD' 'MAIN' 'MKO' 'RFO' 'TWR' 'USER'}
        
    end
    
    methods (TestClassSetup)
        function makeTestFolder(testCase)
            mkdir(fullfile(testCase.testFolder,'encodeFolder'));
        end
    end
    
    methods (TestClassTeardown)
        function deleteTestOutputs(testCase)
            fclose('all');
            rmdir(fullfile(testCase.testFolder,'encodeFolder'), 's');
        end
    end
    
    methods (Test, ParameterCombination =  'sequential')
        function testConvertWithoutError(testCase,files,codecs)
            if ~any(contains(testCase.skipFiles,files))
                dummy = LAC.intpostd.convert(fullfile(testCase.testFolder,files),codecs);
                if iscell(dummy)
                    testCase.compileError(files) = true;
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.intpostd.convert(''%s'',''%s'')'' throws the error: ''%s''',fullfile(testCase.testFolder,files),codecs,dummy{1}))
                else
                    testCase.compileError(files) = false;
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.intpostd.convert(''%s'',''%s'')'' throws an error.',fullfile(testCase.testFolder,files),codecs))
                end
            else
                fprintf('\n%s skipped by testConvertWithoutError due to known compile error using LAC.intpostd.convert\n',fullfile(testCase.testFolder,files))
            end
        end
        
        function testEncode(testCase,files,codecs)
            if ~any(contains(testCase.skipEncode,files))
                if ~any(contains(testCase.skipFiles,files)) && ~testCase.compileError(files) && testCase.encode(codecs)
                    dummy = LAC.intpostd.convert(fullfile(testCase.testFolder,files),codecs);
                    [~,filename]=fileparts(tempname);
                    fullFileName = fullfile(testCase.testFolder,'encodeFolder',[filename '.txt']);
                    try
                        dummy.encode(fullFileName);
                    catch
                        testCase.assertTrue(false,sprintf('Error during encode of ''%s''.',fullfile(testCase.testFolder,files)))
                    end
                    actual = testCase.getTXTdata(fullFileName);
                    seperator = strfind(files,'\');
                    expected = testCase.getTXTdata(fullfile(testCase.testFolder,'expectedEncode_corrected',files(1:seperator(1)-1),'Postloads',files(seperator(end-1)+1:seperator(end)-1),files(seperator(end)+1:end)));
                    testCase.verifyEqual(actual,expected,sprintf('Encoded file content ''%s'' is not as expected.',fullfile(testCase.testFolder,files)));
                end
            else
                fprintf('\n%s skipped by testEncode due to known encode error using encode() function\n',fullfile(testCase.testFolder,files))
            end
        end
        
        function testAutoDetectWithoutError(testCase,files,codecs)
            if ~any(contains(testCase.skipFiles,files)) && ~testCase.compileError(files) && testCase.autoDectect(codecs)
                dummy = LAC.intpostd.convert(fullfile(testCase.testFolder,files));
                if iscell(dummy)
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.intpostd.convert(''%s'')'' throws the error: ''%s''',fullfile(testCase.testFolder,files),dummy{1}))
                else
                    testCase.assertTrue(~iscell(dummy),sprintf('Running ''LAC.intpostd.convert(''%s'')'' throws an error.',fullfile(testCase.testFolder,files)))
                end
            end
        end
    end
    
    methods (Static)
        function result = RunUnitTests()
            result = run(LAC.intpostd.convert_Test);
            failed = result([result.Failed]);
            for iT = 1:length(failed)
                try
                    fprintf('\n%s',failed(iT).Details.DiagnosticRecord.TestDiagnosticResult{1});
                catch
                    fprintf('\nError in test %s at file %s line %i with message %s',failed(iT).Details.DiagnosticRecord.Stack(1).name,failed(iT).Details.DiagnosticRecord.Exception.stack(1).file,failed(iT).Details.DiagnosticRecord.Exception.stack(1).line,failed(iT).Details.DiagnosticRecord.Exception.message);
                end
            end
            fprintf('\n')
        end
        
        function [files,codecs] = findIntPostDFiles()
            list = dir(LAC.intpostd.convert_Test.testFolder);
            prepFolders = {list([list.isdir]).name};
            prepFolders = prepFolders(cellfun(@isempty,regexp(prepFolders,'^\.\.?$')));
            files = {};
            codecs = {};
            for i = 1:length(prepFolders)
                [files,codecs] = LAC.intpostd.convert_Test.getFilePaths(files,codecs,fullfile(prepFolders{i},'Loads'));
            end
        end
        
        function  [files,codecs] = getFilePaths(files,codecs,simulationFolder)
            % intpostd files
            postLoadFiles=LAC.intpostd.convert_Test.file2codec.keys;
            for i = 1:length(postLoadFiles)
                folder = postLoadFiles{i};
                files{end+1} = LAC.intpostd.convert_Test.getFile(fullfile(LAC.intpostd.convert_Test.testFolder,simulationFolder,'Postloads',folder));
                codecs{end+1} = LAC.intpostd.convert_Test.file2codec(folder);
            end
        end
        
        function file = getFile(folder)
            if exist(folder,'file') == 2
                file = strrep(folder,LAC.vts.convert_Test.testFolder,'');
            else
                list = ls(folder);
                folderSeperators=strfind(folder,'\');
                file = strrep(fullfile(folder(1:folderSeperators(end)),strtrim(list(1,:))),LAC.vts.convert_Test.testFolder,'');
            end
        end
    end
    
    methods (Access = private)
        function data = getTXTdata(self,fileName)
            fid=fopen(fileName);
            data=textscan(fid, '%s', -1, 'whitespace', '', 'delimiter', '\n');
            fclose(fid);
        end
    end
    
end