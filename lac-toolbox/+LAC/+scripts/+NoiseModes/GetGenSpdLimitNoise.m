function [ws_pc, gspd_lim] = GetGenSpdLimitNoise(noise_lim, noise_params, pc_file, gear_ratio, gen_speed, AoA)
% Function to get the maximum generator speed values that fullfil the noise limits (based on a baseline tuning)
%
% This script is based on the assumption that vTip is the major contributor for noise (LwA) and pitch/AoA will not change significantly from baseline
% More info can be found in the Noise Modes Guideline (0073-8946.V03), section 6.3
% 
% SYNTAX:
% 	[ws_pc, gspd_lim] = LAC.scripts.NoiseModes.GetGenSpdLimitNoise(noise_lim, noise_params, pc_file, gear_ratio, gen_speed, AoA)
%
% INPUTS:
% 	noise_lim - Noise limit [dB] 
% 	noise_params - Struct with noise equation parameters (only dual linear approach implemented): A1, B1, C1, A2, B2, C2, Cconst, D, Dref, AoA
% 		(ex: noise_params.A1 = -0.254; noise_params.B1 = 55.631; etc.)
% 	pc_file - Baseline power curve file, preliminary / from an initial tuning, to use as reference for AoA values 
% 		(ex: '..\PC\Normal\Rho1.225\pc_(...).txt')
% 	gear_ratio - Gearbox ratio
% 	gen_speed - Range of generator speed to evaluate, optional (gen_speed = min_val : step : max_val)
% 	AoA - Vector containing range of AoA values to evaluate, optional (AoA = min_val : step : max_val)
%
% OUTPUTS:
% 	ws_pc - Vector with wind speed values (x-axis)
% 	gsp_lim - Vector with generator speed values (y-axis)
%	Plots of noise limit boundary and maximum geneator speed values as a function of wind speed
%
% VERSIONS:
% 	2021/09/04 - AAMES: V00

%% Get noise equation and AoA names to read PC data
% get noise eq name
fid = fopen(pc_file,'r');
pc_txt_data = textscan(fid,'%s','Delimiter','\n'); 
pc_txt_data = pc_txt_data{1,1};
fclose(fid);
ind_neq = find(strcmp(pc_txt_data,'#NOISE_EQS'));
ind_name = ind_neq + 5;
neq_data = strsplit(pc_txt_data{ind_name});
neq_name = matlab.lang.makeValidName(neq_data{1});
% get AoA valid name
section = ['#NOISE_' neq_data{1}];
ind_aoa_nm = find(strcmp(pc_txt_data,section)) + 3;
aoa_nm_data = strsplit(pc_txt_data{ind_aoa_nm});
aoa_name = matlab.lang.makeValidName(aoa_nm_data{end});

%% Read pc file and get WS, AoA and GenSpd
pc_data = LAC.pc.ReadPCFile(pc_file);
ws_pc = pc_data.RPM.Wind;
rpm_pc = pc_data.RPM.RPM;
aoa_pc = pc_data.(neq_name).(aoa_name);

%% Define AoA and GenSpd ranges if not defined
if ~exist('gen_speed','var')
    step = 1;
    min_rpm_pc = min(rpm_pc);
    max_rpm_pc = max(rpm_pc);
    gen_speed = min_rpm_pc - 40 : step : max_rpm_pc + 40;
end
if ~exist('AoA','var')
    step = 0.1;
    min_aoa_pc = min(aoa_pc);
    max_aoa_pc = max(aoa_pc);
    AoA = min_aoa_pc - 5 : step : max_aoa_pc + 5;
end

%% Noise equation parameters
A1 = noise_params.A1; 
B1 = noise_params.B1;
C1 = noise_params.C1;
A2 = noise_params.A2;
B2 = noise_params.B2;
C2 = noise_params.C2;
Cconst = noise_params.Cconst;
D = noise_params.D;
Dref = noise_params.Dref;
AoA0 = noise_params.AoA0;

%% Calculate noise
Lwa = zeros(length(gen_speed),length(AoA));
for n = 1:length(gen_speed) 
    vTip = ((pi/30)*gen_speed(n))*(1/gear_ratio)*(D/2); % vtip at nom gen speed
    % Equations
    for k = 1:length(AoA)
        if AoA(k) <= AoA0
            Lwa(n,k) = 10 * log10( 10^((A1*AoA(k)+B1*log10(vTip)+C1)/10) + 10^(Cconst/10) ) + 10 * log10(D/Dref);
        else
            Lwa(n,k) = 10 * log10( 10^((A2*AoA(k)+B2*log10(vTip)+C2)/10) + 10^(Cconst/10) ) + 10 * log10(D/Dref);
        end
    end
end

%% Get boundary and plot
LwaOk = Lwa<=noise_lim;
ind=1;
for g=1:length(gen_speed)
    for a=1:length(AoA)
        if LwaOk(g,a)
            gspd_bound(ind) = gen_speed(g);
            aoa_bound(ind) = AoA(a);
            ind=ind+1;
        end
    end
end
LwA_boundary = boundary(aoa_bound',gspd_bound');

figure('Name','LwA evaluation')
[x,y] = meshgrid(AoA,gen_speed);
subplot(1,2,1)
pc = pcolor(x,y,Lwa);
set(pc,'EdgeColor','None')
ylabel('GenSpd [rpm]')
xlabel('AoA [deg]')
colorbar
hold on
plot(aoa_bound(LwA_boundary),gspd_bound(LwA_boundary),'r','LineWidth',2)
subplot(1,2,2)
plot(ws_pc,aoa_pc,'-o','LineWidth',1.2)
grid on
xlabel('WS [m/s]')
ylabel('AoA [deg]')

%% Get Max RPM for each WS (based on AoA from baseline pc)
gspd_lim = zeros(length(ws_pc),1);
for ws = 1:length(ws_pc)
    aoa = aoa_pc(ws);
    gspds = gspd_bound(abs(aoa_bound-aoa)<0.001);
    gspd_lim(ws) = max(gspds);
end

figure('Name','Max GenSpd')
plot(ws_pc, gspd_lim, '-*', 'linewidth', 1.2)
grid on
xlabel('WS [m/s]')
ylabel('GenSpd [rpm]')

end
