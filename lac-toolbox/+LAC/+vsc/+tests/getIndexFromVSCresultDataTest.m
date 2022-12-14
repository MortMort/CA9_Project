%% Test for getIndexFromVSCresultData
% NIWJO 2021
clear
testFiles = {'w:\ToolsDevelopment\VSC\SupportFiles\LoadsDE.txt'
    'w:\ToolsDevelopment\VSC\SupportFiles\LoadsSE.txt'};

% Test 1: One Sensor two different files
expected(1).index = 72; % expected result from test file 1
expected(2).index = 73; % expected result from test file 2

sensor = 'MxHub_LDD_m=3.3'; % sensor
pval = 0.8; % 80% procentile to search for
for i = 1:length(testFiles)
    index = LAC.vsc.getIndexFromVSCresultData(testFiles{i},sensor,pval,'test'); % index in data file
    assert(isequaln(index,expected(i).index),'Failed assertation of %s',testFiles{i}) % check if the expected is the same
end

% Test 2 and 3: All Sensors two different files
% Same as before, but now testing all sensors!
clear expected pval sensor

% expected result from test file 1
expected(1).index =  [77    22    72    42    55    72     1     1    49     1    78     1    10    95    43     1    10    66    66    66     1    22     1    92     1    22     1 ...
    42    55    55     1    55     1    55    89     1     1    77    25     5    25    25    25    25    20    25    80    36    25    81    14    36     7     4 ...
    91    25    25    25    25    91    14    25     2    25    25    25    25    54    54    25     5    77    70];

% expected result from test file 2
expected(2).index =  [   514   492   363   253   310    73     1     1   509     1   410     1   381   327   486     1   517   461   136   131     1   382     1   252     1   399     1 ...
    379   512   272     1   299     1   299   316     1     1   514    79   608    79    79    79   608    79    79   321   571   321   330   321   604   397   606 ...
    381    79    79   631    79   349    79   323     1    79    79   313    79    79    79    79   552    80   445];

pval = 0.8;% 80% procentile to search for

for i = 1:length(testFiles)
    % First reading the result files to figure out what sensors that exist
    % in the files
    [VSC_results_data] = LAC.vsc.import_VSC_Results_file(testFiles{i});
    fatigueFields = fields(VSC_results_data.Fatigue);
    extremeFields = fields(VSC_results_data.Extreme);
    sensor = [fatigueFields' extremeFields'];
    
    actual(i).index = LAC.vsc.getIndexFromVSCresultData(testFiles{i},sensor,pval,'test');
    
    % Test if the expected indexes are the same as the actual
    assert(isequaln(actual(i).index,expected(i).index),'Failed assertation of %s',testFiles{i});
end
