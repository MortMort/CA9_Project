
% testing script for new functionality in ReadPyroOutFile
% 210330 - PESEG

%% Test 1: Read old Danish aero/pyro format
V80_Out = LAC.pyro.ReadPyroOutFile('w:\ToolsDemo\LACMatlabToolbox\LMT-7840\testPyroFiles\v80.out');

assert(V80_Out.cpaeromax == 0.4824, 'LAC.pyro.ReadPyroOutFile Does not read optimum CP well for V80');
assert(V80_Out.TSRopt == 8.683, 'LAC.pyro.ReadPyroOutFile Does not read optimum TSR well for V80');
assert(V80_Out.Phiopt == -0.743, 'LAC.pyro.ReadPyroOutFile Does not read optimum pitch angle well for V80');
assert(V80_Out.AEP == 5459.652, 'LAC.pyro.ReadPyroOutFile Does not read AEP well for V80' );
assert(V80_Out.AoA_1(15,8) == 5.001, 'LAC.pyro.ReadPyroOutFile Does not read AoA table well for V80');
assert(V80_Out.CL_1(15,8) == 0.972, 'LAC.pyro.ReadPyroOutFile Does not read CL table well for V80');


%% Test 2: Read 2014 pyro format
V136_Out = LAC.pyro.ReadPyroOutFile('w:\ToolsDemo\LACMatlabToolbox\LMT-7840\testPyroFiles\V136-a65.out');

assert(V136_Out.cpaeromax == 0.4935, 'LAC.pyro.ReadPyroOutFile Does not read optimum CP well for V136');
assert(V136_Out.TSRopt == 9.236, 'LAC.pyro.ReadPyroOutFile Does not read optimum TSR well for V136');
assert(V136_Out.Phiopt == 2.955, 'LAC.pyro.ReadPyroOutFile Does not read optimum pitch angle well for V136');
assert(V136_Out.AEP == 14734.339, 'LAC.pyro.ReadPyroOutFile Does not read AEP well for V136' );
assert(V136_Out.AoA_1(20,10) == 4.912, 'LAC.pyro.ReadPyroOutFile Does not read AoA table well for V136');
assert(V136_Out.CL_1(20,10) == 0.996, 'LAC.pyro.ReadPyroOutFile Does not read CL table well for V136');

%% Test 3: Read 2020 pyro format
V144_Out = LAC.pyro.ReadPyroOutFile('w:\ToolsDemo\LACMatlabToolbox\LMT-7840\testPyroFiles\V144_A01_S01.out');

assert(V144_Out.cpaeromax == 0.4945, 'LAC.pyro.ReadPyroOutFile Does not read optimum CP well for V144');
assert(V144_Out.TSRopt == 9.486, 'LAC.pyro.ReadPyroOutFile Does not read optimum TSR well for V144');
assert(V144_Out.Phiopt == 3.352, 'LAC.pyro.ReadPyroOutFile Does not read optimum pitch angle well for V144');
assert(V144_Out.AEP == 15942.2, 'LAC.pyro.ReadPyroOutFile Does not read AEP well for V144' );
assert(V144_Out.AoA_1(20,10) == 5.971, 'LAC.pyro.ReadPyroOutFile Does not read AoA table well for V144');
assert(V144_Out.CL_1(20,10) == 1.148, 'LAC.pyro.ReadPyroOutFile Does not read CL table well for V144');
