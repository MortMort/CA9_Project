function plot(x,y,xvar,yvar,titlestr)
    plot(x,y,'k-o','linewidth',2);grid on
    if nargin>2
        xlabel(xvar);
    end
    if nargin>3
        ylabel(yvar);
    end
    if nargin>4
        title(titlestr);
    end
    set(gcf,'color','white')
end 