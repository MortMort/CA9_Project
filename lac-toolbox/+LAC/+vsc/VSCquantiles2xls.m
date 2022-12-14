function VSCquantiles2xls(SegmentData,outputpath)
% VSCquantiles2xls(SegmentData,outputpath)
% Function to write the VSC quantiles to excel document
% NIWJO 2021

if nargin<2
    outputpath = cd;
end

for i = 1:size(SegmentData,1)
    % First reading the result files to figure out what sensors that exist
    % in the files
    [VSC_results_data] = LAC.vsc.import_VSC_Results_file(SegmentData{i,2});
    sensorsFatigue = fields(VSC_results_data.Fatigue);
    sensorsExtreme = fields(VSC_results_data.Extreme);
    sensor = [sensorsFatigue(2:end)' sensorsExtreme(2:end)'];
    [~,~,ValOut] = LAC.vsc.getIndexFromVSCresultData(SegmentData{i,2},sensor,0.8,'test');
    Values{i} = ValOut.Eval;
end

ResultComb = {};
for i =1:length(ValOut.p)
    [ResultVal, Index] = max(cell2mat(cellfun(@(x) x(:,ValOut.p==ValOut.p(i)),Values,'UniformOutput',0))');
    ResultComb = [ResultComb [num2cell(ResultVal)' SegmentData(Index,1)]];
end
SensorsIndex = ResultVal>20;

Pstr(1:2:length(ValOut.p)*2) = ValOut.p*100;
Pstr(2:2:length(ValOut.p)*2) = NaN;
Pstr = num2cell(Pstr);

Seg = '';
PlotContries = SegmentData(:,1);
for iii = 1:length(PlotContries)
    Seg = [Seg ' ' PlotContries{iii}];
end
xlswrite(fullfile(outputpath,['VSCquantiles ' strrep(Seg,' ','_') '.xls']), [['Sensors:' sensor(SensorsIndex)]' [Pstr' ResultComb(SensorsIndex,:)']'], 1, 'A2');
end