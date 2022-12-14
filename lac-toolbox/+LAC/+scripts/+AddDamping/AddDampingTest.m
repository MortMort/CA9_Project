classdef AddDampingTest < matlab.unittest.TestCase
    properties
        prep_file = {'\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\LACVMSW-624\81SBI_81TG\testAddDamping.txt'
            '\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\LACVMSW-624\62_82\addDampingTest62_82.txt'}
        output = {'\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\LACVMSW-624\81SBI_81TG\damping_application.txt'
            '\\dkrkbfile01\flex\ToolsDemo\LACMatlabToolbox\LACVMSW-624\62_82\damping_application.txt'}
        DLCs = {'81SBI';'81TG'}
    end
    
    methods (Test)
        function Test81SBI_81SBI(testCase)
            n_damping = LAC.scripts.AddDamping.edgewise_vibration_detect(...
                testCase.prep_file{1}, 'DLCs', testCase.DLCs,'forceRead',false);
            assert(n_damping==15,'The number of relevant damped modes are not correct');
            
            expected = {
                '81SBIPi-5wd130azim120'
                '81SBIPi-5wd140azim120'
                '81SBIPi-5wd150azim120'
                '81SBIPi-5wd300azim120'
                '81SBIPi0wd130azim120'
                '81SBIPi0wd140azim120'
                '81SBIPi0wd150azim120'
                '81SBIPi30wd140azim120'
                '81SBIPi30wd150azim120'
                '81SBIPi60wd150azim120'
                '81SBIPi60wd330azim120'
                '81SBIPi60wd340azim120'
                '81SBIPi60wd350azim120'
                '81SBIPi95wd150azim120'
                '81TGwd150azim120'
                };
            
            testCase.checkAddedDamping(testCase.output{1},testCase.prep_file{1},expected);
            testCase.cleanUp(testCase.output{1},testCase.prep_file{1});
        end
        
        function TestDLC62_82(testCase)
            n_damping = LAC.scripts.AddDamping.edgewise_vibration_detect(...
                testCase.prep_file{2},'forceRead',false);
            assert(n_damping==26,'The number of relevant damped modes are not correct');
            
            expected = {
                '62E50a010'
                '62E50a020'
                '62E50a030'
                '62E50a040'
                '62E50a050'
                '62E50a060'
                '62E50a130'
                '62E50a140'
                '62E50a150'
                '62E50a160'
                '62E50a170'
                '62E50b010'
                '62E50b020'
                '62E50b030'
                '62E50b040'
                '62E50b050'
                '62E50b060'
                '62E50b140'
                '62E50b150'
                '62E50b160'
                '62E50b170'
                '62E50b180'
                '82LTPT030'
                '82LTPT140'
                '82LTPT150'
                '82LTPT160'
                };
            
            testCase.checkAddedDamping(testCase.output{2},testCase.prep_file{2},expected);
            testCase.cleanUp(testCase.output{2},testCase.prep_file{2});
        end
    end
    
    methods (Static)
        function checkAddedDamping(output,prep_file,expected)
            txt=LAC.codec.CodecTXT(output);
            actual = txt.getData();
            
            assert(isequaln(expected,actual),'result file is not as expected');
            clear txt
            
            % Add damping to correct load cases
            LAC.scripts.AddDamping.apply_edgewise_damping(prep_file, 1, 0, 0, 0);
            
            % load the updated prep file
            prepFile = LAC.vts.convert(prep_file,'REFMODEL');
            
            % get expected damped DLCs and the actual DLC options from the updated prep
            % file
            expectedDampedDLCs = contains(prepFile.LoadCaseNames',expected);
            DLCoptions = cellfun(@(x) x{3},prepFile.LoadCases(expectedDampedDLCs),'UniformOutput',false)';
            
            % Check if DLCs are damped
            assert(all(~cellfun(@isempty,strfind(DLCoptions,'dd 21 6.3 dd 29 6.3 dd 37 6.3 dd 23 6.3 dd 31 6.3 dd 39 6.3'))),...
                'expected load cases where not damped')
            DLCoptions = cellfun(@(x) x{3},prepFile.LoadCases(~expectedDampedDLCs),'UniformOutput',false)';
            % Check if DLCs are damped
            assert(any(~cellfun(@isempty,strfind(DLCoptions,'dd 21 6.3 dd 29 6.3 dd 37 6.3 dd 23 6.3 dd 31 6.3 dd 39 6.3')))==0,...
                'expected load cases of no need to be damped was damped')
        end
        
        function cleanUp(output,prep_file)
            % clean up
            workingDir = fileparts(prep_file);
            copyFolder = ls(fullfile(workingDir,'_OLD_*'));
            filesInFolder = dir(fullfile(workingDir,copyFolder));
            copyfile(fullfile(workingDir,copyFolder,filesInFolder(~[filesInFolder.isdir]).name),workingDir)
            delete(output)
            rmdir(fullfile(workingDir,copyFolder), 's');
        end
    end
    
end