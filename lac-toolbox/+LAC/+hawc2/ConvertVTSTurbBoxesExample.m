% HAWC2 turb file generation
%
% This script converts VTS turbulence boxes to HAWC2 format.
%
% You should adapt the regex on line 18 and the following lines 
% to reflect the input file data and the desired output file names.
%
% JOSOW 2021

% Source folder for wind files
inputdirectory = 'w:\wind\162_100_G39_L336.Mann_22x22\';
% Folder to place output data
outputdirectory = 'vts2hawc2';

% Create output folder if not existing
if ~exist(outputdirectory, 'dir')
    mkdir(outputdirectory);
end

% Build lists of sources and targets
files = dir([inputdirectory '/*.int']);
sources = [];
targets = [];
for idx = 1:numel(files)
    rexp = regexp(files(idx).name, '(\d{3})(\d{2})(\d{3})(\w).int', 'tokens');
    if(~isempty(rexp))
        % Get tokens
        toks = rexp{1};
        rotd = str2num(toks{1});
        wsp = str2num(toks{2});
        seed = str2num(toks{3});
        component = toks{4};
        % Construct source file
        source = sprintf('%03d%02d%03d', rotd, wsp, seed);
        % Construct target 
        target = sprintf('%03d%02d%03d', rotd, wsp, seed);
        % Add to lists
        sources = [sources string(source)];
        targets = [targets string(target)];
    end
end

% Filter for unique
[sources, iuniq] = unique(sources);
targets = targets(iuniq);

% Convert all
hwt = waitbar(0, 'Starting conversion');
for i = 1:length(targets)
    waitbar(i/numel(sources), hwt, sprintf('Converting box %s to %s', sources(i), targets(i)));
    LAC.hawc2.turb.convertfromvts(sources(i), targets(i), inputdirectory, outputdirectory); 
end
close(hwt);
disp('Finished');