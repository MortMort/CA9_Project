function updatecallbacks(filename,old,new)
%UpdateCallBacks(figname,old,new)
%This function updates callbacks in a figure from old to new
%Example
%   LAC.UpdateCallBacks('distr.fig','SPV','LAC.SPV')
%   updates all callbacks in  distr.fig from package SPV to package LAC.SPV
[pth,nm,ext]=fileparts(filename);

if strcmp(ext,'.fig')

    pat=['@\(hObject,eventdata\)' old '(.*)'];
    repl=['@(hObject,eventdata)' new '$1'];

    h=open(filename);

    saveas(h,[nm '_orig' ext],'fig')

    updChildren(h,pat,repl);


    saveas(h,[filename],'fig');

    close(h)
    
elseif strcmp(ext,'.m')
    
    mFile = LAC.codec.CodecTXT(filename);
    mFile.save(fullfile(pth,[nm '_orig' ext]));
    
    mFile.searchAndReplace(old,new)
    mFile.save(filename);
    
    
end

end


function updChildren(h,pat,repl)

    %Recursive function to traverse all children
    k=get(h,'Children');
    if(~isempty(k))
        for l=1:length(k)
          updChildren(k(l),pat,repl);
        end
    end

    %Fix callbacks
    %Create mapable struct
    p=get(h);

    %pMap=p.asMap();
    s=struct2cell(p);
    fn=fieldnames(p);

    idx=[];
    
    for l=1:length(s)
        sf=s{l};
        if (isa(sf,'function_handle'))
            ss=func2str(sf)
            ss=regexprep(ss,pat,repl)
            set(h,fn{l},str2func(ss));
        end
    end
           
    %for l=1:pMap.count
        
    %end

end