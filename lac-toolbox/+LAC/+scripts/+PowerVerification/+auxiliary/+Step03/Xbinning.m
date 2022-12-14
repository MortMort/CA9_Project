function [X_bin] = Xbinning(Xmean,X_bin_size,Xname,index,wsbinning)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author MODFY - 10/05/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Target: Power Performance Verification
% 
% Inputs: 
% - Xmean (data): a struct variable which has been obtain by loading the
%          information from the database through the sript dataload
% - X_bin_size: the binning range to apply (note that the value should be
%                in percentage)
% -Xname: string variable that contains the name of the binning (example
% TI, Shear, TIQuantile...
% - index: pointing to a list of data toorganise into wind speed bin
% - wsbinning: int variable equal to 0 or 1. States if the binning if in 
%              function of the wind speed. 0 = no and 1 = yes.
% 
% Output:
% The function returns 
% X_bin: a structure variable containing 
%     - X_bin.name:  cells of vector of char the range of the X bin
%     - X_bin.index: cells of int vector containing the index of the measured 
%               data belonging the X bin
%               each index vector corresponds to the bin range having the 
%               same cell number 
%     - X_bin.lowerbinlimit is cell variable that contains the lower limit
%     of the bin 
%     - X_bin.upperbinlimit is cell variable that contains the upper limit
%     of the bin 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check index
if isempty(index)
    index=[1:length(Xmean)]';
end

% bin vector
if strcmp(Xname, 'TI') == 1
    X_bin_max_end = round(max(Xmean)/X_bin_size)*X_bin_size;
    X_bin_vec = [0 3 (3 + X_bin_size):X_bin_size:X_bin_max_end];
else
    X_bin_min_init = floor(min(Xmean)/X_bin_size)*X_bin_size; 
    X_bin_max_end = round(max(Xmean)/X_bin_size)*X_bin_size;  
    X_bin_vec = X_bin_min_init:X_bin_size:(X_bin_max_end);
end

if wsbinning==1
    % bin vector center in a multiple of the bin size for wind speed
    X_bin_min_init = floor(min(Xmean)/X_bin_size)*X_bin_size - X_bin_size/2;
    X_bin_max_end = round(max(Xmean)/X_bin_size)*X_bin_size + X_bin_size/2; 
    X_bin_vec = X_bin_min_init:X_bin_size:(X_bin_max_end);
    Xmean_vec = zeros(length(Xmean),1);
    Xmean_vec(index) = Xmean(index);
    Xmean = Xmean_vec;
    clear Xmean_vec
end

% bin label and data index within the bin
X_bin={};
for i=1:length(X_bin_vec)-1
    str_i_min = num2str(X_bin_vec(i));
    str_i_max = num2str(X_bin_vec(i+1));
    X_bin.name{i} = strcat(Xname,'_',str_i_min,'_',str_i_max);
    X_bin.lowerbinlimit{i} = X_bin_vec(i);
    X_bin.upperbinlimit{i} = X_bin_vec(i+1);
    X_bin.index{i}= find((Xmean>X_bin_vec(i)) & (Xmean<=X_bin_vec(i+1)));
end


end