classdef  mapablestruct 
    
    properties 
        s;
    end
    
    methods (Access = public)
        function mp=asMap(obj)
            mp=struct2map(obj.s);
        end
        
        function obj=setField(obj,fl,val)
             tok=regexp(fl,'(\w+)\.*','tokens');
             names=[tok{:}];
             obj.s=addSubStruct(obj.s,names,val);
        end
        
        function obj=mapAbleStruct()
            obj.s=struct();
        end
        
    end     
    
    methods (Static)
        function obj=fromMap(mp)
            obj=wtLin.mapAbleStruct();
            obj.s=map2struct(mp);
        end
        
        function obj=fromStruct(st)
            obj=wtLin.mapAbleStruct();
            obj.s=st;
        end
    end
end

function s=map2struct(m) 
    %Extract info from map
    keys=m.keys();
    vals=m.values();
    %Create struct
    s=struct();
    %Loop through all key, value pairs and create struct
    for k=1:m.length()
        %Find field names
        tok=regexp(keys{k},'(\w+)\.*','tokens');
        names=[tok{:}];
        %Add substructs (values)
        s=addSubStruct(s,names,vals{k});
    end
end

function s=addSubStruct(s,names,value)
    if length(names)==1 %If this is the last level add the value
        s.(names{1})=value;
    else %If there are further substructs, create struct and recurse
        if ~isfield(s,names{1})
            s.(names{1})=struct();
        end
        s.(names{1})=addSubStruct(s.(names{1}),names(2:end),value);
    end
end



function m=struct2map(s)
    %Create container
    m=containers.Map();
    %Fill in map from struct
    struct2list(s,'',m);
end

function struct2list(s,prefix,m) 
    %Get field names
    f=fieldnames(s);
    %Get field valies
    c=struct2cell(s);
    %Loop through all fields
    for k=1:length(c)
        %Create the name for the field
        name=[prefix f{k}];
        if(isstruct(c{k})) %If the field is a substruct recurse
            struct2list(c{k},[name '.'],m);
        else %Else just add the name, value pair
            m(name)=c{k};
        end

    end
end

