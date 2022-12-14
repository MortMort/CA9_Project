classdef DRT < handle
   properties %(SetObservable)
        Filename char
        Date
        Type
        isMB              
        Extreme_FxM_f_Abs
        Extreme_FyM_r_Max
        Extreme_FyM_r_Min
        Extreme_FzM_f_Abs
        Extreme_MxM_f_Abs
        Extreme_MxM_r_Abs
        Extreme_MyM_r_Max
        Extreme_MyM_r_Min
        Extreme_MyRL_Max
        Extreme_MzM_r_Abs
        Extreme_MzM_f_Abs
        Extreme_MrM_Abs
        Extreme_Omega_Max
        Extreme_Omega_Min
        Equivalent_Load_Ranges
        Equivalent_Load_Duration
        Equivalent_Load_Revolutions
        VLD
    end    
    
   methods (Static)
        function s = decode(Coder)
            s = eval(mfilename('class')); 
            s.Date = datestr(now());
            s.Type = 'DRTload';            
            s.Filename = Coder.getSource;  
            
           
            decodeSections = {
                'Extreme Absolute Lateral Force at Main Bearing (Fixed), FxMBf. Incl. PLF',   ... % decodeSections(1)
                'Extreme Maximum Thrust Force at Main Bearing, FyMBr. Incl. PLF',             ... % decodeSections(2)
                'Extreme Minimum Thrust Force at Main Bearing, FyMBr. Incl. PLF',             ... % decodeSections(3)
                'Extreme Absolute Vertical Force at Main Bearing (Fixed), FzMBf. Incl. PLF',  ... % decodeSections(4)
                'Extreme Absolute Tilt Moment at Main Bearing (Fixed), MxMBf. Incl. PLF',     ... % decodeSections(5)
                'Extreme Absolute Tilt Moment at Main Bearing (rotating), MxMBr. Incl. PLF',  ... % decodeSections(6)
                'Extreme Positive Torque at Main Bearing, MyMBr. Incl. PLF',                  ... % decodeSections(7)
                'Extreme Negative Torque at Main Bearing, MyMBr. Incl. PLF',                  ... % decodeSections(8)
                'Extreme Positive Torque at Rotor Lock (Fixed), MyRL. Incl. PLF',             ... % decodeSections(9)
                'Extreme Absolute yaw Moment at Main Bearing (rotating), MzMBr. Incl. PLF',   ... % decodeSections(10)
                'Extreme Absolute yaw Moment at Main Bearing (Fixed), MzMBf. Incl. PLF',      ... % decodeSections(11)
                'Extreme Resultant Moment at Main Bearing, MrMB. Incl. PLF',                  ... % decodeSections(12)
                'Extreme Positive rotational velocity, Omega, Excl. PLF',                     ... % decodeSections(13)
                'Extreme Negative rotational velocity, Omega, Excl. PLF',                     ... % decodeSections(14)
                'Equivalent Load Ranges, Neq=1E7',                                            ... % decodeSections(15)
                'Equivalent Load Duration',                                                   ... % decodeSections(16)
                'Equivalent Load Revolutions',                                                ... % decodeSections(17)
                'Equivalent load for gearbox'                                        ... % decodeSections(18)   
                };   
           
           
            
            decodeSections_shaft = {
                'Extreme Absolute Lateral Force at Main Shaft (Fixed), FxMSf. Incl. PLF',   ... % decodeSections(1)
                'Extreme Maximum Thrust Force at Main Shaft, FyMSr. Incl. PLF',             ... % decodeSections(2)
                'Extreme Minimum Thrust Force at Main Shaft, FyMSr. Incl. PLF',             ... % decodeSections(3)
                'Extreme Absolute Vertical Force at Main Shaft (Fixed), FzMSf. Incl. PLF',  ... % decodeSections(4)
                'Extreme Absolute Tilt Moment at Main Shaft (Fixed), MxMSf. Incl. PLF',     ... % decodeSections(5)
                'Extreme Absolute Tilt Moment at Main Shaft (rotating), MxMSr. Incl. PLF',  ... % decodeSections(6)
                'Extreme Positive Torque at Main Shaft, MyMSr. Incl. PLF',                  ... % decodeSections(7)
                'Extreme Negative Torque at Main Shaft, MyMSr. Incl. PLF',                  ... % decodeSections(8)
                'Extreme Positive Torque at Rotor Lock (Fixed), MyRL. Incl. PLF',             ... % decodeSections(9)
                'Extreme Absolute yaw Moment at Main Shaft (rotating), MzMSr. Incl. PLF',   ... % decodeSections(10)
                'Extreme Absolute yaw Moment at Main Shaft (Fixed), MzMSf. Incl. PLF',      ... % decodeSections(11)
                'Extreme Resultant Moment at Main Shaft, MrMS. Incl. PLF',                  ... % decodeSections(12)
                'Extreme Positive rotational velocity, Omega, Excl. PLF',                     ... % decodeSections(13)
                'Extreme Negative rotational velocity, Omega, Excl. PLF',                     ... % decodeSections(14)
                'Equivalent Load Ranges, Neq=1E7',                                            ... % decodeSections(15)
                'Equivalent Load Duration',                                                   ... % decodeSections(16)
                'Equivalent Load Revolutions'                                                ... % decodeSections(17)  
                'Equivalent load for gearbox'                                        ... % decodeSections(18) 
                };
            
            sectionName = {
                'Extreme_FxM_f_Abs',  ... % sectionName(1)
                'Extreme_FyM_r_Max',  ... % sectionName(2)
                'Extreme_FyM_r_Min',  ... % sectionName(3)
                'Extreme_FzM_f_Abs',  ... % sectionName(4)
                'Extreme_MxM_f_Abs',  ... % sectionName(5)
                'Extreme_MxM_r_Abs',  ... % sectionName(6)
                'Extreme_MyM_r_Max',  ... % sectionName(7)
                'Extreme_MyM_r_Min',  ... % sectionName(8)
                'Extreme_MyRL_Max',   ... % sectionName(9)
                'Extreme_MzM_r_Abs',  ... % sectionName(10)
                'Extreme_MzM_f_Abs',  ... % sectionName(11)
                'Extreme_MrM_Abs',   ... % sectionName(12)
                'Extreme_Omega_Max',  ... % sectionName(13)
                'Extreme_Omega_Min',            ... % sectionName(14)
                'Equivalent_Load_Ranges',       ... % sectionName(15)
                'Equivalent_Load_Duration',     ... % sectionName(16)
                'Equivalent_Load_Revolutions',  ... % sectionName(17)
                'VLD' ... % sectionName(18)   
                };
            
            Offset1 = 3;
            Offset2 = 2;
                 
            for decodeID = 1:length(decodeSections)
                senData    = [];
                curSenLine = 1;
                switch decodeSections{decodeID}
                    case decodeSections(1)
                       num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)  
                          s.isMB = 1; 
                        Coder.search(decodeSections{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(2));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       else
                         s.isMB = 0;
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(2));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       end
                                
                    case decodeSections(2)
                       
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(3));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(3));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       end
                        
                    case decodeSections(3)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(3));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(3));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';   
                       end
                       
                    case decodeSections(4)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(4));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(4));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kN';   
                       end
                        
                    case decodeSections(5)
                         num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(5));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(5));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                        
                    case decodeSections(6)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(7));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(7));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';   
                       end
                        
                    case decodeSections(7)
                       num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(8));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(8));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                        
                    case decodeSections(8)
                        Coder.search(decodeSections{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(8));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
     
                        
                    case decodeSections(9)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(8));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(8));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                        
                    case decodeSections(10)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(9));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(9));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                       
                    case decodeSections(11)
                        num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(6));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(6));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                       
                    case decodeSections(12)
                       num = size(Coder.search(decodeSections{decodeID},'exact'));
                       if(num>0)
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(11));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       else
                        Coder.search(decodeSections_shaft{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(11));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'kNm';
                       end
                        
                    case decodeSections(13)
                        Coder.search(decodeSections{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(10));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'rpm';
                        
                    case decodeSections(14)
                        Coder.search(decodeSections{decodeID},'exact');
                        Coder.skip(Offset1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).Value    = str2double(C{1}(10));
                        senData(curSenLine).LoadCase = C{1}(13);
                        senData(curSenLine).Unit     = 'rpm';
                       
                    case decodeSections(15)
                        Coder.search(decodeSections{decodeID},'exact');
                        Coder.skip(Offset2)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        
                        senData(curSenLine).FxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).FyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).FyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).FyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).FyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).FyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_r.m12   = str2double(C{1}(7));
                        

                    case decodeSections(16)
                        lines  = Coder.search(decodeSections{decodeID});
                        Coder.search(lines(2),'exact');
                        Coder.skip(Offset2)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        
                        senData(curSenLine).FxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).FyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).FyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).FyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).FyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).FyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MrM_.m3    = str2double(C{1}(2));
                        senData(curSenLine).MrM_.m4    = str2double(C{1}(3));
                        senData(curSenLine).MrM_.m6    = str2double(C{1}(4));
                        senData(curSenLine).MrM_.m8    = str2double(C{1}(5));
                        senData(curSenLine).MrM_.m10   = str2double(C{1}(6));
                        senData(curSenLine).MrM_.m12   = str2double(C{1}(7));
                        

                    case decodeSections(17)
                        lines  = Coder.search(decodeSections{decodeID});
                        Coder.search(lines(2),'exact');
                        Coder.skip(Offset2)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        
                        senData(curSenLine).FxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).FyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).FyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).FyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).FyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).FyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).FzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).FzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).FzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).FzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).FzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).FzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_f.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_f.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_f.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_f.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_f.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_f.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MxM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MxM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MxM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MxM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MxM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MxM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MyM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MyM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MyM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MyM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MyM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MyM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MzM_r.m3    = str2double(C{1}(2));
                        senData(curSenLine).MzM_r.m4    = str2double(C{1}(3));
                        senData(curSenLine).MzM_r.m6    = str2double(C{1}(4));
                        senData(curSenLine).MzM_r.m8    = str2double(C{1}(5));
                        senData(curSenLine).MzM_r.m10   = str2double(C{1}(6));
                        senData(curSenLine).MzM_r.m12   = str2double(C{1}(7));
                        
                        Coder.skip(1)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');
                        senData(curSenLine).MrM_.m3    = str2double(C{1}(2));
                        senData(curSenLine).MrM_.m4    = str2double(C{1}(3));
                        senData(curSenLine).MrM_.m6    = str2double(C{1}(4));
                        senData(curSenLine).MrM_.m8    = str2double(C{1}(5));
                        senData(curSenLine).MrM_.m10   = str2double(C{1}(6));
                        senData(curSenLine).MrM_.m12   = str2double(C{1}(7));
                
                    case decodeSections(18)
                        
                        lines  = Coder.search(decodeSections{decodeID});
                        
                        Coder.search(lines(1),'exact');
                        Coder.skip(2) % assume fixed format until section 12.1.1
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');                            
                        
                        % bearings
                        ii = 1;
                        
                        while ischar(linestr)
                            senData(curSenLine).bearings(ii).name    = char(C{1}(1));
                            senData(curSenLine).bearings(ii).sensor  = char(C{1}(2));
                            senData(curSenLine).bearings(ii).type    = char(C{1}(3));
                            senData(curSenLine).bearings(ii).m       = str2double(C{1}(4));
                            senData(curSenLine).bearings(ii).neq     = str2double(C{1}(5));
                            senData(curSenLine).bearings(ii).value   = str2double(C{1}(6));
                            senData(curSenLine).bearings(ii).unit    = char(C{1}(7));
                            
                            Coder.skip(1)
                            [~,linestr] = Coder.current;
                            
                            ii = ii+1;
                            
                            if linestr == ""
                                break;
                            else
                                C = textscan(linestr,'%s');
                            end
                        end
                        
                        % structural elements
                        Coder.skip(3)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');  
                        
                        ii = 1;
                        while ischar(linestr)
                            senData(curSenLine).structural_elems(ii).sensor  = char(C{1}(1));
                            senData(curSenLine).structural_elems(ii).type    = char(C{1}(2));
                            senData(curSenLine).structural_elems(ii).m       = str2double(C{1}(3));
                            senData(curSenLine).structural_elems(ii).neq     = str2double(C{1}(4));
                            senData(curSenLine).structural_elems(ii).value   = str2double(C{1}(5));
                            senData(curSenLine).structural_elems(ii).unit    = char(C{1}(6));
                            
                            Coder.skip(1)
                            [~,linestr] = Coder.current;
                            
                            ii = ii+1;
                            
                            if linestr == ""
                                break;
                            else
                                C = textscan(linestr,'%s');
                            end
                        end
                        
                        % gears
                        Coder.skip(3)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');  
                        
                        ii = 1;
                        while ischar(linestr)
                            senData(curSenLine).gears(ii).name = char(C{1}(1));
                            senData(curSenLine).gears(ii).sensor  = char(C{1}(2));
                            senData(curSenLine).gears(ii).type    = char(C{1}(3));
                            senData(curSenLine).gears(ii).ratio   = str2double(C{1}(4));
                            senData(curSenLine).gears(ii).m       = str2double(C{1}(5));
                            senData(curSenLine).gears(ii).neq     = str2double(C{1}(6));
                            senData(curSenLine).gears(ii).value   = str2double(C{1}(7));
                            senData(curSenLine).gears(ii).unit    = char(C{1}(8));
                            
                            Coder.skip(1)
                            [~,linestr] = Coder.current;
                            
                            ii = ii+1;
                            
                            if linestr == ""
                                break;
                            else
                                C = textscan(linestr,'%s');
                            end
                        end
                        
                        % torque_ranges
                        Coder.skip(3)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');  
                        
                        ii = 1;
                        while ischar(linestr)

                            senData(curSenLine).torque_ranges(ii).sensor  = char(C{1}(1));
                            senData(curSenLine).torque_ranges(ii).unit    = char(C{1}(2));
                            senData(curSenLine).torque_ranges(ii).type    = char(C{1}(3));    
                            senData(curSenLine).torque_ranges(ii).value   = str2double(C{1}(4));
                            
                            Coder.skip(1)
                            [~,linestr] = Coder.current;
                            
                            ii = ii+1;
                            
                            if linestr == ""
                                break;
                            else
                                C = textscan(linestr,'%s');
                            end
                        end
                        
                        % shafts
                        Coder.skip(3)
                        [~,linestr] = Coder.current;
                        C = textscan(linestr,'%s');  
                        
                        ii = 1;
                        while ischar(linestr)

                            senData(curSenLine).shafts(ii).name    = char(C{1}(1));
                            senData(curSenLine).shafts(ii).sensor  = char(C{1}(2));
                            senData(curSenLine).shafts(ii).type    = char(C{1}(3));
                            senData(curSenLine).shafts(ii).m       = str2double(C{1}(4));
                            senData(curSenLine).shafts(ii).neq     = str2double(C{1}(5));
                            senData(curSenLine).shafts(ii).value   = str2double(C{1}(6));
                            senData(curSenLine).shafts(ii).unit    = char(C{1}(7));
                            
                            Coder.skip(1)
                            [~,linestr] = Coder.current;
                            
                            ii = ii+1;
                            
                            if linestr == ""
                                break;
                            else
                                C = textscan(linestr,'%s');
                            end
                        end                  
%                        a=1
                end
                eval(['s.' sectionName{decodeID} ' = senData;']);
            end
            
        end
        
        function encode(self, FID, s)
            
        end
    end
    
    methods (Access=private)
        
        function output = getIncludedFile(~, files, name)
            for i = 1: length(files)
                if strcmpi(files{i}.Type, name)
                    output = files{i};
                    break
                end
            end
        end
    end
end
