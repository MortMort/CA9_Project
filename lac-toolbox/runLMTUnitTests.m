%% Script to run all unit tests in lac-matlab-toolbox
clear all
fclose all
import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.TAPPlugin;
import matlab.unittest.plugins.ToFile;
topLevel=fileparts(mfilename('fullpath'));
addpath(genpath(topLevel));
cd(topLevel);
addpath('H:\Control\TEST\xlwrite')
%% Add tests in folders
suite = cell(1,0);
directory = dir('*\**');
folderNames = {directory([directory.isdir]).folder};
folderNames = folderNames(cellfun(@isempty,regexp(folderNames,'.*\\\+\w*$')));
folderNames = folderNames(cellfun(@isempty,regexp(folderNames,'.*\.git.*$')));
folderNames = folderNames(cellfun(@isempty,regexp(folderNames,'.*private$')));
folderNames = folderNames(cellfun(@isempty,regexp(folderNames,'.*@\w*$')));
folderNames = unique(folderNames');
for i = 1:length(folderNames)
    suite{end+1} = TestSuite.fromFolder(folderNames{i});
end

%% Add tests in packages
% Find tests in packages in top-level folders
directory = dir();
folderNames = {directory([directory.isdir]).name};
folderNames = folderNames(~cellfun(@isempty,regexp(folderNames,'^(?!(+|\.)).*')));

packages = dir('+*');
packageNames = {packages([packages.isdir]).name};
for i = 1:length(packageNames)
    suite{end+1} = TestSuite.fromPackage(packageNames{i}(2:end),'IncludingSubpackages',true);
end

% Find all packages inside folders (two-layers)
for i=1:length(folderNames)
    
    % top-level packages
    packages = dir(fullfile(folderNames{i},'+*'));
    packageNames = {packages([packages.isdir]).name};
    for k = 1:length(packageNames)
        suite{end+1} = TestSuite.fromPackage(packageNames{k}(2:end),...
            'IncludingSubpackages',true,...
            'BaseFolder',fullfile(topLevel,folderNames{i}));
    end
    
    % sub-folder packages
    directory = dir(folderNames{i});
    subFolderNames = {directory([directory.isdir]).name};
    subFolderNames = subFolderNames(~cellfun(@isempty,regexp(subFolderNames,'^(?!(+|\.)).*'))); % is not a package
    for j=1:length(subFolderNames)
        packages = dir(fullfile(folderNames{i},subFolderNames{j},'+*'));
        packageNames = {packages([packages.isdir]).name};
        for k = 1:length(packageNames)
            suite{end+1} = TestSuite.fromPackage(packageNames{k}(2:end),...
                'IncludingSubpackages',true,...
                'BaseFolder',fullfile(topLevel,folderNames{i},subFolderNames{j}));
        end
    end
end
suite = suite(~cellfun(@isempty,suite));
suite = [suite{:}];
%% Run tests
resultsFolder = 'testResults';
mkdir(resultsFolder);

runner = TestRunner.withTextOutput;
filename = fullfile(resultsFolder,'TapOutput.tap');
plugin = TAPPlugin.producingOriginalFormat(ToFile(filename));
runner.addPlugin(plugin);
xmlFile = fullfile(resultsFolder,'TestResults.xml');
p = XMLPlugin.producingJUnitFormat(xmlFile);
runner.addPlugin(p)
result = runner.run(suite);

%% Check for parse errors in all m-files
fileName = 'parseErrors.txt';
file = fopen(fullfile(resultsFolder,fileName),'w+');
fprintf(file,'-- Parse or syntax errors in LMT m-files  --\n');

mfiles = dir('**/*.m');
mfiles = arrayfun(@(x) fullfile(x.folder,x.name) ,mfiles,'UniformOutput',false);

parseErrors = []; parseErrorFiles = {};
for i = 1:length(mfiles)
    info =checkcode(mfiles{i});
    containParseErrors = contains({info.message},'parse error','IgnoreCase',true);
    parseErrors = [parseErrors; info(containParseErrors)];
    if any(containParseErrors)
        parseErrorFiles = [parseErrorFiles repmat(mfiles(i),1,sum(containParseErrors))];
    end
end

fprintf(file,'%-150s %-4s %s\n','File','Line','Message');
for i =1:length(parseErrors)
    fprintf(file,'%-150s %-4i %s\n',parseErrorFiles{i},parseErrors(i).line,parseErrors(i).message);
end

fclose(file);