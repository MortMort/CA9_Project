function excelStatus = outToExcel( fname, outPath, paths, data, sol )
% OUTTOEXCEL Function to output the summary of the Master Model
% down-selection
%   Results are written in an excel file
%
% Author: YAYDE
% Last checked by: YAYDE - 05/11/2019

excelStatus=0;
target=fullfile(outPath,fname);
varIDs=cellfun(@(x) sprintf('[%d]',x) ,num2cell(1:size(paths,1)),'UniformOutput',0);
mmIDs=cellfun(@(x) sprintf('[%d]',x) ,num2cell(sol.choices),'UniformOutput',0);
warning( 'off', 'MATLAB:xlswrite:AddSheet' ) ;
try
    status = xlswrite(target,sol.sensors,'Sensors');
    status = xlswrite(target,varIDs','Paths','A1');
    status = xlswrite(target,paths,'Paths','B1');
    status = xlswrite(target,data,'Dataset');
    
    status = xlswrite(target,{'Sensors'},'Load factors','A2');
    status = xlswrite(target,{'Variant IDs'},'Load factors','B1');
    status = xlswrite(target,mmIDs','Load factors','B2');
    status = xlswrite(target,sol.sensors,'Load factors','A3');
    status = xlswrite(target,sol.lf_matrix,'Load factors','B3');
    
    status = xlswrite(target,{'ID of choosen Master Models'},'DownSelection','A1');
    status = xlswrite(target,mmIDs','DownSelection','B1');
    status = xlswrite(target,{'Load factors'},'DownSelection','B4');
    status = xlswrite(target,{'Sensors'},'DownSelection','A4');
    status = xlswrite(target,sol.sensors,'DownSelection','A5');
    status = xlswrite(target,sol.lf_best,'DownSelection','B5');  
    
catch
    status;
end

%%%%%%%%%%%%%% Cleaning, saving and closing

sheetName = 'Sheet'; % EN: Sheet, DE: Tabelle, etc. (Lang. dependent)
% Open Excel file.
objExcel = actxserver('Excel.Application');
objExcel.Workbooks.Open(target); % Full path is necessary!
% Delete sheets.
try
    % Throws an error if the sheets do not exist.
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
catch
    ; % Do nothing.
end
% Save, close and clean up.
objExcel.ActiveWorkbook.Save;
objExcel.ActiveWorkbook.Close;
objExcel.Quit;
objExcel.delete;

excelStatus=status;
end

