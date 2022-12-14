function intwrite(fn,dt,data,varargin)
%INTWRITE - Writer function for int-files
%
% Syntax:  intwrite_fast(fn,dummy1,dt,dat)
%
% Inputs:
%    fn       - Filename  
%    dt       - Timestep, e.g. 0.01s
%    data     - Array containing time series; size(data)=[# dt,# sensors]
%    varargin - Header, optional
%
% Example:
%    intwrite_fast('example.int',1,0.1,[linspace(0,5,1000)',linspace(0,10,1000)'])
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: vdat
%
% Author: -
% May 20xx; Last revision (MAARD): 10-June-2015

%% Parse inputs
p = inputParser;
addRequired(p,'fn',@isstr);
addRequired(p,'dt',@isnumeric);
addRequired(p,'data',@isnumeric);
addOptional(p,'header',zeros(19,1));
parse(p,fn,dt,data,varargin{:});

%% Code 
fid = fopen(p.Results.fn,'wb');
fwrite(fid,p.Results.header,'int32');
fwrite(fid,size(p.Results.data,2),'int32');

sno = 1:size(p.Results.data,2)+1;
sno(size(p.Results.data,2)+2)=0;

fwrite(fid,sno,'int32');
fwrite(fid,0,'int32');
fwrite(fid,p.Results.dt,'single');

max_=max(p.Results.data);
min_=min(p.Results.data);

idx=find(max_>-min_);
fak=-min_/32000;
fak(idx)=max_(idx)/32000;
idx=round(10000000*fak)==0;
fak(idx)=1;

if 1==0,
    for i=1:size(p.Results.data,2)
        max_(i)=-1e33;
        min_(i)=1e33;
    end;
    
    for i=1:size(p.Results.data,2)
        for j=1:size(p.Results.data,1)
            if p.Results.data(j,i)>max_(i)
                max_(i)=p.Results.data(j,i);
            end;
            if p.Results.data(j,i)<min_(i)
                min_(i)=p.Results.data(j,i);
            end;
        end;
    end;
    
    for i=1:size(p.Results.data,2)
        if max_(i)>-min_(i)
            fak_(i)=max_(i)/32000;
        else
            fak_(i)=-min_(i)/32000;
        end;
        if round(10000000*fak(i))==0
            fak_(i)=1;
        end;
    end;
    norm(fak-fak_)
end

fwrite(fid,fak,'single');

if 1==0,
    temp=zeros(1,size(p.Results.data,1)*size(p.Results.data,2));
    n=1;
    for j=1:size(p.Results.data,1)
        for i=1:size(p.Results.data,2)
            temp(n)=round(p.Results.data(j,i)/fak(i));
            n=n+1;
        end;
    end
end

if 1==1,
    temp_=zeros(fliplr(size(p.Results.data)),'int16');
    for i=1:length(fak),
        temp_(i,:)=round(p.Results.data(:,i)./fak(i));
    end
    fwrite(fid,temp_,'int16');
end

fclose(fid);