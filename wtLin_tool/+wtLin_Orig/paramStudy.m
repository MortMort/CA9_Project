function [pp,cc,gg,hh] = paramStudy(gp,op,param,defStudy,stdSysPlots,cnctSys,userSys)
% -------------------------------
% function :
% [pp,cc,gg,hh] = paramStudy(op,gp,param,defStudy,stdPlots,cnctSys,userSys)
% Inputs:
% - gp : wtLin gp structure
% - op : wtLin op structure
% Notice: param study on lp-parameters is not supported by this function
% - param : cell with params {'<name>',number,"gain or abs value";..}
% ex: param = {'op.s.env.wind',12,0; 'op.s.env.wind',14,0};
% - detStudy : matrix (0/1's), rows are studies, columns are params.
% ex: defStudy = [1 0; 1 1]; study 1 use param 1; study 2 use param 1 and 2
% - stdSysPlots : Plot standard systems (i.e. gg-systems, not hh-systems)
% - cnctSys : New system definition. Call with [] if not used.
% ex: wRef2w closed loop: 
% cnctSys(1).comps = 'c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,userSys{1}';
% cnctSys(1).in = 'wRef'; cnctSys(1).out = 'w'; 
% - userSys : Needed system defs for making cnctSys
% ex: userSys{1} = sumblk('e','wRef','w','+-');
% Outputs:
% pp : cell with linear parameters for each study, ex. study 2: pp{2,1}
% cc : cell with components for each study, ex. study 2: cc{2,1}
% gg : cell with standard systems for each study, ex. study 2: gg{2,1}
% hh : cell with user def systems for each study, ex. study 2: hh{2,1}
% 
% JSTHO, 28/12 2016
% -------------------------------

[NStudies,NParams] = size(defStudy);
NSys = length(cnctSys);

% Save default values
for ii = 1:NParams
    %
    if startsWith(param{ii,1},'lp.')
        disp('lp parameters cannot be used...')
    end
    %
    eval(['default.' param{ii,1} '=' param{ii,1} ';']);
end

pp = cell(NStudies,1);
cc = cell(NStudies,1); 
gg = cell(NStudies,1);
hh = cell(NStudies,1);

% Studies
for jj = 1:NStudies
    for ii = 1:NParams
        %
        if defStudy(jj,ii) == 1
            if param{ii,3} > 0.5
                % gain method
                ev1 = [param{ii,1} '=' num2str(param{ii,2}) '*' param{ii,1} ';'];
                eval(ev1);
            else
                % abs value method
                ev0 = [param{ii,1} '=' num2str(param{ii,2}) ';'];
                eval(ev0);
            end
            % 
        end
    end
    %
    %------ Setup ----------------
    lp=wtLin.linparms.calcParms(gp,op); % Get linear parameters
    comp=wtLin.comps.calcComps(lp); % Get components (linear systems)
    loop=wtLin.loops.calcLoops(comp); % Get pre-defined loops
    c=comp.s; % Components can be called with c.Name
    cc{jj,1}=c;
    gg{jj,1}=loop.s; % Loops can be called with g.Name
    pp{jj,1}=lp.s;
    %
    if ~isempty(cnctSys)
    w = warning; warning('off'); 
    try
    for kk = 1:NSys
        cnctSysIn = cnctSys(kk).in; cnctSysOut = cnctSys(kk).out;
        sEval = ['connect(' cnctSys(kk).comps ',cnctSysIn,cnctSysOut)'];
        hh{jj,kk} = eval(sEval);
    end
    warning(w); % Enable warnings
    catch
        warning(w); % Enable warnings
    end
    end
    %-----------------------------
    %
    % Recover default parameter values
    for ii = 1:NParams
        eval([param{ii,1} '= default.' param{ii,1} ';']);
    end
    %
    disp(['Study ' num2str(jj) ' processed'])
end




%%
P = bodeoptions;
P.FreqUnits = 'Hz';
P.PhaseMatching = 'on';
plotCol = {'b','r','g','k','m','c','y'};
nn = 0;

% setup legend names
sStudy = {'Study1','Study2','Study3','Study4','Study5','Study6','Study7'};
sLegend = 'sStudy{1,1}';
for jj = 2:NStudies
    s = ['sStudy{1,' num2str(jj) '}'];
    sLegend = [sLegend ','  s];
end
sEvalLegend = ['legend(' sLegend  ')'];



% Pre-calculated loops
if stdSysPlots == 1

nn = nn+1; figure(nn);
for jj = 1:NStudies
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        bode(gg{jj,1}.FLC_CL_wRef2w,plotCol{jj},P)
    else
        bode(gg{jj,1}.PLC_CL_wRef2w,plotCol{jj},P)
    end
    hold on
end
grid on
title('Closed Loop Bode (CL wRef2w)')
eval(sEvalLegend)


nn = nn+1; figure(nn);
for jj = 1:NStudies
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        bode(gg{jj,1}.FLC_CL_wRef2w_nT,plotCol{jj},P)
    else
        bode(gg{jj,1}.PLC_CL_wRef2w_nT,plotCol{jj},P)
    end
    hold on
end
grid on
title('Closed Loop Bode (CL wRef2w No Tower)')
eval(sEvalLegend)


nn = nn+1; figure(nn);
for jj = 1:NStudies
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        step(gg{jj,1}.FLC_CL_wRef2w,plotCol{jj})
    else
        step(gg{jj,1}.PLC_CL_wRef2w,plotCol{jj})
    end
    hold on
end
grid on
title('Closed Loop Step (CL wRef2w)')
eval(sEvalLegend)


nn = nn+1; figure(nn);
for jj = 1:NStudies
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        bode(gg{jj,1}.FLC_OL_e2w,plotCol{jj},P)
    else
        bode(gg{jj,1}.PLC_OL_e2w,plotCol{jj},P)
    end
    hold on
end
grid on
title('Open Loop Bode (OL e2w)')
eval(sEvalLegend)


nn = nn+1; figure(nn);
for jj = 1:NStudies
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        rlocus(gg{jj,1}.FLC_OL_e2w)
    else
        rlocus(gg{jj,1}.PLC_OL_e2w)
    end
    hold on
end
title('Root Locus (OL e2w)')    
eval(sEvalLegend)

end % makePlots






