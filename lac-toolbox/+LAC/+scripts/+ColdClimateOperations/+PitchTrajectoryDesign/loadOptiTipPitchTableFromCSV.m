function [csv_TableLambdaToPitchOptX, csv_TableLambdaToPitchOptY, csv_PartLoadLambdaOpt, csv_norm] = loadOptiTipPitchTableFromCSV(csv_norm)

if ~exist(csv_norm, 'file')                         % check if the file exists
    error('ProdCtrl_ file not found!')              % throw error if it doesn't
else
    csv_norm_par    = LAC.vts.convert(csv_norm);    % load controller parameters if it does
end

% optimal tip-speed ratio
csv_PartLoadLambdaOpt           = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_SC_PartLoadLambdaOpt'))));
% TSR
csv_TableLambdaToPitchOptX(1)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX01'))));
csv_TableLambdaToPitchOptX(2)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX02'))));
csv_TableLambdaToPitchOptX(3)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX03'))));
csv_TableLambdaToPitchOptX(4)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX04'))));
csv_TableLambdaToPitchOptX(5)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX05'))));
csv_TableLambdaToPitchOptX(6)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX06'))));
csv_TableLambdaToPitchOptX(7)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX07'))));
csv_TableLambdaToPitchOptX(8)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX08'))));
csv_TableLambdaToPitchOptX(9)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX09'))));
csv_TableLambdaToPitchOptX(10)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX10'))));
csv_TableLambdaToPitchOptX(11)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX11'))));
csv_TableLambdaToPitchOptX(12)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX12'))));
csv_TableLambdaToPitchOptX(13)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX13'))));
csv_TableLambdaToPitchOptX(14)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptX14'))));
% pitch [deg]
csv_TableLambdaToPitchOptY(1)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY01'))));
csv_TableLambdaToPitchOptY(2)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY02'))));
csv_TableLambdaToPitchOptY(3)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY03'))));
csv_TableLambdaToPitchOptY(4)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY04'))));
csv_TableLambdaToPitchOptY(5)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY05'))));
csv_TableLambdaToPitchOptY(6)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY06'))));
csv_TableLambdaToPitchOptY(7)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY07'))));
csv_TableLambdaToPitchOptY(8)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY08'))));
csv_TableLambdaToPitchOptY(9)   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY09'))));
csv_TableLambdaToPitchOptY(10)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY10'))));
csv_TableLambdaToPitchOptY(11)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY11'))));
csv_TableLambdaToPitchOptY(12)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY12'))));
csv_TableLambdaToPitchOptY(13)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY13'))));
csv_TableLambdaToPitchOptY(14)  = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_OTC_TableLambdaToPitchOptY14'))));

