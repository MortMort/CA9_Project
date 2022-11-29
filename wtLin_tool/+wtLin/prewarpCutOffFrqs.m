function [num_bs_d_final, den_bs_d_final, num_bs, den_bs, err] = ...
    prewarpCutOffFrqs(fc, bw, Ts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% definition of standard outputs %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
err = uint8(0);
num_bs_d_final = [0 0 0 0 0];
den_bs_d_final = [1 0 0 0 0];

%%%%%%%%%%
% params %
%%%%%%%%%%
minDiv =  1e-10;

%%%%%%%%%%%%%%%%
% Check inputs %
%%%%%%%%%%%%%%%%
% do not allow negative centre frequencies or bandwidths
if fc <= 0 || bw <= 0
    err = uint8(1);
    return;
end
% check if upper and lower cut-off frequencies violate limits 
if fc + bw/2 >= 0.95*1/Ts/2 || fc - bw/2 <= 0.01*1/Ts/2
    err = uint8(2);
    return;
end

%%%%%%%%%%%%%%%%%%%%%
% Preprocess inputs %
%%%%%%%%%%%%%%%%%%%%%
% get cut-off frequencies in rad/sec
fhi = fc*2*pi + bw*pi;
flo = fc*2*pi - bw*pi;

% normalise frequencies (index 'n')
maxFrq = 1/Ts*pi; % Nyquist freq in rad/sec
if maxFrq <= minDiv
    err = uint8(3);
    return;
end
fhi_n = fhi/maxFrq;
flo_n = flo/maxFrq;

% filter calculation
% 2nd order prototype
num_lp = 1;
den_lp = [1 sqrt(2) 1]; 

% prewarp cut-off frequencies in normalised setup (index 'p')
Tsp = 0.5; % new sampling time for normalised setup
bwdth_np = 2/Tsp*tan([flo_n fhi_n]*2*pi*Tsp/2); % prewarp cut-off frequencies

% centre frequency based on prewarped cut-off frequencies
om_np = sqrt(bwdth_np(1)*bwdth_np(2));

% calculate continous time parameters
b = (bwdth_np(2)-bwdth_np(1))/om_np; 
a1 = den_lp(2);
num_bs = [1/om_np^4 0 2/om_np^2 0 1];
den_bs = [1/om_np^4 a1*b/om_np^3 (b^2+2*1)/om_np^2 a1*b/om_np  1];
if abs(den_bs(1)) <= minDiv
    err = uint8(4);
    return;
end
num_bs = num_bs/den_bs(1);
den_bs = den_bs/den_bs(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% transformation to discrete time using bilinear trafo %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% introduce dummies
b4 = num_bs(1);
b3 = num_bs(2);
b2 = num_bs(3);
b1 = num_bs(4);
b0 = num_bs(5);
a4 = den_bs(1);
a3 = den_bs(2);
a2 = den_bs(3);
a1 = den_bs(4);
a0 = den_bs(5);

% discretised parameters
bd4 = (16*b4 + 4*b2*Tsp^2 + b0*Tsp^4);
bd3 = (-64*b4 + 4*b0*Tsp^4);
bd2 = (96*b4 - 8*b2*Tsp^2 + 6*b0*Tsp^4);
bd1 = (-64*b4 + 4*b0*Tsp^4);
bd0 = (16*b4 + 4*b2*Tsp^2 + b0*Tsp^4);
ad4 = (4*a2*Tsp^2 + 2*a1*Tsp^3 + 16*a4 + 8*a3*Tsp + a0*Tsp^4);
ad3 = (4*a0*Tsp^4 + 4*a1*Tsp^3 - 64*a4 - 16*a3*Tsp);
ad2 = (6*a0*Tsp^4 - 8*a2*Tsp^2 + 96*a4);
ad1 = (-4*a1*Tsp^3 + 4*a0*Tsp^4 + 16*a3*Tsp - 64*a4);
ad0 = (16*a4 - 2*a1*Tsp^3 + a0*Tsp^4 - 8*a3*Tsp + 4*a2*Tsp^2);

% parameter vectors
num_bs_d = [bd4 bd3 bd2 bd1 bd0];
den_bs_d = [ad4 ad3 ad2 ad1 ad0];

% correct dcgain
sumDen = sum(den_bs_d);
if abs(sumDen) <= minDiv
    err = uint8(5);
    return;
end
k = sum(num_bs_d)/sumDen; % correction for own result
if abs(k) <= minDiv
    err = uint8(6);
    return;
end

%%%%%%%%%%%%%%%%%%
% Output results %
%%%%%%%%%%%%%%%%%%
num_bs_d_final = 1/k*num_bs_d;
den_bs_d_final = den_bs_d;