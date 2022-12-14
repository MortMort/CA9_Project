function mfac=DibtIce(path_BLD_part_file,type)
% This program calculates the mass factor to add on DLC 12Ic (fat and ext)
% Inputs are:
% - a path to a blade part file
% - type: either 'fatigue' or 'extreme'
% Output is mfac to add on the DLC 12Vic
% Created by BRIJO (based on an existing copy)
%% Reading input
Bld=LAC.vts.convert(path_BLD_part_file, 'BLD');
if strcmp(type,'fatigue')==1
    ice_factor=0.5; % DIBT 2004 section 8.6.1
elseif strcmp(type,'extreme')==1
    ice_factor=1;
else
    disp('Error in input, must be either fatigue or extreme')
end

S = length(Bld.SectionTable.R);
S05 = find(Bld.SectionTable.R>=(Bld.SectionTable.R(end)/2),1);

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

%% Calculation of DIBT ice mass
ice_density = 700; % according to DIBt 1993 section 6.7
R = Bld.SectionTable.R(end);
tw = max(Bld.SectionTable.C);
% ts is the chord at the tip, found by linearly fitting between max chord and tip
max_C_ref=find(Bld.SectionTable.C==tw);
P=polyfit(Bld.SectionTable.R(max_C_ref:end),Bld.SectionTable.C(max_C_ref:end),1);
ts=P(1)*R+P(2);
%ts = Bld.SectionTable.C(find(Bld.SectionTable.R>=(Bld.SectionTable.R(end)-1),1)); % chord 1m from tip

theta = ts/tw;
CE = 0.3*exp(-0.32*R)+0.00675;
m_ice = (CE*theta*(1+theta)*ice_density*tw^2)*ice_factor;

Ice_mass_dibt(1:S,1) = m_ice;
Ice_gradient=m_ice/Bld.SectionTable.R(S05);
for i = 1:S05
    Ice_mass_dibt(i,1) = Ice_gradient*rm(i);
end
m_dibt = Bld.SectionTable.m+Ice_mass_dibt(:,1); % [kg/m]
M_DIBT = m_dibt.*b; % [kg]
BS_DIBt = sum(M_DIBT.*rm);

%% Calculation of ice factors
error=1;
tmp_low=1;
tmp_high=1.5;
mfac=(tmp_high+tmp_low)/2;

while abs(error)>0.001   
    mf = Bld.SectionTable.m.*mfac;
    Mf = mf.*b; % [kg]
    BS_VTS = sum(Mf.*rm);
    error = BS_VTS-BS_DIBt;
    if abs(error)<0.001
        break
    elseif error<0
        tmp_low=mfac;
        mfac=(tmp_high+tmp_low)/2;
    else
        tmp_high=mfac;
        mfac=(tmp_high+tmp_low)/2;
    end
end

%% Plots
% plot(rm,Mf)
% xlabel('Radius [m]')
% ylabel('Mass [kg]')
