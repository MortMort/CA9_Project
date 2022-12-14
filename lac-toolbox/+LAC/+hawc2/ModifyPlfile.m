function ModifyPlfile(rootfol,invfol)
%% This function modifies the _PL file to update the sensor configuration file
        plfile=dir(fullfile(rootfol,invfol,'PARTS\_PL\','*pl*'));
        plfl  =LAC.codec.CodecTXT(fullfile(plfile.folder,plfile.name));
        [lines,lineno] = plfl.search('USERconfig:');
        plfl.replaceLine(lineno+2,char(strrep(plfl.lines(lineno+2,lineno+2),'.txt','1.txt')));
        plfl.save(fullfile(plfile.folder,plfile.name));
end