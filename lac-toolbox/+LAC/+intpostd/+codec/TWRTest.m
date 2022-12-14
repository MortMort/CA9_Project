classdef TWRTest < matlab.unittest.TestCase
    methods(Test)
        function testOldTWRcontentUnchanged(testCase)  % Test fails
            currentPath = fileparts(mfilename('fullpath'));
            load(fullfile(currentPath,'TWRoldCodec.mat'));
            for i = 1:length(TWR)
                actualTWR(i) = LAC.intpostd.convert(TWR(i).filename);
                TWRproperties=properties(TWR);
                for j = 1:length(TWRproperties)
                    if ~contains(TWRproperties{j},{'filename','Date','Type','sectionName','decodeSections','EquivalentTowerMoment',...
                                                   'ExtremeTowerMomentExclPLF','ExtremeTowerMomentInclPLF','MomentDueToTowerOutOfVerticalExclPlf'...
                                                   'SLSLoads','LateralForeAftFatigueLoadsAndRatio'})
                        testCase.assertEqual(isequaln(actualTWR(i).(TWRproperties{j}),TWR(i).(TWRproperties{j})),true,...
                            sprintf('%s property in TWR codec for filename %s is not as expected',TWRproperties{j},TWR(i).filename))
                    end
                end
            end
        end
    end
end