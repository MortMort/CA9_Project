%% Visualizing the Ct and Cp curves from tables extracted by wtLin


% Ct
Ct = gp.s.aero.ct;
Cp = gp.s.aero.cp;
theta = gp.s.aero.theta;
lambda = gp.s.aero.lambda;

omegaOp = lp.s.stat.genSpd * 1/gp.s.drt.gearRatio * 2*pi/60;
% Omega converted from RPM to rad/s to get correct lambda calculation
R = gp.s.rot.radius;
V0Op = 16;

lambdaOp = omegaOp*R/V0Op
thetaOp = lp.s.stat.pitch;



% Plotting Ct for all TSRs with varying theta:
myfig(1);
plot(theta, Ct)
xlabel('theta [deg]')
ylabel('C_T')
title('C_T curve for varying lambda plotted against theta')

% It almost looks like nomatter what the TSR is an increase in theta will
% yield a decrease in thrust, but around TSR = 5 there is an increase in
% stead of a decrease!

myfig(10);
plot(theta, Ct(:,2:11))
xlabel('theta [deg]')
ylabel('C_T')
title(sprintf('C_T curve for lambda = %.1f to lambda = %.1f plotted against theta', lambda(3), lambda(11)))


% Plotting Cp for all TSRs with varying theta:
myfig(2);
subplot(311)
plot(theta, Cp(:,1:ceil(length(lambda)*1/3)))
xlabel('theta [deg]')
ylabel('C_P')
title('C_P curve for varying lambda plotted against theta (first third)')
xlim([theta(1) 20])
subplot(312)
plot(theta, Cp(:,ceil(length(lambda)*1/3):ceil(length(lambda)*2/3)))
xlabel('theta [deg]')
ylabel('C_P')
title('C_P curve for varying lambda plotted against theta (second third)')
xlim([theta(1) 20])
subplot(313)
plot(theta, Cp(:,ceil(length(lambda)*2/3):end))
xlabel('theta [deg]')
ylabel('C_P')
title('C_P curve for varying lambda plotted against theta (third third)')
xlim([theta(1) 20])


% Plotting the Ct and Cp curves for the operating point of 16 m/s:


% By observing the lambda and theta arrays the corresponding indexes are
% used to find the curves at the operating point

% find the index of lambda value
lambdaIdx = find(lambda == round(lambdaOp*2)/2);

myfig(3);
subplot(211)
plot(theta, Ct(:,lambdaIdx))
title(sprintf('Ct vs. theta at operating point where TSR = %.2f with ...V_0 = %.1f [m/s] and Omega = %.2f [rad/s]',lambdaOp, V0Op, omegaOp))
grid on
xline(thetaOp)
subplot(212)
plot(theta, Cp(:,lambdaIdx))
title(sprintf('Cp vs. theta at operating point where TSR = %.2f with V_0 = %.1f [m/s] and Omega = %.2f [rad/s]',lambdaOp, V0Op, omegaOp))
grid on
xline(thetaOp)


%% Plotting Ct against TSR

% Plotting Ct for all thetas with varying TSR:
myfig(10);
plot(lambda, Ct')
xlabel('TSR')
ylabel('C_T')
title('C_T curve for varying theta plotted against TSR')

% find the index of theta value at op
thetaIdx = find(theta == round(thetaOp/2)*2);

% Plotting Ct for theta at OP with varying TSR:
myfig(11);
plot(lambda, Ct(thetaIdx,:)')
xline(lambdaOp)
xlabel('TSR')
ylabel('C_T')
title(sprintf('Ct vs. TSR at operating point where theta = %.2f with ...V_0 = %.1f [m/s] and Omega = %.2f [rad/s]',thetaOp, V0Op, omegaOp))


% Plotting Ct for theta at OP with varying V0:
V0 = omegaOp*R./lambda;
myfig(12);
plot(V0, Ct(thetaIdx,:)')
xline(V0Op)
xlabel('V0')
ylabel('C_T')
title(sprintf('Ct vs. V0 at operating point where theta = %.2f with ...V_0 = %.1f [m/s] and Omega = %.2f [rad/s]',thetaOp, V0Op, omegaOp))


% Plotting Ct for theta at OP with varying omega:
omega = V0Op*lambda/R;
myfig(13);
plot(omega, Ct(thetaIdx,:)')
xline(omegaOp)
xlabel('V0')
ylabel('omega')
title(sprintf('Ct vs. omega at operating point where theta = %.2f with ...V_0 = %.1f [m/s] and Omega = %.2f [rad/s]',thetaOp, V0Op, omegaOp))
