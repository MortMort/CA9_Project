% test ConvertVTSTurbBoxesTest
%
% JOSOW 2021

%% Test 1 - Conversion completes successfully
% Filename of test turbulence box
filename = string('16204001');
% VTS turbulences boxes for test conversion
vts_path = '\\dkrkbfile01\flex\ToolsDevelopment\HAWC2\VTSTurbulenceConversion\LMT-Test\VTS\';
% Convert VTS turbulence box
ok = LAC.hawc2.turb.convertfromvts(filename, filename, vts_path, '.');
assert(ok == 1);

%% Test 2 - Test dimensionality and values match reference
% Filename of test turbulence box
filename = string('16204001');
% VTS turbulences boxes for test conversion
vts_path = '\\dkrkbfile01\flex\ToolsDevelopment\HAWC2\VTSTurbulenceConversion\LMT-Test\VTS\';
% Wind
Vnav = 4;
Ti = 0.14;

% Test U
vts_comp = join([vts_path filename 'u.int'], '');
hwc_comp = join(['./' filename 'u.bin'], '');
turb_vts = LAC.hawc2.turb.turbread_vts(vts_comp, Vnav, Ti);
turb_hwc = LAC.hawc2.turb.turbread_hwc(hwc_comp, Vnav, Ti, ...
    turb_vts.NST, turb_vts.NAT, turb_vts.N2T+1);
assert(turb_vts.NST == size(turb_hwc, 3));
assert(turb_vts.NAT == size(turb_hwc, 2));
assert(turb_vts.N2T == size(turb_hwc, 1) - 1);
rel_error = max(abs(turb_vts.dat(:) - turb_hwc(:))) / mean(abs(turb_vts.dat(:)));
assert(rel_error < 1e-6);

% Test V
vts_comp = join([vts_path filename 'v.int'], '');
hwc_comp = join(['./' filename 'v.bin'], '');
turb_vts = LAC.hawc2.turb.turbread_vts(vts_comp, 4, 0.14);
turb_hwc = LAC.hawc2.turb.turbread_hwc(hwc_comp, 4, 0.14, ...
    turb_vts.NST, turb_vts.NAT, turb_vts.N2T+1);
assert(turb_vts.NST == size(turb_hwc, 3));
assert(turb_vts.NAT == size(turb_hwc, 2));
assert(turb_vts.N2T == size(turb_hwc, 1) - 1);
rel_error = max(abs(turb_vts.dat(:) - turb_hwc(:))) / mean(abs(turb_vts.dat(:)));
assert(rel_error < 1e-6);

% Test W
vts_comp = join([vts_path filename 'w.int'], '');
hwc_comp = join(['./' filename 'w.bin'], '');
turb_vts = LAC.hawc2.turb.turbread_vts(vts_comp, 4, 0.14);
turb_hwc = LAC.hawc2.turb.turbread_hwc(hwc_comp, 4, 0.14, ...
    turb_vts.NST, turb_vts.NAT, turb_vts.N2T+1);
assert(turb_vts.NST == size(turb_hwc, 3));
assert(turb_vts.NAT == size(turb_hwc, 2));
assert(turb_vts.N2T == size(turb_hwc, 1) - 1);
rel_error = max(abs(turb_vts.dat(:) - turb_hwc(:))) / mean(abs(turb_vts.dat(:)));
assert(rel_error < 1e-6);

%% Test 3 - Check converted HAWC2 box matches reference
% Reference (correct) HAWC2 boxes converted from VTS
hawc2_gold = '\\dkrkbfile01\flex\ToolsDevelopment\HAWC2\VTSTurbulenceConversion\LMT-Test\HAWC2_Gold\';
% Turbulence box dimensions
filename = string('16204001'); % Filename 
NST = 22; % Box Z dimension
NAT = 22; % Box Y dimension
N2T = 4096; % Box X dimension
Vnav = 4;
Ti = 0.14;

% Test U
box1 = join(['./' filename 'u.bin'], '');
box2 = join([hawc2_gold filename 'u.bin'], '');
hwc_1 = LAC.hawc2.turb.turbread_hwc(box1, Vnav, Ti, NST, NAT, N2T+1);
hwc_2 = LAC.hawc2.turb.turbread_hwc(box2, Vnav, Ti, NST, NAT, N2T+1);
assert(isequal(hwc_1, hwc_2));

% Test V
box1 = join(['./' filename 'v.bin'], '');
box2 = join([hawc2_gold filename 'v.bin'], '');
hwc_1 = LAC.hawc2.turb.turbread_hwc(box1, Vnav, Ti, NST, NAT, N2T+1);
hwc_2 = LAC.hawc2.turb.turbread_hwc(box2, Vnav, Ti, NST, NAT, N2T+1);
assert(isequal(hwc_1, hwc_2));

% Test W
box1 = join(['./' filename 'w.bin'], '');
box2 = join([hawc2_gold filename 'w.bin'], '');
hwc_1 = LAC.hawc2.turb.turbread_hwc(box1, Vnav, Ti, NST, NAT, N2T+1);
hwc_2 = LAC.hawc2.turb.turbread_hwc(box2, Vnav, Ti, NST, NAT, N2T+1);
assert(isequal(hwc_1, hwc_2));
