function combine_rotorlock(path, varargin)

% combine_rotorlock - Combines maintenance loads for documentation.
% Combines sets of rotor lock and parking tool loads for several variants,
% for use in maintenance load documents. Takes the ranked sensors for the
% different sensors in the "\DRT\RotorLockLoads.txt" file for all RL cases
% and ranks them globally. Write 5 excel sheets to the current folder, one
% for each sensor (MyMBr_max, MyMBr_min, MxMBf_abs, MzMBf_abs, MrMB_abs).
%
% Syntax:   combine_rotorlock(path)
%
% Inputs:
%    path - Cell array containing paths to "Loads" folder of all the
%           variants that need to be compared/combined.
%
% Example: 
%    combine_rotorlock({'h:\3MW\MK3\V1053450.072\IEC1A\Loads\', 'h:\3MW\MK3\V1053600.072\IEC1A\Loads\'})
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% July 2016; Last revision: 15-July-2016

% Input
file    = '\DRT\RotorLockLoads.txt';   % file to read from in the Loads folder
n_ln    = [38, 132, 226, 320];                  % line numbers to start from (RL1, RL2, RL3, RL4)

% Use input parser object to allow for optional parameters with default values
Parser = inputParser;
Parser.addOptional('output_folder',cd);
% Parse.
Parser.parse(varargin{:});
% Set variables.
output_folder = strcat(Parser.Results.('output_folder'), '\');

% Loop on files and save data
MyMBr_max   = zeros(10*length(path), 13, 4);    MyMBr_max_DLC   = cell(10*length(path), 1, 4);      % create arrays for storing data
MyMBr_min   = zeros(10*length(path), 13, 4);    MyMBr_min_DLC   = cell(10*length(path), 1, 4);
MxMBf       = zeros(10*length(path), 13, 4);    MxMBf_DLC       = cell(10*length(path), 1, 4);
MzMBf       = zeros(10*length(path), 13, 4);    MzMBf_DLC       = cell(10*length(path), 1, 4);
MrMB        = zeros(10*length(path), 13, 4);    MrMB_DLC        = cell(10*length(path), 1, 4);
for i = 1:length(path)                              % start looping on paths in input
    fid = fopen(fullfile(path{i}, file));                   % open file
    C   = textscan(fid, '%s', 'delimiter', '\n');   % read file and store data in preliminary array
    fclose(fid);                                    % close file
    MyMBr_max((10*(i-1) + 1):10*i, 13, :) = i;      MyMBr_min((10*(i-1) + 1):10*i, 13, :) = i;      MxMBf((10*(i-1) + 1):10*i, 13, :) = i;      MzMBf((10*(i-1) + 1):10*i, 13, :) = i;      MrMB((10*(i-1) + 1):10*i, 13, :) = i;
                                                    % write reference number in arrays
    for j = 1:10                                    % start looping on rank (i.e. load sets) in postloads files
        for k = 1:4                                 % start looping on RL cases (i.e. RL1, RL2, RL3 and RL4)
            MyMBr_max(10*(i-1)+j, 1:12, k)  = sscanf(C{1,1}{n_ln(k)+j, 1}, '%d %f %f %f %f %f %f %f %f %f %f %f %*s', 12);                  % write load data to array
            MyMBr_min(10*(i-1)+j, 1:12, k)  = sscanf(C{1,1}{n_ln(k)+j+16, 1}, '%d %f %f %f %f %f %f %f %f %f %f %f %*s', 12);
            MxMBf(10*(i-1)+j, 1:12, k)      = sscanf(C{1,1}{n_ln(k)+j+32, 1}, '%d %f %f %f %f %f %f %f %f %f %f %f %*s', 12);
            MzMBf(10*(i-1)+j, 1:12, k)      = sscanf(C{1,1}{n_ln(k)+j+48, 1}, '%d %f %f %f %f %f %f %f %f %f %f %f %*s', 12);
            MrMB(10*(i-1)+j, 1:12, k)       = sscanf(C{1,1}{n_ln(k)+j+64, 1}, '%d %f %f %f %f %f %f %f %f %f %f %f %*s', 12);
            MyMBr_max_DLC{10*(i-1)+j, 1, k} = char(sscanf(C{1,1}{n_ln(k)+j, 1}, '%*d %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %s'))';    % write DLC names to array
            MyMBr_min_DLC{10*(i-1)+j, 1, k} = char(sscanf(C{1,1}{n_ln(k)+j+16, 1}, '%*d %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %s'))';
            MxMBf_DLC{10*(i-1)+j, 1, k}     = char(sscanf(C{1,1}{n_ln(k)+j+32, 1}, '%*d %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %s'))';
            MzMBf_DLC{10*(i-1)+j, 1, k}     = char(sscanf(C{1,1}{n_ln(k)+j+48, 1}, '%*d %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %s'))';
            MrMB_DLC{10*(i-1)+j, 1, k}      = char(sscanf(C{1,1}{n_ln(k)+j+64, 1}, '%*d %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %s'))';
        end
    end
end

% Sort values
MyMBr_max_  = zeros(10*length(path), 13, 4);    MyMBr_max_DLC_  = cell(10*length(path), 1, 4);      % create arrays for storing sorted data
MyMBr_min_  = zeros(10*length(path), 13, 4);    MyMBr_min_DLC_  = cell(10*length(path), 1, 4);
MxMBf_      = zeros(10*length(path), 13, 4);    MxMBf_DLC_      = cell(10*length(path), 1, 4);
MzMBf_      = zeros(10*length(path), 13, 4);    MzMBf_DLC_      = cell(10*length(path), 1, 4);
MrMB_       = zeros(10*length(path), 13, 4);    MrMB_DLC_       = cell(10*length(path), 1, 4);
for k = 1:4     % start looping on RL cases (i.e. RL1, RL2, RL3 and RL4)
    [MyMBr_max_(:, :, k), index]    = sortrows(MyMBr_max(:, :, k), -8);     MyMBr_max_DLC_(:, :, k) = MyMBr_max_DLC(index, 1, k);
    [MyMBr_min_(:, :, k), index]    = sortrows(MyMBr_min(:, :, k), 8);      MyMBr_min_DLC_(:, :, k) = MyMBr_min_DLC(index, 1, k);
    [MxMBf_(:, :, k), index]        = sortrows(MxMBf(:, :, k), -5, 'ComparisonMethod', 'abs');         MxMBf_DLC_(:, :, k)     = MxMBf_DLC(index, 1, k);
    [MzMBf_(:, :, k), index]        = sortrows(MzMBf(:, :, k), -6, 'ComparisonMethod', 'abs');         MzMBf_DLC_(:, :, k)     = MzMBf_DLC(index, 1, k);
    [MrMB_(:, :, k), index]         = sortrows(MrMB(:, :, k), -11, 'ComparisonMethod', 'abs');         MrMB_DLC_(:, :, k)      = MrMB_DLC(index, 1, k);
end

% circshift function was set up using 2015 and it is not tested / validated that using 2010 will yield same results.
matlab_version = version('-release');
matlab_version_year = matlab_version(1:4);
if str2double(matlab_version_year)<2015
    error('The call of the circshift function is only validated (MIFAK) in Matlab 2015 and in the current call (3 parameters) it will crash in at least 2010. Please use matlab 2015 for this function.')
end

% Delete "local Rank" and "Omega" values and rearrange arrays
MyMBr_max_(:, 10, :)    = [];       MyMBr_max_(:, 1, :) = [];       MyMBr_max_  = circshift(MyMBr_max_, 1, 2);
MyMBr_min_(:, 10, :)    = [];       MyMBr_min_(:, 1, :) = [];       MyMBr_min_  = circshift(MyMBr_min_, 1, 2);
MxMBf_(:, 10, :)        = [];       MxMBf_(:, 1, :)     = [];       MxMBf_      = circshift(MxMBf_, 1, 2);
MzMBf_(:, 10, :)        = [];       MzMBf_(:, 1, :)     = [];       MzMBf_      = circshift(MzMBf_, 1, 2);
MrMB_(:, 10, :)         = [];       MrMB_(:, 1, :)      = [];       MrMB_       = circshift(MrMB_, 1, 2);

% Write data to excel files
RL_case = {'RL1', 'RL2', 'RL3', 'RL4'};
header = {'Ref.', 'FxMBf [kN]', 'FyMBr [kN]', 'FzMBf [kN]', 'MxMBf [kNm]', 'MzMBf [kNm]', 'MxMBr [kNm]', 'MyMBr [kNm]', 'MzMBr [kNm]', 'MrMB [kNm]', 'PLF []', 'LoadCase'};
for k = 1:4     % start looping on RL cases (i.e. RL1, RL2, RL3 and RL4)
    xlswrite(strcat(output_folder, 'MyMBr_max.xlsx'), vertcat(header, horzcat(num2cell(MyMBr_max_(:, :, k)), MyMBr_max_DLC_(:, :, k))), RL_case{k});
    xlswrite(strcat(output_folder, 'MyMBr_min.xlsx'), vertcat(header, horzcat(num2cell(MyMBr_min_(:, :, k)), MyMBr_min_DLC_(:, :, k))), RL_case{k});
    xlswrite(strcat(output_folder, 'MxMBf.xlsx'), vertcat(header, horzcat(num2cell(MxMBf_(:, :, k)), MxMBf_DLC_(:, :, k))), RL_case{k});
    xlswrite(strcat(output_folder, 'MzMBf.xlsx'), vertcat(header, horzcat(num2cell(MzMBf_(:, :, k)), MzMBf_DLC_(:, :, k))), RL_case{k});
    xlswrite(strcat(output_folder, 'MrMB.xlsx'), vertcat(header, horzcat(num2cell(MrMB_(:, :, k)), MrMB_DLC_(:, :, k))), RL_case{k});
end