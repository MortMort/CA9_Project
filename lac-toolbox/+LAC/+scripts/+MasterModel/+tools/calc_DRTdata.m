
function [DRTdata,VLDs] = calc_DRTdata(MAINpath,sen,useVLDcodec)
VLDs = {};
%% Using intpostD DRT codec to read VLD proxies
if useVLDcodec == true
    [filepath,~,~] = fileparts(MAINpath);
    postload = filepath(1:(end-4));
    path = [postload 'DRT\DRTload.txt'];

    DRT = LAC.intpostd.convert(path,'DRT');

    fn = fieldnames(DRT.VLD);
    for c = 1:length(fn)
        for p = 1:numel(DRT.VLD.(fn{c}))
            if strcmp(string(lower(fn{c})),'torque_ranges')
                VLDs{end+1,1} = [DRT.VLD.(fn{c})(p).sensor '_' fn{c} ' ' DRT.VLD.(fn{c})(p).type];
            else
                VLDs{end+1,1} = [DRT.VLD.(fn{c})(p).sensor '_' fn{c} ' ' DRT.VLD.(fn{c})(p).type ' m' num2str(DRT.VLD.(fn{c})(p).m) ' Neq' num2str(DRT.VLD.(fn{c})(p).neq,'%G')];
            end
        end
    end

    DRTdata=...
        [DRT.VLD.gears.value,...
        DRT.VLD.bearings.value,...
        DRT.VLD.torque_ranges.value,...
        DRT.VLD.shafts.value,...
        DRT.VLD.structural_elems.value]';

%% Legacy methodology (using LMT proxy scripts)
% Computes the DRT proxies, based on functions extracted from VLD.
else
    [filepath,~,~] = fileparts(MAINpath);
    path=filepath(1:(end-4));

    % ... examples 
    % MyMBr_rev='h:\Vidar\LoadReleases\L10\L10.4\Loads_V150\V150_LTq_5.00_DIBt_HH125.0_VAS_STE__25y_T967D00\Loads\Postloads\LDD\0054_MyMBr_rev.ldd';
    % MrMB_rev='h:\Vidar\LoadReleases\L10\L10.4\Loads_V150\V150_LTq_5.00_DIBt_HH125.0_VAS_STE__25y_T967D00\Loads\Postloads\LDD\0679_MrMB_rev.ldd';
    % MyMBr_mko='h:\Vidar\LoadReleases\L10\L10.4\Loads_V150\V150_LTq_5.00_DIBt_HH125.0_VAS_STE__25y_T967D00\Loads\Postloads\MARKOV\0054_MyMBr.mko';
    % MyMBr_rfo='h:\Vidar\LoadReleases\L10\L10.4\Loads_V150\V150_LTq_5.00_DIBt_HH125.0_VAS_STE__25y_T967D00\Loads\Postloads\RAIN\0054_MyMBr.rfo';

    % Path to MyMBr LRD - assumes standard location
    MyMBr_rev = dir([path 'LDD\*_My' sen 'r_rev.ldd']);
    if isempty(MyMBr_rev)
        errordlg(['The are no My' sen 'r_rev.ldd files in the folder ', path,'.Please run IntPostD in the folder and configure My' sen 'r sensor to output LRD results']);
    end
    if length(MyMBr_rev)>1
        errordlg(['The are more than one My' sen 'r_rev.ldd file in the folder ', path,'.Please remove all except the one which has the required data']);
    end
    MyMBr_revPath=[MyMBr_rev.folder filesep MyMBr_rev.name];

    % Path to MrMB LRD - assumes standard location
    MrMB_rev = dir([path 'LDD\*_Mr' sen '_rev.ldd']);
    if isempty(MrMB_rev)
        errordlg(['The are no Mr' sen '_rev.ldd files in the folder ', path,'.Please run IntPostD in the folder and configure Mr' sen ' sensor to output LRD results']);
    end
    if length(MrMB_rev)>1
        errordlg(['The are more than one Mr' sen '_rev.ldd file in the folder ', path,'.Please remove all except the one which has the required data']);
    end
    MrMB_revPath=[MrMB_rev.folder filesep MrMB_rev.name];

    % Path to MyMBr MARKOV - assumes standard location
    MyMBr_mko = dir([path 'MARKOV\*_My' sen 'r.mko']);
    if isempty(MyMBr_mko)
        errordlg(['The are no My' sen 'r.mko files in the folder ', path,'.Please run IntPostD in the folder and configure My' sen 'r sensor to output MARKOV results']);
    end
    if length(MyMBr_mko)>1
        errordlg(['The are more than one My' sen 'r.mko file in the folder ', path,'.Please remove all except the one which has the required data']);
    end
    MyMBr_mkoPath=[MyMBr_mko.folder filesep MyMBr_mko.name];

    % Path to MyMBr RAIN - assumes standard location
    MyMBr_rfo = dir([path 'RAIN\*_My' sen 'r.rfo']);
    if isempty(MyMBr_rfo)
        errordlg(['The are no My' sen 'r.rfo files in the folder ', path,'.Please run IntPostD in the folder and configure My' sen 'r sensor to output RAIN results']);
    end
    if length(MyMBr_rfo)>1
        errordlg(['The are more than one My' sen 'r.rfo file in the folder ', path,'.Please remove all except the one which has the required data']);
    end
    MyMBr_rfoPath=[MyMBr_rfo.folder filesep MyMBr_rfo.name];

    %% Calculation of DRT proxies
    % Gbx and bearing
    [Teq_gbx,~,MrMB,~]=LAC.scripts.MasterModel.misc.vld.gear_calc(MyMBr_revPath,MrMB_revPath);
    %Struct
    p    =[4 7 7 9 9 11 11];
    Nref =[5e6 1e3 2e6 1e3 2e6 1e3 2e6];
    [Teq_struct,amplitudeModified,n]=LAC.scripts.MasterModel.misc.vld.struct_elem_calc(MyMBr_mkoPath,p,Nref,0);
    %Shaft
    [Teq_shaft,MyMBr,n]=LAC.scripts.MasterModel.misc.vld.shaft_calc(MyMBr_rfoPath,0);

    % MyMBr_LRD_max
    reader  = LAC.scripts.MasterModel.misc.postloads();
    fid     = fopen(MyMBr_revPath);
    tmpLRD  = reader.decode(fid);
    Tmax    = tmpLRD.spectrum(1,1);
    fclose(fid);

    DRTdata=...
        [Teq_gbx.gear(1);... 
        Teq_gbx.gear(2);...
        Teq_gbx.gear(3);...
        Teq_gbx.gear(4);...
        Teq_gbx.gear(7);...
        Teq_gbx.bear(1);...
        Teq_gbx.gear(3);...
        Tmax;...
        Teq_shaft.shaft(1);...
        Teq_shaft.shaft(2);...
        Teq_shaft.shaft(3);...
        Teq_struct.fat(1);...
        Teq_struct.fat(2);...
        Teq_struct.fat(3);...
        Teq_struct.fat(4);...
        Teq_struct.fat(5);...
        Teq_struct.fat(6);...
        Teq_struct.fat(7);...
        ];
end
end




