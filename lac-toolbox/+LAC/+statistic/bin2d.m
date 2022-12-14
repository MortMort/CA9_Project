function [N,binDat]=bin2d(dat1,dat2,edges1,edges2)
[N1, bin1_i] = histc(dat1,edges1);
for i=1:length(N1)
    [N(:,i), bin2_i] = histc(dat2(bin1_i==i),edges2);
    for j=1:size(N,1)
        temp=dat2(bin1_i==i);
        binDat{i,j}=temp(bin2_i==j);   
        
    end
    
    
end
end
