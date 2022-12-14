classdef WindClass < handle
    methods
        function self = WindClass()
            self.setIECConstants();
            self.setDIBtConstants();
        end
        
        function output = get(self, data)
            output = 'UNKNOWN';
            
            % TI is data.WND.Turbpar
            % Vave/VaveNSI is data.WND.Vav
            if isfield(data, 'WND') && isfield(data.WND, 'Turbpar') && isfield(data.WND, 'Vav') ...
                                    && isfield(data, 'WindSpeeds') && isfield(data.WindSpeeds, 'V50') && isfield(data.WindSpeeds, 'Ve50') ...
                                    && isfield(data.WindSpeeds, 'V1') && isfield(data.WindSpeeds, 'Ve1') ...
                                    && isfield(data, 'Hhub')
                
                % Try to determine IEC class
                output = self.getIECName(data);
                if strcmpi(output, 'IECS')
                    % Try to determine DIBt class
                    self.setHubHeight(data.Hhub);
                    dibtclass = self.getDIBtName(data);
                    if ~isempty(dibtclass)
                        output = dibtclass;
                    end
                end
            end
        end
        
        function output = getCalculatedWindData(self)
            output.IEC  = self.IECdata;
            output.DIBt = self.DIBtdata;
        end
    end
    
    methods (Static)
        function status = verify(windclass)
            % Verify WindClass format, e.g. IEC1A, IECS, DIBt1I, DIBt4IV
            status = false;
            windclass = strrep(upper(windclass), 'DIBT', 'DIBt');
            
            res1 = regexp(windclass, 'IEC[1-3][A-C]|IECS','match');
            res2 = regexp(windclass, 'DIBt[1-4]IV|DIBt[1-4][I]{0,3}','match');
            if length(res1)==1 && strcmp(res1,windclass)
                status = true;
            elseif length(res2)==1 && strcmp(res2,windclass)
                status = true;
            end
        end
        
    end
    
    methods (Access=private)
        function output = getIECName(self, data)
            % Determine the wind turbine class according to IEC61400-1 ed.3
            % Use setTurbulence() and setRefWindSpeed() to create 'data' parameter
            
            output = '';
            if ~isempty(self.IECdata)
                prefix = 'IEC';
                windclass = '';
                turbulence = '';
                
                % Find turbulence intensity
                switch num2str(data.WND.Turbpar)
                    case self.IECdata.TurbparA
                        turbulence = 'A';
                    case self.IECdata.TurbparB
                        turbulence = 'B';
                    case self.IECdata.TurbparC
                        turbulence = 'C';
                end
                
                % Compare paramters with wind turbine class vectors
                Vave_class = find(abs(single(self.IECdata.Vave_expected) - single(str2double(data.WND.Vav)))        <0.01);
                V50_class  = find(abs(single(self.IECdata.V50_expected)  - single(str2double(data.WindSpeeds.V50))) <0.01);
                Ve50_class = find(abs(single(self.IECdata.Ve50_expected) - single(str2double(data.WindSpeeds.Ve50)))<0.01);
                V1_class   = find(abs(single(self.IECdata.V1_expected)   - single(str2double(data.WindSpeeds.V1)))  <0.01);
                Ve1_class  = find(abs(single(self.IECdata.Ve1_expected)  - single(str2double(data.WindSpeeds.Ve1))) <0.01);
                
                % Does the parameters match a wind turbine class?
                notempty = [Vave_class, V50_class, Ve50_class, V1_class, Ve1_class]; % All paramters were found
                if length(notempty)==5
                    samevalue = find(notempty==Vave_class); % All parameters are the same class
                    if length(samevalue)==5
                        windclass = Vave_class; % All paramters are the same. Use the first.
                    end
                end
                
                if ~isempty(turbulence) && ~isempty(windclass)
                    % Match the IECed3 specification
                    output = [prefix int2str(windclass) turbulence];
                else
                    % turbulence == '' OR windclass==0 
                    % ==> User specified wind class
                    output = [prefix 'S'];
                end
            end
        end
        
        function output = getDIBtName(self, data)
            % Determine the wind turbine class according to DIBt 2012
            % Use setHubHeight() to create 'data' parameter
            
            % w:\USER\Thtba\matlab\TLtoolbox\WpDIBt2012.m 
            % PowerPoint DMS 0038-3406
            
            output = '';
            if ~strcmpi(data.WND.ReferenceStandard,'ieced2')                
                if ~strcmpi(data.WND.Turbpar, self.IECdata.TurbparA)
                    % Not a DIBt class if not IEC class A (Turbpar == 0.16)
                    return
                end
            end
            
            if ~isempty(self.DIBtdata)
                prefix = 'DIBt';
                myTerrainCategory = '';
                myWindZone = '';
                
                myV50  = str2double(data.WindSpeeds.V50);
                myVe50 = str2double(data.WindSpeeds.Ve50);
                myV1   = str2double(data.WindSpeeds.V1);
                myVe1  = str2double(data.WindSpeeds.Ve1);
                myVav  = str2double(data.WND.Vav);
                
                categories = fields(self.DIBtdata.DIN);
                % Wind zone
                for i = 1:length(categories)
                    V50_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).V50)  - single(myV50)) <0.05);
                    Ve50_class   = find(abs(single(self.DIBtdata.DIN.(categories{i}).Ve50) - single(myVe50))<0.05);
                    V1_class     = find(abs(single(self.DIBtdata.DIN.(categories{i}).V1)   - single(myV1))  <0.05);
                    Ve1_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).Ve1)  - single(myVe1)) <0.05);
                    Vav_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).Vav)    - single(myVav))<0.01);
                    VavNSI_class = find(abs(single(self.DIBtdata.DIN.(categories{i}).VavNSI) - single(myVav))<0.01);
                    
                    notempty = [V50_class, Ve50_class, V1_class, Ve1_class, Vav_class, VavNSI_class];
                    if ~isempty(V50_class)
                        samevalue = find(notempty==V50_class);
                        if length(notempty)>=5
                            if length(samevalue)==5
                                myWindZone = num2str(V50_class);
                                break
                            end
                        end
                    end
                    
                    V50_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).V50)  - single(myV50)) <0.05);
                    Ve50_class   = find(abs(single(self.DIBtdata.ALT.(categories{i}).Ve50) - single(myVe50))<0.05);
                    V1_class     = find(abs(single(self.DIBtdata.ALT.(categories{i}).V1)   - single(myV1))  <0.05);
                    Ve1_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).Ve1)  - single(myVe1)) <0.05);
                    Vav_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).Vav)    - single(myVav))<0.01);
                    VavNSI_class = find(abs(single(self.DIBtdata.ALT.(categories{i}).VavNSI) - single(myVav))<0.01);
                    
                    notempty = [V50_class, Ve50_class, V1_class, Ve1_class, Vav_class, VavNSI_class];
                    if ~isempty(V50_class)
                        samevalue = find(notempty==V50_class);
                        if length(notempty)>=5
                            if length(samevalue)==5
                                myWindZone = num2str(V50_class);
                                break
                            end
                        end
                    end
                end

                % Terrain category ("DIN EN 1991-1-4" or "Alternative")
                for i = 1:length(categories)
                    V50_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).V50)  - single(myV50)) <0.05);
                    Ve50_class   = find(abs(single(self.DIBtdata.DIN.(categories{i}).Ve50) - single(myVe50))<0.05);
                    V1_class     = find(abs(single(self.DIBtdata.DIN.(categories{i}).V1)   - single(myV1))  <0.05);
                    Ve1_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).Ve1)  - single(myVe1)) <0.05);
                    Vav_class    = find(abs(single(self.DIBtdata.DIN.(categories{i}).Vav)    - single(myVav))<0.01);
                    VavNSI_class = find(abs(single(self.DIBtdata.DIN.(categories{i}).VavNSI) - single(myVav))<0.01);
                    
                    notempty = [V50_class, Ve50_class, V1_class, Ve1_class];
                    if length(notempty)==4
                        samevalue = find(notempty==V50_class);
                        if length(samevalue)==4
                            myTerrainCategory = categories{i};
                            break
                        end
                    end
                    
                    
                    V50_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).V50)  - single(myV50)) <0.05);
                    Ve50_class   = find(abs(single(self.DIBtdata.ALT.(categories{i}).Ve50) - single(myVe50))<0.05);
                    V1_class     = find(abs(single(self.DIBtdata.ALT.(categories{i}).V1)   - single(myV1))  <0.05);
                    Ve1_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).Ve1)  - single(myVe1)) <0.05);
                    Vav_class    = find(abs(single(self.DIBtdata.ALT.(categories{i}).Vav)    - single(myVav))<0.01);
                    VavNSI_class = find(abs(single(self.DIBtdata.ALT.(categories{i}).VavNSI) - single(myVav))<0.01);
                    
                    notempty = [V50_class, Ve50_class, V1_class, Ve1_class];
                    if length(notempty)==4
                        samevalue = find(notempty==V50_class);
                        if length(samevalue)==4
                            myTerrainCategory = categories{i};
                            break
                        end
                    end
                end
                
                output = '';
                if ~isempty(myTerrainCategory) && ~isempty(myWindZone)
                    % Match the DIBt 2012 specification
                    output = [prefix myWindZone myTerrainCategory];
                end
            end            
        end
        
        function setIECConstants(self)
            % Calculate wind turbine class vectors
            Vref = [50.0, 42.5, 37.5]; % Reference wind speeds for wind turbine class I, II, and III
                                       % Refer to IEC61400-1 ed.3
            self.IECdata.Vave_expected = 0.2 * Vref;
            self.IECdata.V50_expected  = Vref;
            self.IECdata.Ve50_expected = 1.4 * Vref;
            self.IECdata.V1_expected   = 0.8 * Vref;
            self.IECdata.Ve1_expected  = 0.8 * self.IECdata.Ve50_expected;
            
            self.IECdata.TurbparA = '0.16';
            self.IECdata.TurbparB = '0.14';
            self.IECdata.TurbparC = '0.12';
        end
        
        function setHubHeight(self, HubHeight)
            % Set hub heigth and do all possible calculations
            
            HubHeight = str2double(HubHeight);
            categories = fields(self.TerrainCategory);
            for i=1:length(categories)
                % Calculate DIN EN 1991-1-4
                cat = self.TerrainCategory.(categories{i}).DIN;
                self.DIBtdata.DIN.(categories{i}) = self.calculateDIBtWindParameters(HubHeight, cat);
                
                % Calculate Alternative
                cat = self.TerrainCategory.(categories{i}).ALT;
                self.DIBtdata.ALT.(categories{i}) = self.calculateDIBtWindParameters(HubHeight, cat);
            end
        end
        
        function output = calculateDIBtWindParameters(self, HubHeight, cat)
            output = struct();
            output.V50     = cat.ExtremeWinSpeed * self.WindZone.Vb * (HubHeight/10)^cat.PowerExtremeWinSpeed;
            output.Ve50    = 1.4*output.V50;
            output.V1      = 0.8*output.V50;
            output.Ve1     = 1.4*output.V1;
            output.Turbpar = cat.TurblenceIntensy * (HubHeight/10)^cat.PowerTurblenceIntensy;
            
            V50_WND       = cat.ExtremeWinSpeed * self.WindZone.VbWND * (HubHeight/10)^cat.PowerExtremeWinSpeed;
            output.Vav    = self.WindZone.ExtremeWinSpeed * V50_WND;
            output.VavNSI = self.WindZone.ExtremeWinSpeedNorthSee * V50_WND;
        end
        
        function setDIBtConstants(self)
            self.WindZone.Vb    = [22.5, 25.0, 27.5, 30.0];
            self.WindZone.VbWND = [22.5, 27.5, 27.5, 30.0];
            self.WindZone.ExtremeWinSpeed=0.18;
            self.WindZone.ExtremeWinSpeedNorthSee=0.20;
            
            self.TerrainCategory.I.DIN.ExtremeWinSpeed=1.18;
            self.TerrainCategory.I.DIN.TurblenceIntensy=0.14;
            self.TerrainCategory.I.DIN.PowerExtremeWinSpeed=0.12;
            self.TerrainCategory.I.DIN.PowerTurblenceIntensy=-0.12;
            
            self.TerrainCategory.I.ALT.ExtremeWinSpeed=1.15;
            self.TerrainCategory.I.ALT.TurblenceIntensy=0.128;
            self.TerrainCategory.I.ALT.PowerExtremeWinSpeed=0.121;
            self.TerrainCategory.I.ALT.PowerTurblenceIntensy=-0.05;
            
            self.TerrainCategory.II.DIN.ExtremeWinSpeed=1.00;
            self.TerrainCategory.II.DIN.TurblenceIntensy=0.19;
            self.TerrainCategory.II.DIN.PowerExtremeWinSpeed=0.16;
            self.TerrainCategory.II.DIN.PowerTurblenceIntensy=-0.16;
            
            self.TerrainCategory.II.ALT.ExtremeWinSpeed=1.15;
            self.TerrainCategory.II.ALT.TurblenceIntensy=0.128;
            self.TerrainCategory.II.ALT.PowerExtremeWinSpeed=0.121;
            self.TerrainCategory.II.ALT.PowerTurblenceIntensy=-0.05;
            
            self.TerrainCategory.III.DIN.ExtremeWinSpeed=0.77;
            self.TerrainCategory.III.DIN.TurblenceIntensy=0.28;
            self.TerrainCategory.III.DIN.PowerExtremeWinSpeed=0.22;
            self.TerrainCategory.III.DIN.PowerTurblenceIntensy=-0.22;
            
            self.TerrainCategory.III.ALT.ExtremeWinSpeed=0;
            self.TerrainCategory.III.ALT.TurblenceIntensy=0;
            self.TerrainCategory.III.ALT.PowerExtremeWinSpeed=0;
            self.TerrainCategory.III.ALT.PowerTurblenceIntensy=0;
            
            self.TerrainCategory.IV.DIN.ExtremeWinSpeed=0.56;
            self.TerrainCategory.IV.DIN.TurblenceIntensy=0.43;
            self.TerrainCategory.IV.DIN.PowerExtremeWinSpeed=0.30;
            self.TerrainCategory.IV.DIN.PowerTurblenceIntensy=-0.30;
            
            self.TerrainCategory.IV.ALT.ExtremeWinSpeed=0;
            self.TerrainCategory.IV.ALT.TurblenceIntensy=0;
            self.TerrainCategory.IV.ALT.PowerExtremeWinSpeed=0;
            self.TerrainCategory.IV.ALT.PowerTurblenceIntensy=0;
        end
    end
    
    properties (Access=private)
        TerrainCategory;
        WindZone;
        
        IECdata;
        DIBtdata;
    end
end
   