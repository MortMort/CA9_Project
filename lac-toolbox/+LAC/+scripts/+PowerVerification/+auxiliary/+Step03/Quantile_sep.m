function [Quantiles] = Quantile_sep(vec_in, q_size)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author JOPMF - 13/05/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Target: Power Performance Verification
% -------------------------------------------------------------------
% DESCRIPTION
% -------------------------------------------------------------------
% Separates a data set in quantiles with an user-defined size

% -------------------------------------------------------------------
% INPUT SYNTAX
% -------------------------------------------------------------------
%   vec_in --> Turbulence intensity vector
%   q_size -> Quantiles size, e.g., 5 / 10 / 20

% -------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------
% Structure with the data index in each quantile
%	Quantiles.Q_10 = [10 12 13 15 20]
%	Quantiles.Q_20 = [10 12 13 15 20 37 44 200]
%	...
%	Quantiles.Q_90 = [10 12 13 15 20 37 44 200 211 263 277 280 301]

% -------------------------------------------------------------------
% NOTE
% -------------------------------------------------------------------
% For the NTM, the representative value of the turbulence STD is
% given by the 90% quantile for the given hub height WindSpeed

% -------------------------------------------------------------------
% STEP 1: DATA SORTING
% -------------------------------------------------------------------

	import LAC.scripts.PowerVerification.auxiliary.Step03.*
	
    % Sorting algorithm uses a row vector as an input
    if length(vec_in(1,:)) == 1
        vec_in = vec_in';
    end
    
    % Sorting
    vector_sorted  = quicksort(vec_in(1,:));
    
    % Index attachment
    for i = 1:length(vector_sorted(1,:))
        j = 1;
        
        while (vector_sorted(1, i) ~= vec_in(1, j))
           j = j + 1; 
        end
        
        vector_sorted(2,i) = j;
        
    end

% -------------------------------------------------------------------
% STEP 2: DATA BY QUANTILE
% -------------------------------------------------------------------

    qnt1 = q_size;
    qnt_vec = qnt1:q_size:100;
    Quantiles = {};
    
    for i=1:length(qnt_vec)
        Quantiles.name{i} = strcat('Q_', num2str(qnt_vec(i)));
        Quantiles.index{i} = vector_sorted(2, 1:floor((qnt_vec(i)/100) * length(vector_sorted(2,:))));
    end
end