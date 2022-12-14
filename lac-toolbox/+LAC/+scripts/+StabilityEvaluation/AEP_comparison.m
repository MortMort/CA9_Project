baseline = LAC.vts.stapost('h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter00_Stability_of_Reference_Blade\PC\Rho1.225\');baseline.read;
X1 = LAC.vts.stapost('h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter11_X1\PC\Rho1.225\');X1.read;
X2 = LAC.vts.stapost('h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter12_X2\PC\Rho1.225\');X2.read;


WS=4:0.5:20;
for iLC = 1:length(WS)
    
    LC{iLC} = sprintf('94_Rho1.225_Vhfree_%s_',num2str(WS(iLC)));

    
    
    
end
baseline_P = baseline.getLoad('P','mean',LC);
X1_P = X1.getLoad('P','mean',LC);
X2_P = X2.getLoad('P','mean',LC);

LAC.climate.aep(X2_P,WS,6.5,2)/LAC.climate.aep(baseline_P ,WS,6.5,2)
LAC.climate.aep(X1_P,WS,6.5,2)/LAC.climate.aep(baseline_P ,WS,6.5,2)

LAC.figure
plot(WS,baseline_P,'*b');hold on; grid on;
plot(WS,X1_P,'*r'); 
plot(WS,X2_P,'*g'); 

xlabel('Wind Speed [m/s]'); ylabel('Power [kW]');
legend('Baseline','X1','X2')