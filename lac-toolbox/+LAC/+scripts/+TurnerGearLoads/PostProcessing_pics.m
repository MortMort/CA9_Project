output_folder = 'h:\MWOW\Investigations\399\_Pics_15mps\';
Label         = 'V236_15mps_';

%Figure 6: LSS torque Vs Rotor Position, when only one blade(B1) is installed
figure; scatter(DataMinBin(:,2),DataMinBin(:,3),'v');
hold on
scatter(DataMaxBin(:,2),DataMaxBin(:,3),'^');
title('Only 1 blade (B1) mounted without PLF');
xlabel('Rotor azimuth position [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,3));
MinVar = min(DataMinBin(:,3));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '1BLD_Razi.fig']);
saveas(gcf, [output_folder Label '1BLD_Razi.emf']);

%Figure 7: LSS torque Vs Wind direction, when only one blade(B1) is installed.
figure; scatter(DataMinBin(:,1),DataMinBin(:,3),'v');
hold on
scatter(DataMaxBin(:,1),DataMaxBin(:,3),'^');
title('Only 1 blade (B1) mounted without PLF');
xlabel('Wind direction [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,3));
MinVar = min(DataMinBin(:,3));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '1BLD_Wdir.fig']);
saveas(gcf, [output_folder Label '1BLD_Wdir.emf']);

%Figure 8: LSS torque Vs Rotor postion, when only two blades(B12) are installed.
figure; scatter(DataMinBin(:,2),DataMinBin(:,6),'v');
hold on
scatter(DataMaxBin(:,2),DataMaxBin(:,6),'^');
title('Two blades (B12) mounted without PLF');
xlabel('Rotor azimuth position [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,6));
MinVar = min(DataMinBin(:,6));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '2BLDs_Razi.fig']);
saveas(gcf, [output_folder Label '2BLDs_Razi.emf']);

%Figure 9: LSS torque Vs Wind direction, when only two blades (B12) are installed.
figure; scatter(DataMinBin(:,1),DataMinBin(:,6),'v');
hold on
scatter(DataMaxBin(:,1),DataMaxBin(:,6),'^');
title('Two blades (B12) mounted without PLF');
xlabel('Wind direction [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,6));
MinVar = min(DataMinBin(:,6));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '2BLDs_Wdir.fig']);
saveas(gcf, [output_folder Label '2BLDs_Wdir.emf']);

%Figure 10: LSS torque Vs Rotor position, when all are installed.
figure; scatter(DataMinBin(:,2),DataMinBin(:,9),'v');
hold on
scatter(DataMaxBin(:,2),DataMaxBin(:,9),'^');
title('All blades mounted without PLF');
xlabel('Rotor azimuth position [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,9));
MinVar = min(DataMinBin(:,9));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '3BLDs_Razi.fig']);
saveas(gcf, [output_folder Label '3BLDs_Razi.emf']);

%Figure 11: LSS torque Vs Wind direction, when all blades are installed.
figure; scatter(DataMinBin(:,1),DataMinBin(:,9),'v');
hold on
scatter(DataMaxBin(:,1),DataMaxBin(:,9),'^');
title('All blades mounted without PLF');
xlabel('Wind direction [deg]');
ylabel('LSS torque [kNm]');
xlim([0 360]);
xticks([0:30:360]);
MaxVar = max(DataMaxBin(:,9));
MinVar = min(DataMinBin(:,9));
MaxStr = strcat('Max = ', num2str(MaxVar,'%5.1f'));
MinStr = strcat('Min = ', num2str(MinVar,'%5.1f'));
legend(MinStr, MaxStr, 'Location', 'best');
saveas(gcf, [output_folder Label '3BLDs_Wdir.fig']);
saveas(gcf, [output_folder Label '3BLDs_Wdir.emf']);