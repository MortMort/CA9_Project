clear all
clc 

addpath('C:\repo\lac-matlab-toolbox')
addpath(genpath('C:\repo\lac-matlab-toolbox\External\'))

testCase = LAC.scripts.MasterModel.test.MasterModelTest;
results = testCase.run;