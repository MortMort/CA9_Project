classdef intpost < handle
    % SYNTAX:
    %   postLoads=postLoads(simulationpath)
    %   postLoads.read()
    %
    %
    % INPUTS:
    %   simulationpath - path to the VTS simulation folder, the folder must
    %   contain an intpostd output
    %
    % CLASS METHODS:
    %   postLoads.read      - reads the post loads files from folder and
    %                        store data in the object
    %
    %   postLoads.save       - saves data from the object into a postloads.mat file
    %
    %   postLoads.load       - loads postloads.mat file
    %
    %
    %   stapost.getLoad    - Extract load from stadata and bins to specified
    %   load cases
    %
    %   stapost.compareLC  - compares load cases for different intpostLoads
    %   instances.
    %
    % DATASTRUCTURE:
    %   intpostLoads.mainload - Main load post processed loads
    %
    %   intpostLoads.pitload - Pitch system post processed loads
    %
    %   intpostLoads.info   - info about the data in the object, date, user etc.
    %
    %   intpostLoads.settings  - Settings to be used for comparing between
    %   different set-ups
    %
    % 06/08-2014 - FACAP
    % V00beta - Not reviewed.
    properties
        mainload;
        pitload;
        twrload;
        simdat=struct('path','','frqfile','','sensorfile','','setfile','','masfile','')
        info=struct('created',datestr(now),'user',getenv('USERNAME'),'version','V00beta');
        settings=struct('postLoad','MainLoad','plot',true,'plotRatioToRef',true)
    end
    
    methods
        
        function self=intpost(folder)
            self.simdat=LAC.vts.simulationdata(folder);
        end
        
        function [mainload]=read(self,forceread,postLoadFoldName)
            % mainload=intpostLoads.read(self,forceread,postLoadFoldName)
            %
            % DESCRIPTION:
            %   Read all stafiles in simulation folder and store it in the
            %   object. If a current stapost.m file exist, this file will be loaded
            %   instead.
            %
            % INPUTS:
            %   forceread - optional argument. Value 1 = read regardless if
            %               stapost.m file exist.
            %   postLoadFoldName - optional argument. Post loads custom
            %   folder name, default "postloads".
            
            if nargin==1
                forceread=0;
            end
            if nargin<2 || isempty(postLoadFoldName)
                postLoadFoldName = 'Postloads';
            end
            
            postLoad_file=fullfile(self.simdat.simulationpath,postLoadFoldName,'MAIN','MainLoad.txt');
            if exist(fullfile(self.simdat.simulationpath,postLoadFoldName,'postloads.mat'), 'file')&&forceread==0
                if exist(postLoad_file,'file')
                    temp=dir(postLoad_file);
                    dateSens=temp.date;
                    self.load(fullfile(self.simdat.simulationpath,'postloads.mat'));
                    self.info.created;
                    if datenum(dateSens)>datenum(self.info.created)
                        disp('Postloads has been changed after postloads.mat creation. Reading postLoads files..')
                        self.read(1);
                    end
                else
                    self.load(fullfile(self.simdat.simulationpath,'postloads.mat'));
                end
            else
                % MAIN
                mainLoad = LAC.intpostd.convert(postLoad_file,'MAIN');
                % PIT
                postLoad_file=fullfile(self.simdat.simulationpath,postLoadFoldName,'HUB','PITLoad.txt');
                pitLoad = LAC.intpostd.convert(postLoad_file,'PIT');
                % TWR
                postLoad_file=fullfile(self.simdat.simulationpath,postLoadFoldName,'TWR','TWRLoad.txt');
                twrLoad = LAC.intpostd.convert(postLoad_file,'TWR');
            end
            
            self.mainload=mainLoad;
            self.pitload=pitLoad;
            self.twrload=twrLoad;
            
            self.info.created=datestr(now);
        end
                
        function [ref, out]=compareLC(self,load2plot,varargin)
            % [ref out]=stapost.compareLC(loads2plot,intpostLoads_objects)
            %
            % DESCRIPTION:
            %   Compare specified simulation intpostd loads with settings from
            %   intpostLoads.LC.
            %
            % INPUTS:
            %   load2plot - path the loads section to be compared e.g. mainload.EquivalentBladeBearingLoad
            %   intpostLoads_objects - any number of intpostLoads objects, which
            %                     shall be used for comparing.
            
            ref = self.struct2mat(eval(sprintf('self.%s;',load2plot)),'Value');
            
            legendstr={self.simdat.path};
            out=[];
            
            for i=1:length(varargin)
                if isempty(eval(sprintf('varargin{i}.%s',load2plot)))
                    varargin{i}.read;
                end
                
                out(i,:) = self.struct2mat(eval(sprintf('varargin{i}.%s;',load2plot)),'Value');
                
                for nn=1:size(out,2)
                    sensorName=eval(sprintf('self.%s(nn).Sensor',load2plot));
                    sensorMethod=eval(sprintf('self.%s(nn).Method',load2plot));
                    sensorUnit=eval(sprintf('self.%s(nn).Unit',load2plot));
                    sensorNote=eval(sprintf('self.%s(nn).Note',load2plot));
                    xtlbls{nn} = sprintf('%s@%s %s-%s',sensorMethod,sensorName,sensorUnit,sensorNote);
                end
                
                legendstr{end+1}=varargin{i}.simdat.path;
                
            end
            nSensors=size(out,2);
            
            if nSensors==1
                out(end,end+1) = nan;
                ref(1,end+1) = nan;
            end
            
            if self.settings.plot
                % Plot figure
                f=figure;
                set(f,'color','white'); set(f, 'Position', [120 75 1100 800]);
                subplot(5,1,1:4)
                if ~self.settings.plotRatioToRef
                    bar([ref; out]'); grid on;
                else
                    barVal = [ref./ref; out./repmat(ref,size(out,1),1)]';
                    barVal(isnan(barVal)) = 1;
                    barVal(isinf(barVal)) = 1;
                    hBars = bar(barVal); grid on;
                    set(hBars(1),'BaseValue',1);
                    hBaseline = get(hBars(1),'BaseLine');
                    set(hBaseline,'LineStyle',':',...
                       'Color','red',...
                       'LineWidth',2);
                end
                
                legend(legendstr,'location','Best','Interpreter','none');
                
                if self.settings.plotRatioToRef
                    ylabel('Ratio2Ref');
                else
                    ylabel('Value');
                end

                Xt = 1:1:nSensors;
                Xl = [0.5 nSensors+0.5];
                
                set(gca,'XTick',Xt,'XLim',Xl);
                ax = axis; % Current axis limits
                axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
                Yl = ax(3:4); % Y-axis limits
                
                % Place the text labels
                t = text(Xt,Yl(1)*ones(1,length(Xt)),xtlbls);
                set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
                    'Rotation',45,'Interpreter','none');
                % Remove the default labels
                set(gca,'XTickLabel','');
                
                title(load2plot,'Interpreter','None');

                %                 if ~self.settings.plotRatioToRef
                %                     uitable('Data', [ref; out], 'ColumnName', xtlbls, 'Position', [30 20 990 120]);
                %                 else
                %                     uitable('Data', [ref; out./repmat(ref,size(out,1),1)], 'ColumnName', xtlbls, 'Position', [30 20 990 120]);
                %                 end
            end
        end
        
        
        function save(self)
            savefile = 'postloads.mat';
            fprintf('Saving data to %s...\n',fullfile(self.simdat.path,savefile))
            export.simdat=self.simdat; export.stadat=self.stadat; export.info=self.info;
            save(fullfile(self.simdat.path,savefile), 'export');
        end
        
        
        function load(self,filename)
            fprintf('Loading %s...\n',filename)
            load(filename)
            self.simdat=export.simdat; self.stadat=export.stadat; self.info=export.info;
        end
    end
    
    methods (Access = private)
        function smat=struct2mat(self,structVect,fieldName)
            smat=zeros(1,length(structVect));
            for nn=1:length(structVect)
                eval(['smat(nn)=structVect(nn).' fieldName ';']);
            end
        end
    end
    
end
