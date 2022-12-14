function Review_Fatigue_Matrix(xmlfile,out_path,inv_name,clm_par)
%% Plot Fatigue Interpolation from XML
% 21/11/2020
% Script to plot an overview of the fatigue database as a function of wind speed
%% Inputs
% xmlfile - path to the relevant VSC xml file;
% out_path - path to output folder;
% inv_name - prefix added to file name of saved figures;
% clm_par - parameter for color ID. Options: 'TI', 'wshear', 'slope'

dlc_str  = '11'; % Load case handle to be included in the overview. Note: Wildcards are not supported.

% Settings for the plot
colors   = [0, 0.4470, 0.7410
            0.8500, 0.3250, 0.0980
            0.4660, 0.6740, 0.1880]; 

%% Main Script
% Read xml files
xmldata  = xmlread(xmlfile);

% Get sensor list from Approved Design Loads
adl_list = xmldata.getElementsByTagName('ApprovedDesignLoads');
adl_data = adl_list.item(0);

% Check Fatigue Load Sensors
fatiguedata.method = 'Fatigue';
adlfat_list = adl_data.getElementsByTagName('Fatigue');
adlfat_data = adlfat_list.item(0);

method_list = adlfat_data.getElementsByTagName('Wohler');
method_data = method_list.item(0); 

counter = 0;
for iwohler = 0 : method_data.getLength - 1   
    sensor_data = adlfat_data.getElementsByTagName('LoadLevel');
    sensor_list = sensor_data.item(0).getAttributes;

    for isen = 0 : sensor_list.getLength - 1    
        counter            = counter + 1;
        attrib             = sensor_list.item(isen);
        sensor{counter,1}  = char(attrib.getName);
        wohler{counter,1}  = str2double(method_list.item(iwohler).getAttribute('value'));
    end
end

fatiguedata.sensor = sensor; clear sensor;
fatiguedata.type   = wohler; clear wohler;

% Check LDD/LRD Load Sensors
ldddata.method = 'LoadDurationDistribution';
adlfat_list    = adl_data.getElementsByTagName('LoadDurationDistribution');
adlfat_data    = adlfat_list.item(0);

method_list = adlfat_data.getElementsByTagName('Wohler');
method_data = method_list.item(0); 

counter = 0;
for iwohler = 0 : method_data.getLength - 1
    sensor_data = adlfat_data.getElementsByTagName('LoadLevel');
    sensor_list = sensor_data.item(0).getAttributes;
    
    for isen = 0 : sensor_list.getLength - 1
        counter           = counter + 1;
        attrib            = sensor_list.item(isen);
        sensor{counter,1} = char(attrib.getName);
        wohler{counter,1} = str2double(method_list.item(iwohler).getAttribute('value'));
    end
end

ldddata.sensor = sensor; clear sensor;
ldddata.type   = wohler; clear wohler;

%% Get Reference Loads Data
refloads_list = xmldata.getElementsByTagName('ReferenceLoads');
refload       = refloads_list.item(0);

fatigue_list  = refload.getElementsByTagName(fatiguedata.method);
fat           = fatigue_list.item(0);

ldd_list      = refload.getElementsByTagName(ldddata.method);
ldd           = ldd_list.item(0);

fat_lc_list   = fat.getElementsByTagName('LoadCase');
ldd_lc_list   = ldd.getElementsByTagName('LoadCase');

% Loop through fatigue calculation process
for m = 1:2    
    if m == 1
        lc_list = fat_lc_list;
        data    = fatiguedata;
    elseif m == 2
        lc_list = ldd_lc_list;
        data    = ldddata;
    end
    
    for n = 1 : length(data.sensor)        
        count = 0;        
        for ilc = 0 : lc_list.getLength - 1
            dlc_name           = lc_list.item(ilc).getAttribute('value');
            
            if strncmp(dlc_name, dlc_str, length(dlc_str))
                count = count + 1;
                wspd(count)      = str2double(lc_list.item(ilc).getAttribute('WindSpeed'));
                wohler_list      = lc_list.item(ilc).getElementsByTagName('Wohler');
                
                for iwoh = 0 : wohler_list.getLength - 1
                    wohler  = wohler_list.item(iwoh).getAttribute('value');
                    
                    if str2double(wohler) == data.type{n}
                        dc_list = wohler_list.item(iwoh).getElementsByTagName('DesignClimate');
                        
                        for idc = 0 : dc_list.getLength - 1
                            dc_node = dc_list.item(idc);
                            TI                    = str2double(dc_node.getAttribute('TurbulenceIntensity'));
                            wshear                = str2double(dc_node.getAttribute('WindShear'));
                            inflow                = str2double(dc_node.getAttribute('Inflow'));
                            wgrad                 = str2double(dc_node.getAttribute('WindGradient'));
                            load                  = str2double(dc_node.getAttribute(data.sensor(n)));
                            dc_data(idc + 1, 1:5, count) = [TI wshear inflow wgrad load];
                        end
                    else
                        continue
                    end
                    
                end
            end
        end        
        %save dc_data for combination of sensor + type
        dc_data_final.(sprintf('%s_%s',data.sensor{n},strrep(string(data.type{n}),'.','_'))) = dc_data;
    end
end


%% Plot Load Data - Max Wshear
fig = figure();
set(fig,'visible','off')

sensorlabels = fields(dc_data_final);
for isen = 1:length(fields(dc_data_final))
    sensorlabel  = sensorlabels{isen};
    dc_data_plot = dc_data_final.(sprintf('%s',sensorlabel));
    
    % Loop in wind speed
    for iwspd = 1 : length(wspd)
        switch lower(clm_par)
            case 'ti'
                par = 1;
            case 'wshear'
                par = 2;
            case 'slope'
                par = 3;
        end
        
        par_interp = unique(dc_data(:,par,iwspd));
        
        for ipar = 1 : length(par_interp)
            par_pos = find(dc_data_plot(:,par,iwspd) == par_interp(ipar));
            scatter(repelem(wspd(iwspd),length(par_pos)), dc_data_plot(par_pos,5,iwspd), [], colors(ipar, :),'filled')
            hold on
        end
    end
    
    grid on
    xlabel('Wind Speed [m/s]')
    ylabel(sensorlabel,'Interpreter','none')
    saveas(gcf, fullfile(out_path,sprintf('%s_%s.fig',inv_name,sensorlabel)),'fig')
    saveas(gcf, fullfile(out_path,sprintf('%s_%s.emf',inv_name,sensorlabel)),'emf')
    hold off
end
close all


end