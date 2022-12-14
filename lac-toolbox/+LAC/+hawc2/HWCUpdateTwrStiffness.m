function HWCUpdateTwrStiffness(simulationpath,HWC,n)
%% This function modifies the tower.st file with the required Stiffness.
    twrFn = fullfile(simulationpath,'DATA','tower.st');
    twrst   = LAC.codec.CodecTXT(twrFn);

    m=find(ismember(HWC.Parameter(:,2),'Master'));
    twrst.searchAndReplace('2.1000E+011',sprintf('%0.5g',HWC.Parameter_Values(m,n)));
    twrst.save(twrFn); 
end
