function dampingPlotting(bladeProps,turbname,outpath)
% Plots the calculated 2D damping at the specified reference section along
% with each of the four components that contribute to the 2D damping:
% CL,CD,dCL/dA,dCD/dA

% blade sctions
stations = bladeProps.SectionTable.R;
radius = bladeProps.SectionTable.R(end); 
span = [.50, .71, .88, .96]; % [-] wanted blade span output

sr = span*radius;
[~,r] = (min(abs(stations - sr))); % closest blade span outputs

load([outpath '/' turbname,'_SDOF2Ddamping'])
load([outpath '/' turbname,'_BOdamping'])

%% PLOTTING
eta=damping.MODE2.BLD1.eta; % Select 1st Edgewise Mode for Blade 1
LW=2;
% 2D Damping
for i=1:length(r)
    figure(i)
    hold off
    P(1)=plot(yawerr,eta.lift(r(i),idx),'g--','LineWidth',LW);
    hold on
    P(2)=plot(yawerr,eta.drag(r(i),idx),'r--','LineWidth',LW);
    P(3)=plot(yawerr,eta.liftslope(r(i),idx),'c--','LineWidth',LW);
    P(4)=plot(yawerr,eta.dragslope(r(i),idx),'m--','LineWidth',LW);
    P(5)=plot(yawerr,eta.total(r(i),idx),'b','LineWidth',LW);
    plot([-180 180],[0 0],'k')
    xlim([-180 180])
    set(gca,'XTick',[-180:60:180])
    xlabel('\bfAngle of Attack [\circ]','FontSize',12)
    ylabel('\bf2D Damping Ratio [%]','FontSize',12)
    
    legend(P,{'CL','CD','CL''','CD''','Total'},'Orientation','Horizontal','Location','North')
    title(sprintf('%s - 2D Damping at R=%im (%.1f%%)',turbname,R(r(i)),R(r(i))*100/R(end)),'FontWeight','Bold','FontSize',14,'Interpreter','none')
    print(gcf,[outpath '/' turbname,'_2Ddamping_',num2str(R(r(i))),'m.png'],'-dpng')
    savefig([outpath '/' turbname,'_2Ddamping_',num2str(R(r(i))),'m'])
end

% Blade Only Damping
figure(i+1)
hold off
colvec={'r','g','m','c'};
for j=1:length(r)
    P2(j)=plot(yawerr,eta.total(r(j),idx),'color',colvec{j},'LineWidth',LW);
    hold on
end
P2(j+1)=plot(yawerr,BOdamping*100,'b','LineWidth',LW);
plot([-180 180],[0 0],'k')
xlim([-180 180])
xlabel('\bfAngle of Attack [\circ]','FontSize',12)
ylabel('\bf(2D/3D) Damping Ratio [%]','FontSize',12)
legend(P2([5,1:4]),{'Whole Blade',sprintf('2D - %.1f%% Span',R(r(1))*100/R(end)),sprintf('2D - %.1f%% Span',R(r(2))*100/R(end)),sprintf('2D - %.1f%% Span',R(r(3))*100/R(end)),sprintf('2D - %.1f%% Span',R(r(4))*100/R(end))},'Location','SouthWest')
title(sprintf('%s - 2D and Whole Blade Damping',turbname),'FontWeight','Bold','FontSize',14,'Interpreter','none')
print(gcf,[outpath '/' turbname,'_Damping_Comparison.png'],'-dpng')
savefig([outpath '/' turbname,'_Damping_Comparison'])