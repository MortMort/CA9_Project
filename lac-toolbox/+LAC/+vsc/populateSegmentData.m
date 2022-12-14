function SegmentData = populateSegmentData(SegmentData)
% SegmentData = populateSegmentData(SegmentData)
% Function used in VSC scripts
% Reads data from VSC results files and populates the SegmentData structure
for i = 1:size(SegmentData,1)
   SegmentData{i,3}.data = []; SegmentData{i,5}.data = [];
   disp(['Reading ' SegmentData{i,2}{:}])
   [VSC_results_data]      = LAC.vsc.import_VSC_Results_file(SegmentData{i,2});
   SegmentData{i,4}       = fieldnames(VSC_results_data.Fatigue)';
   SegmentData{i,3}.data  = cell2mat(cellfun(@(x) VSC_results_data.Fatigue.(x),SegmentData{i,4},'UniformOutput',0));
   SegmentData{i,6}       = fieldnames(VSC_results_data.Extreme)';
   SegmentData{i,5}.data  = cell2mat(cellfun(@(x) VSC_results_data.Extreme.(x),SegmentData{i,6},'UniformOutput',0));
end
