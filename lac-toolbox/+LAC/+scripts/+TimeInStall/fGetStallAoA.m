function [LS] = fGetStallAoA(LS,Setup,Outputs)
    
    if nargin <3
        Outputs.StallPoint = 1;
    end

    if ~exist([LS.Path,'INT\sensor'],'file')
        disp(['ERROR: no sensor file in ',LS.Path,'INT.']);
    end
    [C] = LAC.vts.convert([LS.Path,'INT\sensor'],'SENSOR');
    
    Index_Vhub = find(contains(C.name,'Vhub'));
    LS.idxVhub   = Index_Vhub(1);
    
    % Check for Vhfree or add error
    
    masfiles = dir([LS.Path,'INPUTS\*.mas']);
    if length(masfiles)>1
        fprintf('More than one master file, please choose correct one: \n')
            for imas=1:length(masFiles)
                list{imas} = sprintf('%s, ',masfiles(imas).name);
            end
        [indx_mas,~] = listdlg('ListString',list);
    else
        indx_mas = 1;
    end
    
    frqfiles = dir([LS.Path,'INPUTS\*.frq']);
   
    if length(frqfiles)>1
        fprintf('More than one frequency file, please choose correct one: \n')
            for imas=1:length(masFiles)
                list{imas} = sprintf('%s, ',frqfiles(imas).name);
            end
        [indx_frq,~] = listdlg('ListString',list);
    else
        indx_frq = 1;
    end
    
    LS.mas = LAC.vts.convert([LS.Path,'INPUTS\',masfiles(indx_mas).name]); %getmsd();
    
    LS.frqfile = frqfiles(indx_frq).name;
    
    idx.AoA = strfind(C.name,Setup.AoASensor);
    idx.AoAexclude = strfind(C.name,[Setup.AoASensor '87%']);
    
    idxAoAsensor = find(~cellfun(@isempty,idx.AoA));
    idxAoAsensorexclude = intersect(find(~cellfun(@isempty,idx.AoA)),find(~cellfun(@isempty,idx.AoAexclude)));
    
    LS.idxAoA = idxAoAsensor(idxAoAsensor~=idxAoAsensorexclude);
    
    % Get radius position of each AoA output
    n=1;
    for i=1:length(LS.idxAoA)
        tmp = char(C.name(LS.idxAoA(i)));
        if tmp(end)~='%'
            Section(n) = str2num(tmp(5:end));
            LS.Radius(n) =  LS.mas.bld.Radius(Section(n));
            n=n+1;
        end
    end
    
    if length(LS.Radius)<length(LS.mas.bld.Radius)
        disp(['WARNING: AoA is not output at all sections in ',LS.Path,'. The program will run and interpolate. But it is recommended to rerun VTS with aoa output at allsections.']);
    end
    
    % Diameter of given turbine
    LS.Diameter = LS.mas.bld.Radius(end)*2;
    
    % Read profile data
    LS.pro_dat = LAC.vts.convert(LS.mas.pro.default);
    
    % Get stall AoA for tc
    switch LS.StallMethod
        case 'auto'
            for i_tc = 1:length(LS.pro_dat.Thickness)
                %LS.Section(i_Section).tc = max(min(LS.mas.bld.Thickness(i_Section),max(LS.mas.pro.Thickness)),min(LS.mas.pro.Thickness)); % T/C of given section, bounded by min and max T/C in polar file.
                
                % Get profiles
                LS.TC(i_tc).Polar.aoa = LS.pro_dat.alpha;
                LS.TC(i_tc).Polar.cl = LS.pro_dat.cL(:,i_tc);
                LS.TC(i_tc).Polar.cd = LS.pro_dat.cD(:,i_tc);
                LS.TC(i_tc).Polar.cm = LS.pro_dat.cM(:,i_tc);
                
                % Find AoA at zero lift (assumed to be between -30 and +30 degrees)
                idx_AoAm30 = find(LS.TC(i_tc).Polar.aoa < -30);
                idx_AoAm30 = idx_AoAm30(end);
                idx_AoAp30 = find(LS.TC(i_tc).Polar.aoa > 30);
                idx_AoAp30 = idx_AoAp30(1);
                if LS.TC(i_tc).Polar.cl(idx_AoAm30) < 0 && LS.TC(i_tc).Polar.cl(idx_AoAp30)
                    j = idx_AoAm30;
                    while LS.TC(i_tc).Polar.cl(j)<0
                        j = j+1;
                    end
                    idx_AoA0 = j;
                    
                    % Find <0 stall AoA
                    LS.TCnveStall.idx_AoA(i_tc) = idx_AoA0;
                    
                    gradient = 1;
                    
                    while gradient > LS.gradientStallLimit
                        AoA_step_diff =  (LS.TC(i_tc).Polar.aoa(LS.TCnveStall.idx_AoA(i_tc)-1) - LS.TC(i_tc).Polar.aoa(LS.TCnveStall.idx_AoA(i_tc)));
                        Cl_step_diff = (LS.TC(i_tc).Polar.cl(LS.TCnveStall.idx_AoA(i_tc)-1) - LS.TC(i_tc).Polar.cl(LS.TCnveStall.idx_AoA(i_tc)));
                        gradient = Cl_step_diff /  AoA_step_diff;
                        LS.TCnveStall.idx_AoA(i_tc) = LS.TCnveStall.idx_AoA(i_tc) -1;
                    end
                    
                    LS.TCnveStall.AoA(i_tc) = LS.TC(i_tc).Polar.aoa(LS.TCnveStall.idx_AoA(i_tc)+1);
                    LS.TCnveStall.cl(i_tc) = LS.TC(i_tc).Polar.cl(LS.TCnveStall.idx_AoA(i_tc)+1);
                    LS.TCnveStall.cd(i_tc) = LS.TC(i_tc).Polar.cd(LS.TCnveStall.idx_AoA(i_tc)+1);
                    LS.TCnveStall.cm(i_tc) = LS.TC(i_tc).Polar.cm(LS.TCnveStall.idx_AoA(i_tc)+1);
                    
                    % Find >0 stall AoA
                    LS.TCpveStall.idx_AoA(i_tc) = idx_AoA0;
                    
                    gradient = 1;
                   
                    while gradient > LS.gradientStallLimit
                        AoA_step_diff =  (LS.TC(i_tc).Polar.aoa(LS.TCpveStall.idx_AoA(i_tc)+1) - LS.TC(i_tc).Polar.aoa(LS.TCpveStall.idx_AoA(i_tc)));
                        Cl_step_diff = (LS.TC(i_tc).Polar.cl(LS.TCpveStall.idx_AoA(i_tc)+1) - LS.TC(i_tc).Polar.cl(LS.TCpveStall.idx_AoA(i_tc)));
                        gradient = Cl_step_diff /  AoA_step_diff;
                        LS.TCpveStall.idx_AoA(i_tc) = LS.TCpveStall.idx_AoA(i_tc) +1;
                    end
                                  
                    LS.TCpveStall.AoA(i_tc) = LS.TC(i_tc).Polar.aoa(LS.TCpveStall.idx_AoA(i_tc)-1);
                    LS.TCpveStall.cl(i_tc) = LS.TC(i_tc).Polar.cl(LS.TCpveStall.idx_AoA(i_tc)-1);
                    LS.TCpveStall.cd(i_tc) = LS.TC(i_tc).Polar.cd(LS.TCpveStall.idx_AoA(i_tc)-1);
                    LS.TCpveStall.cm(i_tc) = LS.TC(i_tc).Polar.cm(LS.TCpveStall.idx_AoA(i_tc)-1);
                    
                    if (Outputs.StallPoint)
                        figure('name',['Cl & Cd stall points - TC ' num2str(LS.pro_dat.Thickness(i_tc))])
                        plot(LS.TC(i_tc).Polar.aoa,LS.TC(i_tc).Polar.cl)
                        hold on;
                        plot(LS.TC(i_tc).Polar.aoa,LS.TC(i_tc).Polar.cd)
                        plot(LS.TCpveStall.AoA(i_tc),LS.TCpveStall.cl(i_tc),'v')
                        plot(LS.TCnveStall.AoA(i_tc),LS.TCnveStall.cl(i_tc),'^')
                        xlabel('AoA [deg]')
                        ylabel('Cl,Cd [-]')
                        xlim([-30 30]);
                        grid on;
                        
                        labelstrPos = sprintf('Positive stall AoA: %.2f', LS.TCpveStall.AoA(i_tc));
                        text(-29, 0.7, labelstrPos);
                        
                        labelstrNeg = sprintf('Negative stall AoA: %.2f', LS.TCnveStall.AoA(i_tc));
                        text(-29, 0.5, labelstrNeg);
                        
                        SaveFileNameFig=[LS.OutPutFolder,'\StallPoint_TC_',num2str(LS.pro_dat.Thickness(i_tc)),'.jpg'];
                        saveas(gcf,SaveFileNameFig)
                    end
                    
                else % for 100% profile
                    LS.TCnveStall.idx_AoA(i_tc) = NaN; % Temporarily makes it a NaN. Will be overwritten later
                    LS.TCpveStall.idx_AoA(i_tc) = NaN; % Temporarily makes it a NaN. Will be overwritten later
                end
                clear idx_AoA0 idx_AoAm30 idx_AoAp30
                close all; 
            end
            % For 100% T/C sections, nve and pve stall are taken from first
            % section where it was possible to get +ve and -ve stall AoA.
            for i_tc = 1:length(LS.pro_dat.cL(1,:))
                if ~isnan(LS.TCnveStall.idx_AoA(i_tc))
                    idx_AoA_TCnveStall = LS.TCnveStall.idx_AoA(i_tc);
                    idx_AoA_pveStall = LS.TCpveStall.idx_AoA(i_tc);
                else
                    LS.TCnveStall.idx_AoA(i_tc) = idx_AoA_TCnveStall;
                    LS.TCpveStall.idx_AoA(i_tc) = idx_AoA_pveStall;
                    LS.TCnveStall.AoA(i_tc) = LS.TC(i_tc).Polar.aoa(LS.TCnveStall.idx_AoA(i_tc));
                    LS.TCnveStall.cl(i_tc) = LS.TC(i_tc).Polar.cl(LS.TCnveStall.idx_AoA(i_tc));
                    LS.TCnveStall.cd(i_tc) = LS.TC(i_tc).Polar.cd(LS.TCnveStall.idx_AoA(i_tc));
                    LS.TCnveStall.cm(i_tc) = LS.TC(i_tc).Polar.cm(LS.TCnveStall.idx_AoA(i_tc));
                    LS.TCpveStall.AoA(i_tc) = LS.TC(i_tc).Polar.aoa(LS.TCpveStall.idx_AoA(i_tc));
                    LS.TCpveStall.cl(i_tc) = LS.TC(i_tc).Polar.cl(LS.TCpveStall.idx_AoA(i_tc));
                    LS.TCpveStall.cd(i_tc) = LS.TC(i_tc).Polar.cd(LS.TCpveStall.idx_AoA(i_tc));
                    LS.TCpveStall.cm(i_tc) = LS.TC(i_tc).Polar.cm(LS.TCpveStall.idx_AoA(i_tc));
                end
            end
            
            % interpolate Stall AoA for all sections
            for i_Section = 1:length(LS.mas.bld.Radius)
                % Thickness ratio of the given section, bounded by min and
                % max TR defined in polar files
                LS.Section(i_Section).tc = max(min(LS.mas.bld.Thickness(i_Section),max(LS.pro_dat.Thickness)),min(LS.pro_dat.Thickness)); % T/C of given section, bounded by min and max T/C in polar file.

                LS.Section(i_Section).Polar.aoa = LS.pro_dat.alpha;
                LS.Section(i_Section).Polar.cl = interp1(LS.pro_dat.Thickness,LS.pro_dat.cL',LS.Section(i_Section).tc);
                LS.Section(i_Section).Polar.cd = interp1(LS.pro_dat.Thickness,LS.pro_dat.cD',LS.Section(i_Section).tc);
                LS.Section(i_Section).Polar.cm = interp1(LS.pro_dat.Thickness,LS.pro_dat.cM',LS.Section(i_Section).tc);
            end
            
            for i_Section = 1:length(LS.mas.bld.Radius)
                % Thickness ratio of the given section, bounded by min and
                % max TR defined in LS.StallTR
                tcbounded = LS.mas.bld.Thickness(i_Section); 
      
                LS.nveStall.AoA(i_Section) = interp1(LS.pro_dat.Thickness,LS.TCnveStall.AoA,tcbounded);
                LS.nveStall.cl(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cl,LS.nveStall.AoA(i_Section));
                LS.nveStall.cd(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cd,LS.nveStall.AoA(i_Section));
                LS.nveStall.cm(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cm,LS.nveStall.AoA(i_Section));

                LS.pveStall.AoA(i_Section) = interp1(LS.pro_dat.Thickness,LS.TCpveStall.AoA,tcbounded);
                LS.pveStall.cl(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cl,LS.pveStall.AoA(i_Section));
                LS.pveStall.cd(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cd,LS.pveStall.AoA(i_Section));
                LS.pveStall.cm(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cm,LS.pveStall.AoA(i_Section));
            end
            
            
            
            
        case 'inpTR'
            % Check if there are TR in polar files for which Stall AoA are
            % not input in LS{i}.StallTR
            for i_TR = 1:length(LS.pro_dat.Thickness)
                idx = find(LS.StallTR == LS.pro_dat.Thickness(i_TR));
                switch length(idx)
                    case 0
                        disp(['WARNING: stall AoA for T/C=',num2str(LS.pro_dat.Thickness(i_TR)),' not defined in LS{i}.StallTR']);
                    case 1
                    otherwise
                        disp(['ERROR: stall AoA for T/C=',num2str(LS.pro_dat.Thickness(i_TR)),' defined several times in LS{i}.StallTR. Can''t proceed further.']);
                        return;
                end
            end
            
            % Check if there are TR in LS{i}.StallTR which are not defined in polar files
            for i_TR = 1:length(LS.StallTR)
                idx = find(LS.StallTR(i_TR) == LS.pro_dat.Thickness);
                if isempty(idx)
                    disp(['WARNING: stall AoA for T/C=',num2str(LS.StallTR(i_TR)),' defined in LS{i}.StallTR but not in the polar files.',...
                        ' Stall AoA will be interpolated in between the values defined in LS{i}.StallTR. Extrpolation will be ']);
                end
            end
            
            % interpolate Stall AoA for all sections
            for i_Section = 1:length(LS.mas.bld.Radius)
                % Thickness ratio of the given section, bounded by min and
                % max TR defined in polar files
                LS.Section(i_Section).tc = max(min(LS.mas.bld.Thickness(i_Section),max(LS.pro_dat.Thickness)),min(LS.pro_dat.Thickness)); % T/C of given section, bounded by min and max T/C in polar file.

                LS.Section(i_Section).Polar.aoa = LS.mas.pro.alpha;
                LS.Section(i_Section).Polar.cl = interp1(LS.pro_datThickness,LS.mas.pro.cL',LS.Section(i_Section).tc);
                LS.Section(i_Section).Polar.cd = interp1(LS.pro_dat.Thickness,LS.pro_dat.cD',LS.Section(i_Section).tc);
                LS.Section(i_Section).Polar.cm = interp1(LS.pro_dat.Thickness,LS.pro_dat.cM',LS.Section(i_Section).tc);
            end
            
            for i_Section = 1:length(LS.mas.bld.Radius)
                % Thickness ratio of the given section, bounded by min and
                % max TR defined in LS.StallTR
                tcbounded = max(min(LS.mas.bld.Thickness(i_Section),max(LS.StallTR)),min(LS.StallTR)); 
      
                LS.nveStall.AoA(i_Section) = interp1(LS.StallTR,LS.NveStallAoA,tcbounded);
                LS.nveStall.cl(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cl,LS.nveStall.AoA(i_Section));
                LS.nveStall.cd(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cd,LS.nveStall.AoA(i_Section));
                LS.nveStall.cm(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cm,LS.nveStall.AoA(i_Section));

                LS.pveStall.AoA(i_Section) = interp1(LS.StallTR,LS.PveStallAoA,tcbounded);
                LS.pveStall.cl(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cl,LS.pveStall.AoA(i_Section));
                LS.pveStall.cd(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cd,LS.pveStall.AoA(i_Section));
                LS.pveStall.cm(i_Section) = interp1(LS.Section(i_Section).Polar.aoa,LS.Section(i_Section).Polar.cm,LS.pveStall.AoA(i_Section));
            end
        otherwise
            disp(['ERROR: method for deriving stall AoA not correct for simulations ',LS.Path,'. It should be either ''auto'' or ''inpTR''']);
            return;
    end
    
    if Setup.Plot
        
        
    end
    
    
end