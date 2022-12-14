function ok = convertfromvts(inputfilename, outputfilename, inputdirectory, outputdirectory)
%convertfromvts
%
% inputfilename - Input (VTS) turbulence box filename (without u/v/w suffix)
% outputfilename - The output filename (without u/v/w suffix)
% inputdirectory - Location of VTS turbulence boxes
%
% JUXAV/JOSOW 2021

    vtsu = join([inputdirectory inputfilename 'u.int'], ''); % INT file for wind in U direction 
    vtsv = join([inputdirectory inputfilename 'v.int'], ''); % INT file for wind in V direction
    vtsw = join([inputdirectory inputfilename 'w.int'], ''); % INT file for wind in W direction

    % Files names of corresponding HAWC2 files
    hwcu = strjoin([outputdirectory '/' outputfilename 'u.bin'], '');
    hwcv = strjoin([outputdirectory '/' outputfilename 'v.bin'], '');
    hwcw = strjoin([outputdirectory '/' outputfilename 'w.bin'], '');

    % Convert each component
    convertBoxComponent(vtsu, hwcu);
    convertBoxComponent(vtsv, hwcv);
    convertBoxComponent(vtsw, hwcw);

    % Done
    ok = 1;
end

function convertBoxComponent(infile, outfile)
%convertBoxComponent
%
% Convert a single turbulence box component.
%
% Assume a mean wind speed of 1m/s and a TI of 1.00 since the 
% aeroelastic simulation tools will rescale anyway.
    turb = LAC.hawc2.turb.turbread_vts(infile, 1, 1); 
    ok = LAC.hawc2.turb.turbwrite_hwc(turb.dat, outfile);
end
