function MinPLF = GC_CalculateMinFactor(OrigLoad,GCLoad,CorrectionFactor)
% GC_CALCULATEMINFACTOR - Calculates the minimum limit to gravity corrected PLF based on how much DLC13 loads must be increased to match DLC11 loads.
% See http://wiki.tsw.vestas.net/display/LACWIKI/Guideline+for+using+gravity+correction+during+load+extrapolation
%
% Syntax:  MinPLF = GC_CalculateMinFactor(OrigLoad,GCLoad,CorrectionFactor)
%
% Inputs:
%    OrigLoad			- 
%    GCLoad			- 
%    CorrectionFactor	- 
%
% Outputs:
%    MinPLF			- 
%
% Example: 
%    TBD
%
% Author: GUOVI
% Nov. 2019; Last revision: 12-11-2019

    ORIGPLF   = 1.35; % origianl PLF from DLC1.3
    GCMINPLF  = 1.1;  % Minimum PLF for full effect of gravity correction (GCLoad is
                      % supposed to reflect this)   
    
    gc_plf = GCLoad/(OrigLoad/ORIGPLF);
    phi2   = (gc_plf-GCMINPLF)/(ORIGPLF-GCMINPLF);
    MinPLF = (gc_plf*CorrectionFactor-ORIGPLF*phi2)/(1-phi2);

end
