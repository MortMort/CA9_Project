%% Test for LAC.vsc.VSCquantiles2xls
% NIWJO 2021
clear
outputpath = 'w:\ToolsDevelopment\VSC\SupportFiles\';
SegmentData = {
    'DE' ,{'w:\ToolsDevelopment\VSC\SupportFiles\LoadsDE.txt'};
    'SE',{'w:\ToolsDevelopment\VSC\SupportFiles\LoadsSE.txt'};
    };
try
    LAC.vsc.VSCquantiles2xls(SegmentData,outputpath);
    delete('w:\ToolsDevelopment\VSC\SupportFiles\VSCquantiles _DE_SE.xls');
catch
    delete('w:\ToolsDevelopment\VSC\SupportFiles\VSCquantiles _DE_SE.xls');
    error('Test of LAC.vsc.VSCquantiles2xls failed')
end
