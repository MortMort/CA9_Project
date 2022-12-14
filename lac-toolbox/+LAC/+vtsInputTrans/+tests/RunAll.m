% Simple wrapper to locally run all the tests for the vtsInputTrans scripts
% NIWJO 2021
clc; clear all; close all;
testsList = {
       'LAC.vtsInputTrans.tests.YAWtest'
       'LAC.vtsInputTrans.tests.PITtest'
       'LAC.vtsInputTrans.tests.NACtest'
       'LAC.vtsInputTrans.tests.HUBtest'
       'LAC.vtsInputTrans.tests.GENtest'
       'LAC.vtsInputTrans.tests.DRTtest'
       'LAC.vtsInputTrans.tests.CNVtest'
       'LAC.vtsInputTrans.tests.BRKtest'
       'LAC.vtsInputTrans.tests.BLDbbtest'
       'LAC.vtsInputTrans.tests.VRBtest'
};

for i = 1:length(testsList)
    disp(['Running ' testsList{i}]);
    eval(testsList{i});
end