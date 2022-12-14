function [ ok ] = turbwrite_hwc( turb, outfile )
%TURBWRITE_HWC Write turbulence box in HAWC2 format.
%
% Write turbulence box data in HAWC2 binary format.
%
% Arguments:
%  - turb : turbulence data as a 3D array [X, Y, Z].
%  - outfile : filename of the data to be written.
%
% Returns:
%  - ok : 1 if data successfully written, otherwise 0.
%
% JUXAV/JOSOW 2021
    fid = fopen(outfile, 'w');
    tdat = flip(flip(turb, 2), 3); 
    tdatflat = reshape(permute(tdat, [3, 2, 1]), [], 1); 
    count = fwrite(fid, tdatflat, 'single');
    fclose(fid);

    % Confirm that correct amount of data was written to disk.
    if count == size(turb(:))
        ok = 1;
    else
        ok = 0;
    end
end

