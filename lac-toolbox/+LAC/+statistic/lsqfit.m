function [par R]=lsqfit(disttype,F, X)
% Least Square Method Fit
%**********************************************************
% Least Square Method Fit. Created by SORSO @ Vestas
%**********************************************************
%
% [par R]=lsqfit(disttype,F, X)
%
%Input:
% disttype='wbl3'; 3-parameter Weibull dristribution
% disttype='gbl'; Gumbel dristribution
% disttype='logn'; lognormal distribution
% F=[F1,F2,...,Fk]; nonexceedens probability (use eg. Median Rank)
% X=[T1, T2, ..., Tk ] or X=[Yc1, Yc2, ..., Yck ]; sample input sorted
% asecended 
% output:
% par = [B A (k)];           B= mean est. A= std est.
% R regression constant

n=length(F);
if strcmp('gbl',disttype)==1 %Gumbel Distribution
    Y=-log(-log(F));
elseif strcmp('wbl3',disttype)==1 %Weibull Distribution
    k=0.1:0.05:10;
    for i=1:length(k)
    Y=(-log(1-F)).^(1/k(i));
    
    Ym=1/n*sum(Y);
    Xm=1/n*sum(X);
    
    VarX=1/n*sum((X-Xm).^2);
    VarY=1/n*sum((Y-Ym).^2);
    CovYX=1/n*(Y-Ym)*(X-Xm)';
    
    A=CovYX/VarY;
    B=Xm-A*Ym;
    Yest=A*X+B;
    Xest=(Y-B)/A;
    
    R(i)=CovYX/sqrt(VarX*VarY);
        
    end
    [val pos]=max(R.^2);
    k=k(pos);
    Y=(-log(1-F)).^(1/k);
elseif strcmp('logn',disttype)==1 % Linear Fit
    
    Y=LAC.statistic.normalinvcdf(F);
    X=log(X);
else
    disp('Undefined distribution type')
    return;
end

Ym=1/n*sum(Y);
Xm=1/n*sum(X);

VarX=1/n*sum((X-Xm).^2);
VarY=1/n*sum((Y-Ym).^2);
CovYX=1/n*(Y-Ym)*(X-Xm)';

A=CovYX/VarY;
B=Xm-A*Ym;
R=CovYX/sqrt(VarX*VarY);
par=[B A];
if strcmp('wbl3',disttype)==1
    par(1,3)=k;
end

%% warning plot

if R.^2<=0.95
    color=[rand rand rand];
figure(99)
hold on
plot(X,Y,'.','Color',color)
plot(X,(X-B)/A,'-','Color',color)
xlabel('load')
ylabel('linearised yaxis')
title(['regression is below 0.95.']);
text(X(1),(X(1)-B)/A,['\leftarrow','R^2=',num2str(R.^2) ],...
     'HorizontalAlignment','left')
end
end