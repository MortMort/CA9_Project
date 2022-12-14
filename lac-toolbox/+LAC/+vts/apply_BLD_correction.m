function apply_BLD_correction(BLD_path,rename,varargin)

% apply_BLD_correction - Applies blade corrections as specified in 0102-0849.
% Reads a BLD parts file and applies 10% increase in torsional stiffness as
% well as a 2.5% shift in shear center in accordance with LAC internal guidance
%
%   - 0-20% span: no shear center offset
%   - 20-40% span: shear center offset increase linearly to 5% of chord
%   - 40% span to tip: shear center offset by 5% of chord
%
% Script writes a new BLD parts file in the same folder as the input BLD
% parts file, but with "_corrected" appended to the filename. A note about
% the correction is furthermore added in the comments of the parts file
% with a timestamp.
%
% Syntax:   apply_BLD_correction(BLD_path)
%
% Inputs:
%   BLD_path - Path to BLD parts file used as input.
%   rename - optional: choose whether new parts should be renamed to ".._corrected".
%
% Example:
%    apply_BLD_correction('w:\USER\MIFAK\BLD_correction_matlab_script\V116_a47_18-2_l04_s26-1_FG18_VA36_new_prebend_update_hybrid_with_ste_prototype_extended_output_used.009')
%
% Other m-files required:   LAC.vts.convert()
%                           LAC.vts.codec.BLD()
% Subfunctions: none
% MAT-files required: none

%% Generate file name for new BLD parts file (i.e. with correction)
if nargin<2
rename = true;
end
[filepath, name, ext] = fileparts(BLD_path);
if rename
name_new = [name, '_corrected'];
else
name_new = name;
end

% optional inputs
p = inputParser;
addOptional(p,'CheckPiOff',true,@(x) islogical(x));
addOptional(p,'CheckGammaRootEdge',true,@(x) islogical(x));
addOptional(p,'CorrectTorsion',true,@(x) islogical(x));

parse(p,varargin{:});
CheckPiOff = p.Results.CheckPiOff;
CheckGammaRootEdge = p.Results.CheckGammaRootEdge;
CorrectTorsion = p.Results.CorrectTorsion;


%% Read BLD parts data and correct
BLD_dat = LAC.vts.convert(BLD_path, 'BLD');             % read BLD part file
BLD_dat.KTfac = [1.0, 1.0, 1.0];

if CorrectTorsion
    answer = questdlg(sprintf('The blade torsional stiffness correction is %1.1f.\n\nShould this be set to 1.1 in accordance with the shear centre correction approach (DMS 0102-0849)?',BLD_dat.KTfac(1)),'Change CorrectTorsion',...
    'Yes','No','Yes');
    if strcmp(answer,'Yes')
        BLD_dat.KTfac = [1.1, 1.1, 1.1];
        fprintf('KTfac set to to %1.1f\n',BLD_dat.KTfac(1));
    end
end

R = BLD_dat.SectionTable.R;
C = BLD_dat.SectionTable.C;
Xshc_org = BLD_dat.SectionTable.Xshc;
Xshc_cor = Xshc_org;
for iSec = 1:length(R)
    if R(iSec) < 0.2*R(end)
        % 0-20% span, no offset of Xshc
        Xshc_cor(iSec) = Xshc_org(iSec);
    elseif R(iSec) < 0.4*R(end)
        % 20-40% span: linear increase to 5% of chord offset
        Xshc_cor(iSec) = Xshc_org(iSec) + C(iSec)*0.025*(R(iSec) - 0.2*R(end))/(0.2*R(end));
    else
        % 40% span to tip: 5% of chord Xshc offset
        Xshc_cor(iSec) = Xshc_org(iSec) + C(iSec)*0.025;
    end
end
BLD_dat.SectionTable.Xshc = Xshc_cor;

if CheckGammaRootEdge
    answer = questdlg(sprintf('GammaRootEdge is %1.2f.\n\n0.1 degree should be added to the actual physical value to ensure conservatism (DMS 0080-7307).\n\nShould 0.1 degree be added?',BLD_dat.GammaRootEdge),'Change GammaRootEdge',...
    'Yes','No','Yes');
    if strcmp(answer,'Yes')
        BLD_dat.GammaRootEdge = BLD_dat.GammaRootEdge+0.1;
        fprintf('GammaRootEdge set to to %1.2f\n',BLD_dat.GammaRootEdge);
    end
end

if CheckPiOff
    if ~all(ismember([0.1 0 -0.1],round((BLD_dat.PiOff-mean(BLD_dat.PiOff))*1e2)*1e-2))
        answer = questdlg(sprintf('PiOff = [%1.2f %1.2f %1.2f].\n\nDo you want to set them to [0.1 0 -0.1] according to DMS 0080-7307 (CCI study)?',reshape(BLD_dat.PiOff,1,[])),'Change PiOff',...
                'Yes','No','Yes');
        if strcmp(answer,'Yes')
            BLD_dat.PiOff = [0.1 0 -0.1];
            fprintf('PiOff set to [%1.2f %1.2f %1.2f]\n',reshape(BLD_dat.PiOff,1,[]));
        end
    end
end

%% Add comment to the BLD parts file
BLD_dat.comments{end + 1} = '';
BLD_dat.comments{end + 1} = sprintf('%s - Torsional stiffness increased by 10%% and shear center corrected using "%s".', datestr(datetime('now'), 'yyyymmdd-HH:MM'), mfilename('fullpath'));
BLD_dat.comments{end + 1} = sprintf('%16s Changed by %s, original file: %s', '', getenv('USERNAME'), BLD_path);

%% Write corrected BLD parts file
BLD_dat.encode(fullfile(filepath, [name_new, ext]));