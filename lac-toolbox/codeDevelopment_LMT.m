classdef codeDevelopment_LMT < handle
%CODEDEVELOPMENT_LMT - Used to generate new, add headers and tests to m-files.
% This class can be used to generate templates for new scripts,
% functions and classes which obey the documentation requirements
% for new code in LMT. It can also add a header template to existing files
% and create a template for test of an m-file.
%
% Constructor syntax:  
%    object = CODEDEVELOPMENT_LMT(fullFilePath) where fullFilePath is 
%    a path to a new/existing m-file, e.g. 'c:\temp\script.m'.
%
% Important class methods:
%    writeNewFunction()
%    writeNewScript()
%    writeNewClass()
%    writeHeader() or writeHeader(fileType)
%    writeUnitTestTemplate()
%
% See also: matlab.unittest.TestCase, assert

    
    properties (SetAccess = private, GetAccess = public)
        fileName char % name of file
        fileLocation char % location of file
        fullFilePath; % [fileLocation, fileName]
        fileType % 'class', 'function' or 'script'
    end
    
    methods
        function self = codeDevelopment_LMT(fullFilePath)
            % CODEDEVELOPMENT_LMT Construct the codeDevelopment_LMT object.
            % fullFilePath is a path to a new/existing m-file, e.g. 'c:\temp\script.m'.
            [self.fileLocation,filename,extension] = fileparts(fullFilePath);
            self.fileName = [filename,'.m'];
            self.fullFilePath = fullfile(self.fileLocation,self.fileName);
        end
        
        function writeNewFunction(self)
            % WRITENEWFUNCTION writes a template for a new matlab function
            fileID = fopen(self.fullFilePath,'w+');
            template={
                sprintf('function [output1,output2] = %s(input1,input2,input3)',self.fileName(1:end-2))
                'end'};
            fprintf(fileID,'%s\n', template{:});
            fclose(fileID);
            self.fileType = 'function';
            self.writeHeader();
        end
        
        function writeNewScript(self)
            % WRITENEWSCRIPT writes a template for a new matlab script
            self.fileType = 'script';
            fileID = fopen(self.fullFilePath,'w+');
            fclose(fileID);
            self.writeHeader();
        end
        
        function writeNewClass(self)
            % WRITENEWCLASS writes a template for a new matlab class
            fileID = fopen(self.fullFilePath,'w+');
            template={
                sprintf('classdef %s',self.fileName(1:end-2))
                ''
                '    properties'
                '        property1 % short explaination'
                '    end'
                ''
                '    methods'
                sprintf('        function self=%s(input1,input2,input3)',self.fileName(1:end-2))
                sprintf('        %%%s short description.',upper(self.fileName(1:end-2)))
                '        end'
                ''
                '        function [output1,output2] = firstFunction(input1,input2)'
                '        % FIRSTFUNCTION short description.'
                ''
                '        end'
                '        function [output1,output2] = secondFunction(input1,input2)'
                '        % SECONDFUNCTION short description.'
                ''
                '        end'
                '    end'
                ''
                'end'};
            fprintf(fileID,'%s\n', template{:});
            fclose(fileID);
            self.fileType = 'class';
            self.writeHeader();
        end
        
        function writeHeader(self,fileType)
            % WRITEHEADER writes a header template to the given fileType
            % fileType can be either 'function', 'script', 'class'.
            if nargin == 1
                fileType = self.fileType;
            end
            
            % read in current file content
            fileID = fopen(self.fullFilePath,'r');
            fileContent = textscan(fileID, '%s', -1, 'whitespace', '', 'delimiter', '\n');
            fileContent = fileContent{1};
            fclose(fileID);
            
            switch fileType
                case 'function'
                   header = {
                    sprintf('%%%s - One line description of what the function performs (H1 line)',upper(self.fileName(1:end-2)))
                    '%Optional file header info (to give more details about the function than in the H1 line)'
                    '%Optional file header info (to give more details about the function than in the H1 line)'
                    '%Optional file header info (to give more details about the function than in the H1 line)'
                    '%'
                    '% Syntax:  '
                    sprintf('%%    [output1,output2] = %s(input1) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of inputs and outputs.'
                    '%'
                    sprintf('%%    [output1,output2] = %s(input1,input2) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of input2 and what it affects.'
                    '%'
                    sprintf('%%    [output1,output2] = %s(input1,input2,input3) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of input2 and what it affects.'
                    '%'
                    '% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2'
                    ''
                    };
                    codeStart = find(~cellfun(@isempty,regexp(fileContent,'^\s*function')),1);
                    if codeStart~=1
                        warning('''function'' tag not found in first line of code')
                    end
                    headerAdded = [fileContent(codeStart);header;fileContent(codeStart+1:end)];
                case 'script'
                    header = {
                       sprintf('%%%s - One line description of what the script performs (H1 line)',upper(self.fileName(1:end-2)))
                       '%Optional file header info (to give more details about the script than in the H1 line)'
                       '%Optional file header info (to give more details about the script than in the H1 line)'
                       '%Optional file header info (to give more details about the script than in the H1 line)'
                       '%'
                       '% Initizalization'
                       'clear all'
                       '%% USER INPUTS'
                       ''
                       '%% SCRIPT (Not to be changed by the user)'
                       };
                   headerAdded = [header;fileContent];
                case 'class'
                    header = {
                    sprintf('%%%s - One line description of what the class performs (H1 line)',upper(self.fileName(1:end-2)))
                    '%Optional file header info (to give more details about the class than in the H1 line)'
                    '%Optional file header info (to give more details about the class than in the H1 line)'
                    '%Optional file header info (to give more details about the class than in the H1 line)'
                    '%'
                    '% Constructor syntax:  '
                    sprintf('%%    object = %s(input1) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of inputs.'
                    '%'
                    sprintf('%%    object = %s(input1,input2) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of input2 and what it affects.'
                    '%'
                    sprintf('%%    object = %s(input1,input2,input3) followed by',upper(self.fileName(1:end-2)))
                    '%    a description of input2 and what it affects.'
                    '%'
                    '%'
                    '% Important class methods:'
                    '%    [output1,output2] = firstFunction(input1,input2)'
                    '%    [output1,output2] = secondFunction(input1,input2)'
                    '%'
                    '% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2'
                    ''
                    };
                    codeStart = find(~cellfun(@isempty,regexp(fileContent,'^\s*classdef')),1);
                    if codeStart~=1
                        warning('''classdef'' tag not found in first line of code')
                    end
                    headerAdded = [fileContent(codeStart);header;fileContent(codeStart+1:end)];
            end
            
            fileID = fopen(self.fullFilePath,'w+');
            fprintf(fileID,'%s\n', headerAdded{:});
            fclose(fileID);            
        end
        
        function writeUnitTestTemplate(self)
            % WRITEUNITTESTTEMPLATE adds a simple unit test template for the m-file.
            example = {
            sprintf('%% test %s',self.fileName(1:end-2))
            'testParameters = [1 3 -1 Inf NaN];'
            ''
            '%% Test 1: test normal input'
            'expected = [1 9 1];'
            ''
            sprintf('actual = %s(testParameters(1));',self.fileName(1:end-2))
            'assert(actual == expected(1),''actual: %1.2f is not equal to expected output: %1.2f'',actual,expected(1))'
            ''
            sprintf('actual = %s(testParameters(2));',self.fileName(1:end-2))
            'assert(actual == expected(2),''actual: %1.2f is not equal to expected output: %1.2f'',actual,expected(2))'
            ''
            sprintf('actual = %s(testParameters(3));',self.fileName(1:end-2))
            'assert(actual == expected(3),''actual: %1.2f is not equal to expected output: %1.2f'',actual,expected(3))'
            ''
            '%% Test 2: abnormal input'
            'expected = Inf;'
            ''
            sprintf('actual = %s(testParameters(4));',self.fileName(1:end-2))
            'assert(actual == Inf,''actual: %1.2f is not equal to expected output: Inf'',actual)'
            ''
            sprintf('actual = %s(testParameters(5));',self.fileName(1:end-2))
            'assert(isnan(actual),''actual: %1.2f is not equal to expected output: NaN'',actual)'
            };
            fileID = fopen([self.fullFilePath(1:end-2),'Test.m'],'w+');
            fprintf(fileID,'%s\n', example{:});
            fclose(fileID);            
        end
    end
end

