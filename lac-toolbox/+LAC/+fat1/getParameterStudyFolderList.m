function [ folderList, parStudyText, parStudyValues ] = getParameterStudyFolderList(Fat1folder, studyNumber, showOnlyChangedParams)
%GETPARAMETERSTUDYFOLDERLIST - Retreives the list of folders matching the
%study numbers wished.
%Optionally generates a list of parameters
%Optional file header info (to give more details about the function than in the H1 line)
%Optional file header info (to give more details about the function than in the H1 line)
%
% Syntax:  [output1,output2] = function_name(input1,input2,input3)
%
% Inputs:
%    Fat1folder - Full path to the FAT1 parameter study folder
%    studyNumber - Int, wished study number to select (empty to select all)
%    showOnlyChangedParams - Bool, cleans the parameter list for those
%    parameters which are constant across all the parameter studies
%
% Outputs:
%    folderList   - List of FAT1 folders matching the selection criteria
%    parStudyText - Parameter names
%    parStudyValues - Parameter values
%
% Example: 
%    [ folderList, xLabelText, parStudyValues ] = ...
%            LAC.fat1.getParameterStudyFolderList('h:\FEATURE\HighTowers\007\Mk3B_V126_3.45MW_126.0_hh166\LoadsTowV2_SSTD_LogDeval\', 2, true)
%
% Other m-files required: none
% Subfunctions: removeEmptyParameterCells
% MAT-files required: none
%
% See also: LAC.fat1.fat1info

% Author: FACAP, Fabio Caponetti
% April 2016; Last revision: 04-April-2016

%------------- BEGIN CODE --------------

% Reads the FAT1 sweep folder
[subfolders, parStudyValues, parameters] = LAC.fat1.fat1info(Fat1folder);
% Initializes the result matrices
folderList         = {};
parStudyText       = [];
% If at least a folder exists
if ~isempty(Fat1folder)
    idxStudy   = [];
    % For each FAT1 subfolder
    for ii=1:length(subfolders)
        if ~isempty(studyNumber) % checks if this is one of the studies wished
            if ~ismember(str2double(subfolders{ii}(1:2)), studyNumber)
                % if not, skips it
                continue;
            end
        end
        % full folder path
        folderList{end+1} = fullfile(Fat1folder, subfolders{ii});
        idxStudy(end+1)   = ii;
    end
    if showOnlyChangedParams
        % Takes out only the parameters which change between each folder;
        parStudyValues  = parStudyValues(idxStudy, :);
        if length(subfolders)>1
            parIdx = diff(parStudyValues)~=0;
        else
            parIdx = 1;
        end
        parStudyValues = parStudyValues(:, parIdx(1,:));
        parStudyText      = removeEmptyParameterCells(parameters(idxStudy,parIdx(1,:)));
    else
        parStudyText      = removeEmptyParameterCells(parameters(idxStudy,:));
    end
end
end

% Function to remove empty parameter cells
function parameterText = removeEmptyParameterCells(parameterTextCell)
parameterText = {};
for row = 1:size(parameterTextCell, 1)
    for col = 1:size(parameterTextCell, 2)
        if ~isempty(parameterTextCell{row, col})
            parameterText{row, col} = parameterTextCell{row, col};
        end
    end
end
parameterText = unique(parameterText, 'stable')';
end

%------------- END OF CODE --------------