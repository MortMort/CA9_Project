classdef MasterModelTest < matlab.unittest.TestCase
    properties (Access=private)
        sensorlist
        solutions
    end

    methods (TestMethodSetup)       
       function getTestParameters(testCase)
           pathlist = 'w:\ToolsDevelopment\MasterModel\tests\Pathlist.txt';

           [overview,exactpath] = LAC.scripts.MasterModel.tools.PathInfo(pathlist);    

           [loadData, testCase.sensorlist] = LAC.scripts.MasterModel.tools.get_data_DRT_TWR(exactpath.path(overview.Availability),'MB',0,true);

           applyUnitTest = true;
           testCase.solutions = LAC.scripts.MasterModel.choose_turbines_glpk(loadData,0.01,false,applyUnitTest);           
       end
    end

    methods(Test)
        function verifyAlgorithm(testCase)
                load('w:\ToolsDevelopment\MasterModel\tests\MM_solutions.mat','Solution')
                expec.selection = Solution.choices;

                testCase.verifyEqual(testCase.solutions.choices,expec.selection,...
                'verifyAlgorithm did not obtain the correct master models using the algorithm in choose_turbines_glpk.m.')
        end

        function verifySensorList(testCase)
            load('w:\ToolsDevelopment\MasterModel\tests\MM_sensors.mat','sensors')
            expec.sensors = sensors;

             for i = 1:numel(testCase.sensorlist)
                testCase.assertEqual(testCase.sensorlist(i),expec.sensors(i),...
                    'expected sensors not found.');
             end
        end
    end
end
