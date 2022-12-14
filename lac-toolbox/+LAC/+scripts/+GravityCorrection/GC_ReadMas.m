function [MAS] = GC_ReadMas(masfile)
% GC_ReadMas - Helper function for extracting only blade info needed to perform the
% gravity correction of moment loads.
%
% Syntax:  [MAS] = GC_ReadMas(masfilename)
%
% Inputs:
%    masfile	      - Absolute path to master file
%
% Outputs:
%    MAS             - Structure with desired information
%
% Example: 
%    TBD
%
% Author: GUOVI
% Oct. 2019; Last revision: 10-11-2019

    masObj = LAC.vts.convert(masfile);
    MAS.blade  = [masObj.bld.Radius';
                  masObj.bld.m';
                  masObj.bld.PhiOut'];
    MAS.secno  = length(masObj.bld.Radius);
    MAS.nblade = masObj.rot.NumBlades;
    MAS.coning = masObj.rot.Gamma;
    MAS.tilt   = masObj.rot.Tilt;
end
