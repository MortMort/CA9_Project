
function TWRdata = calc_TWRdata(MAINpath)

% Extracts Mytt moment from tower file
% Last checked by YAYDE - 30/04/2020

[filepath,~,~] = fileparts(MAINpath);
path=filepath(1:(end-5));

%% Paths
% Path to tower - assumes standard location
pathChangedDLC14 = regexprep(path,'\Postloads(\w*)\','\Postloads_ChangedDLC14\', 'ignorecase');
MtwrPath = dir([pathChangedDLC14 '\TWR\TWRload.txt']);
if isempty(MtwrPath)
    errordlg(['There are no TWRload.txt file in the folder ', pathChangedDLC14,'.Please run IntPostD in the folder']);
end
if length(MtwrPath)>1
    errordlg(['There are more than one TWRload file in the folder ', pathChangedDLC14,'.Please remove all except the one which has the required data']);
end
TWRPath=[MtwrPath.folder filesep MtwrPath.name];

twrres=LAC.intpostd.convert(TWRPath,'TWR');
Mytt=twrres.LateralForeAftFatigueLoadsAndRatio(1).MytValue;

TWRdata=...
    [Mytt;... 
    ];

%         'Mytt' 'Rfc' '4.00' 'Mytt Rfc 4.00'


end




