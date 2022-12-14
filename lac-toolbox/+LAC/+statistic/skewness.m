function skew=skewness(x)
% 3. moment, Skewness
%**********************************************************
% 3. moment, Skewness. Created by SORSO @ Vestas
%**********************************************************
% 
% skew=skewness(x)
% 
% input:
% x = data sample
% output:
% skewness of data (3. moment)
%
% Note! verifyed against Excel skewness

n=length(x);
xm=mean(x);
xs=std(x);
skew=n/((n-1)*(n-2))*sum(((x-xm)/xs).^3);
end
