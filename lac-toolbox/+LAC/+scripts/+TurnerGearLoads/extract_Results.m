clear; clc; close all

input_paths = {'h:\Feasibility\Projects\011_Mk3E_V155_4.5MW\BladeIterations\V163_4.5MW_A13_S13\3_Investigations\TurnerGear_SBI\TG_Study\TGL_19+5ms\19+5ms\ExtremeTurnerGearLoadsPostProcessed.mat', ...
               'h:\Feasibility\Projects\011_Mk3E_V155_4.5MW\BladeIterations\V163_4.5MW_A13_S13\3_Investigations\TurnerGear_SBI\TG_Study\TGL_19+5ms_GC\19+5ms\ExtremeTurnerGearLoadsPostProcessed.mat', ...
               'h:\Feasibility\Projects\011_Mk3E_V155_4.5MW\BladeIterations\V163_4.5MW_A13_S13\3_Investigations\TurnerGear_SBI\TG_Study\TGL_19+5ms_GC_11\19+5ms\ExtremeTurnerGearLoadsPostProcessed.mat'};

RF = 1.07;

for i = 1:length(input_paths)
    load(input_paths{i});
    
    BLDs_1 = max([abs(max([max(DataMaxBin(:,6)); max(DataMaxBin(:,7)); max(DataMaxBin(:,8))]));...
                  abs(min([min(DataMinBin(:,6)); min(DataMinBin(:,7)); min(DataMinBin(:,8))]))]);

    BLDs_2 = max([abs(max([max(DataMaxBin(:,3)); max(DataMaxBin(:,4)); max(DataMaxBin(:,5))]));
                  abs(min([min(DataMinBin(:,3)); min(DataMinBin(:,4)); min(DataMinBin(:,5))]))]);

    BLDs_3 = max([abs(max(DataMaxBin(:,9))); abs(min(DataMinBin(:,9)))]);

    Output_noPLF(:, i) = [BLDs_1 BLDs_2 BLDs_3]';

    BLDs_1 = max([abs(max([max(DataMaxBin_withPLF(:,6)); max(DataMaxBin_withPLF(:,7)); max(DataMaxBin_withPLF(:,8))]));...
                  abs(min([min(DataMinBin_withPLF(:,6)); min(DataMinBin_withPLF(:,7)); min(DataMinBin_withPLF(:,8))]))]);

    BLDs_2 = max([abs(max([max(DataMaxBin_withPLF(:,3)); max(DataMaxBin_withPLF(:,4)); max(DataMaxBin_withPLF(:,5))]));
                  abs(min([min(DataMinBin_withPLF(:,3)); min(DataMinBin_withPLF(:,4)); min(DataMinBin_withPLF(:,5))]))]);

    BLDs_3 = max([abs(max(DataMaxBin_withPLF(:,9))); abs(min(DataMinBin_withPLF(:,9)))]);

    Output_PLF(:, i) = [BLDs_1 BLDs_2 BLDs_3]' * RF;
end
