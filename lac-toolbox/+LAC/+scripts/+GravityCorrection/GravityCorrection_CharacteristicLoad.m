function [Fk_up] = GravityCorrection_CharacteristicLoad(Fk_v,Fgrav_v,PLF,PLFmin,family,method)
% GravityCorrection_CharacteristicLoad - Function to calculate the gravity corrected partial safety factors and an updated characteristic load
%
% Syntax:  [output1,output2] = GravityCorrection_CharacteristicLoad(Fk_v,Fgrav_v,PLF,family,method)
%
% Inputs:
%    Fk_v 		- Main load sensor (1D array)
%    Fgrav_v 	       - Contemporaneous gravity load (1D array)
%    PLF		- Partial Load Factor for XXXXX
%    PLFmin		- Minimum PLF limit for gravity correction
%    family		- Family number (1D array)
%    method		- Family method to be applied (1D array)
%
% Outputs:
%    Fk_up 		- Gravity Correction main load sensor (1D array)
%
% Example: 
%    TBD
%    TBD
%    TBD
%
% Author: IVSON, Ivan Sønderby
% Oct. 2019; Last revision: 16-Oct-2019

%------------- BEGIN CODE --------------

    if nargin > 4 % then the output must be family weighted
        unique_families = unique(family);
        nr_fam = length(unique_families);
        Fk_up = zeros(nr_fam,1);
        for ii = 1:nr_fam
            ind = find(family == unique_families(ii));
            FamMethod = method(ind(1));
            disp(['ii = ' num2str(ii) ' Family method = ' num2str(FamMethod)])
            if FamMethod == 0 % worst of worst
                % for the new method we must pick Fgrav from the seed that gave the worst loads in the family
                [val,ix] = max( Fk_v(ind) );
                Fk_up(ii,1) = GravityCorrection_LoadEval(val,Fgrav_v(ix),PLF,PLFmin);
            elseif FamMethod == 1 % mean of max
                Fk_up(ii,1) = GravityCorrection_LoadEval(mean(Fk_v(ind)),mean(Fgrav_v(ind)),PLF,PLFmin); % extract safety factors corresponding to family weighted Fk and Fgrav
            elseif FamMethod == 2 % mean of worst half
                [val,ix] = sort(MaxLoad,'descend');
                ix = ix(1:end/2);   % indices of worst half
                Fk_up(ii,1) = GravityCorrection_LoadEval(mean(Fk_v(ix)),mean(Fgrav_v(ix)),PLF,PLFmin); % extract safety factors corresponding to family weighted Fk and Fgrav
            end
        end
    else
        Fk_up = GravityCorrection_LoadEval(Fk_v,Fgrav_v,PLF,PLFmin); % extract safety factors corresponding to family weighted Fk and Fgrav
    end

%------------- END OF CODE --------------
	
end

function Fk_up = GravityCorrection_LoadEval(Fk_v,Fg_v,PLF,PLFmin)
% GravityCorrection_LoadEval - Correct characteristic load for with gravity PLF
%
% Syntax:  [output1,output2] = GravityCorrection_LoadEval(Fk_v,Fg_v,PLF)
%
% Inputs:
%    Fk_v 		- Main load sensor (1D array)
%    Fg_v 		- Contemporaneous gravity load (1D array)
%    PLF		- Partial Load Factor for XXXXX
%
% Outputs:
%    Fk_up 		- Gravity Correction main load sensor (1D array)
%
% Example: 
%    TBD
%    TBD
%    TBD
%
% Author: IVSON, Ivan Sønderby
% Oct. 2019; Last revision: 16-Oct-2019

%------------- BEGIN CODE --------------

    nr = length(Fk_v);
    Fk_up = zeros(nr,1);
    theta = PLF-PLFmin;
    
    for i = 1:nr
        Fk = Fk_v(i); Fg = Fg_v(i);
        if Fg*Fk >= 0 % then Fg is unfavorable
            if abs(Fg) <= abs(Fk)
                eta = 1 - abs(Fg)/abs(Fk);
            else
                eta = 0;
            end
            gamma_r=PLFmin+theta*eta^2;
            Fk_up(i,1) = (gamma_r/PLF)*Fk;					
        else % then Fg is favorable
            Fk_up(i,1) = (1/PLF)*(PLF*Fk);
        end
    end
    
%------------- END OF CODE --------------	
	
end
