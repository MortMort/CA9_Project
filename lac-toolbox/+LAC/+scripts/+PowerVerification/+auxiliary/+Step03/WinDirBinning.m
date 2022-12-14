function [Bin] = WinDirBinning(Xmean,BinRange,MetMastLoc,Binname,index)
  
    % check index
    if isempty(index)
        index=[1:length(Xmean)]';
    end
    
    for i = 1:length(BinRange)
        LowLim = MetMastLoc-(BinRange(i)/2);
        UppLim = MetMastLoc+(BinRange(i)/2);
        
        Bin.name{i}          = strcat(Binname,'_',num2str(LowLim),'_',num2str(UppLim));
        Bin.lowerbinlimit{i} = LowLim;
        Bin.upperbinlimit{i} = UppLim;
        Bin.index{i}       = find(Xmean >= LowLim & Xmean <= UppLim);

    end
  
end