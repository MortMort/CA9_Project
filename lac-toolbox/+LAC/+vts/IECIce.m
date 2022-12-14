function mfac=IECIce(path_BLD_part_file,type)
% This program calculates the mass factor to add on DLC 12Ic (fat and ext)
% Inputs are:
% - a path to a blade part file
% - type: either 'fatigue' or 'extreme'
% Output is mfac to add on the DLC 12Vic
% Created by BRIJO (based on an existing copy)
%% Reading input
Bld=LAC.vts.convert(path_BLD_part_file, 'BLD');
if strcmp(type,'fatigue')==1
    ice_factor=1; %
elseif strcmp(type,'extreme')==1
    ice_factor=2;
else
    disp('Error in input, must be either fatigue or extreme')
end

S = length(Bld.SectionTable.R);
%S05 = find(Bld.SectionTable.R>=(Bld.SectionTable.R(end)/2),1);

b = zeros(S,1);     % length between 2 radial positions
rm = zeros(S,1);    % radius
b(1) = (Bld.SectionTable.R(2)-Bld.SectionTable.R(1))*0.5;
rm(1) = Bld.SectionTable.R(1)+0.5*b(1);
b(S) = (Bld.SectionTable.R(S)-Bld.SectionTable.R(S-1))*0.5;
rm(S) = Bld.SectionTable.R(S)-0.5*b(S);
for i = 2:S-1
    b(i) = (Bld.SectionTable.R(i)-Bld.SectionTable.R(i-1))*0.5+(Bld.SectionTable.R(i+1)-Bld.SectionTable.R(i))*0.5;
    rm(i) = (Bld.SectionTable.R(i)-(Bld.SectionTable.R(i)-Bld.SectionTable.R(i-1))*0.5+Bld.SectionTable.R(i)+(Bld.SectionTable.R(i+1)-Bld.SectionTable.R(i))*0.5)*0.5;
end

%% Calculation of IEC ice mass
A = 0.125; % according to IEC ed.4 Annex L
R = Bld.SectionTable.R(end); % Rotor radius
R85 = 0.85 * R; % 85% rotor radius
C85 = interp1(Bld.SectionTable.R(), Bld.SectionTable.C(), R85); % 85% chord

m_ice = A * C85 * Bld.SectionTable.R * ice_factor; % [kg/m]
M_ice = m_ice.*b; % [kg]
Mom_ice = M_ice.*rm; % [kg-m]

Bld_sect_mass = Bld.SectionTable.m.*b; % [kg]
Bld_sect_mom = Bld_sect_mass.*rm; % [kg-m]
Icebld_sect_mom = Bld_sect_mom + Mom_ice; % [kg-m] static moment of blade with ice

Bld_static_mom = sum(Bld_sect_mom);
Icebld_static_mom = sum(Icebld_sect_mom);

mfac = Icebld_static_mom/Bld_static_mom;



%% Plots
% plot(rm,Mf)
% xlabel('Radius [m]')
% ylabel('Mass [kg]')
