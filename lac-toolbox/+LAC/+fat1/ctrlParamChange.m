function ctrlParamChange(paramchangefile,paramfile)

ctrchange = LAC.fat1.convert(paramchangefile,'CTRCHG');

auxfile = LAC.vts.convert(paramfile);
copyfile(paramfile,[paramfile '.bk']);
for iPar = 1:length(ctrchange.parameters)
    [par,val,idx]=auxfile.getParameter(ctrchange.parameters{iPar});
    auxfile.setParameter(ctrchange.parameters{iPar},ctrchange.values(iPar));
    auxfile.units{idx} = ['; %changed by ctrlParamChange, orgVal = ',num2str(val)];
%     [a,b]=auxfile.getParameter(ctrchange.parameters{iPar});
end
auxfile.encode(paramfile)