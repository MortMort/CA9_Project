function binneddata = lognbin(signal1,signal2,bins,quantile)
% lognbin creates estimates for the lognormal distribution based on 'bins'.
% Example:
% To bin turbulence on wind speed in the bins [2:2:26] and find the 90%-quantile 
% 
% signal1 = measured wind speed
% signal2 = measured turbulence
% bins = [2:2:26];
% quantile = 90;
%
% binneddata = lognbin(signal1,signal2,bins,quantile);
%
% binneddata is then a matrix with the following rows:
% [param1 for logn ; param2 for logn ; number of data points in bin ; value
% for quantile in bin]

 

kk=signal2>0;
signal1 = signal1(kk);
signal2 = signal2(kk);

d=diff(bins)./2;
for i=1:length(bins)
    clear y k f_cum
    f_cum = 0;
    k=(signal1>=bins(i)-d(1) & signal1<=bins(i)+d(1));
    y=signal2(k,:);
    
    params = LAC.statistic.maxlikehoodfit('logn',y);
    x=[0.01:0.01:3000];
    f=LAC.statistic.lognormalpdf(x,params(1),params(2));
    
    for ii=1:length(f)
        if ii==1
            f_cum(ii)=f(ii);
        else
            f_cum(ii)=f_cum(ii-1)+f(ii);
        end
    end
    entry = find(f_cum > quantile);
    
    binneddata(i,1)=params(1);
    binneddata(i,2)=params(2);
    if isempty(entry)
        binneddata(i,4)=nan;
    else
        binneddata(i,4)=x(entry(1));
    end
    binneddata(i,3)=sum(k);
%     figure; set(gcf,'color','white')
%     hist(y,[0:1:100]);
%     f = lognormalpdf(x,params(1),params(2));
%     hold on
%     plot(x,f*sum(k),'r','linewidth',2)
%     grid on
%     xlabel('Wind Direction STD [deg]'); ylabel('Probability density function (Lognormal)')
%     title([num2str(bins(i)),' m/s'])
%     plot([24 24],[0 3000],'--r','linewidth',2)
%     if ~isnan(max(f*sum(k)))
%         ylim([0 max(f*sum(k))])
%     end
%     legend('Measurement data','Lognormal fit','Shutdown level')
%     print('-djpeg','-r200','Measurement Data - LognormalPlot')    
end

