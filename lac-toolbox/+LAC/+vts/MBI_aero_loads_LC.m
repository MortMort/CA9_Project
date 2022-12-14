function MBI_aero_loads_LC(path, Wsp, alpha, n_seed)

% MBI_aero_loads_LC - Creates DLC's for calculating aero loads for MBI.
% Creates DLC's for calculating aero loading on blades while handled using
% the MBI (blade gripper).
%
% Syntax:   MBI_aero_loads_LC(path, Wsp, alpha, n_seed)
%
% Inputs:
%  path -   Where the output text file containing the DLC's should be
%           saved.
%  Wsp -    Vector of wind speeds that should be investigated (remember to
%           include 5 m/s safety in accordance with IEC 61400-1 ed. 3 -
%           sec. 7.4.8).
%  alpha -  Vector of inflow angles to calculate for in degrees.
%  n_seed - Number of seeds to run for each wind speed - inflow angle
%           combination.
%
% Example:
%    MBI_aero_loads_LC('h:\3MW\MK3\V1053450.072\IEC1A\', [10, 15, 20, 25], [-25:25, 155:205], 6)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% December 2016; Last revision: 07-June-2017

fid = fopen([path, 'MBI_AeroLoad_LC.txt'], 'w');  	% open text file for writing DLC's
for i = 1:length(Wsp)                             	% start looping on wind speeds
    fprintf(fid, '*** #%d Wind speed = %.0f m/s\r\n\r\n', i, Wsp(i));
                                                    % write header for each wind speed
    for j = 1:length(alpha)                     	% start looping on inflow angles
        pit = -alpha(j) + 90;                       % calculate pitch angle corresponding to inflow angle
        div = floor(pit/360);                       % calculate whole divisor with 360
        pit = pit - div*360;                        % correct pitch angle to be within the interval [0,360]
        if n_seed == 1                              % check if only 1 seed is selected
            seed = sprintf('%d', randi(6));         % pick random seed number (1 - 6)
        else
            seed = sprintf('1 - %d', n_seed);       % use seed "1 - n" if more than 1 seed is selected (where n is number of seeds)
        end
        fprintf(fid, 'MBI_AeroLoads_Wsp%02d_Inflow%03d\r\n', Wsp(i), abs(alpha(j)));
                                                    % write load case name to text file
        fprintf(fid, 'ntm %s Freq 0 LF 1.5\r\n', seed);
                                                    % write seed, fatigue and PLF data to text file
        fprintf(fid, '0 0 %.1f 0 slope -6 drtdyn 0 0 0 0 1 vexp 0 pitch0 9999 90.0 %.2f 90.0 azim0 30 gravity 0 profdat STANDSTILL\r\n\r\n', Wsp(i), pit);
                                                    % write load case specifications to text file (i.e. pitch angle, wind shear, inflow etc.)
    end
end
fclose(fid);                                        % close text file