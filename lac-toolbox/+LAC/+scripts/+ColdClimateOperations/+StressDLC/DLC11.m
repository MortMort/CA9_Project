function DLC11(raw,fidout,Turb,Transition)

% to write the DLC 1.1 with low and default turbulence
% inputs
%
% output

wsp_keys={'Vin','Vr-2','Vrat','Vr+2','Vout'};
wsp_vin=round(raw.WindSpeeds(wsp_keys{1}));
wsp_vratm=round(raw.WindSpeeds(wsp_keys{2}));
wsp_vrat=round(raw.WindSpeeds(wsp_keys{3}));
wsp_vratp=round(raw.WindSpeeds(wsp_keys{end-1}));
wsp_vout=round(raw.WindSpeeds(wsp_keys{end}));
wsp_values=[wsp_vin,wsp_vratm,wsp_vrat,wsp_vratp,wsp_vout];
wsp=wsp_vin:2:wsp_vout;

    if nargin>4
        disp('4. Writing DLC11 with Cp reduction');

        fprintf(fidout,'**** DLC 1.1 with default turb and Cp reduction  \n\n');
        for k=1:length(wsp)

        fprintf(fidout,['11' num2str(wsp(k),'%0.2d') 'aNTM Prod. ' num2str(wsp(k)) ' - ' num2str(wsp(k)+1) 'm/s Wdir=0 '   '\n']);
        fprintf(fidout,['ntm 1 - 6 Weib ' num2str(wsp(k)) ' ' num2str(wsp(k)+1) ' 1 LF 1.35 \n']);
        fprintf(fidout,['0.1' ' 2 ' num2str(wsp(k)) ' 0  rho 1.325']);
        if wsp(k)>=wsp_vrat-1
            fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp(k)) ' -1300 -1000']);
        end
        fprintf(fidout,[ '\n\n']);    
        end

    elseif nargin==4

    disp('1. Writing DLC11 to capture transition lambda optimal, to TL, to FL and vice-versa');
    
    fprintf(fidout,'**** DLC 1.1 with 0per turbulence to check the shift of transition from lambda optimal, to TL, to FL and vice-versa  \n\n');
    Time=(50:50:600)';
        for k=2:length(wsp_keys)
%             wsp_vin=round(raw.WindSpeeds(wsp_keys{1}));
            wsp2=round(raw.WindSpeeds(wsp_keys{k}));

            wsp_dif=wsp2-wsp_vin;
            seed = 1;

            %Vin to xx
            fprintf(fidout,['11' num2str(wsp_vin,'%0.2d') 'aT0S' num2str(k) ' Prod. ' num2str(wsp_keys{1}) ' m/s to ' num2str(wsp_keys{k}) ' Wdir=0 and T=0.0'   '\n']);
            fprintf(fidout,['ntm ' num2str(seed) ' freq 0 LF 1.35 \n']);
            fprintf(fidout,['0.1' ' 2 ' num2str(wsp_vin) ' 0 turb 0.0 rho 1.325']);
%             if wsp2>=wsp_vrat
%                 fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp_values(k)) ' -1300 -1000']);
%             end


            for i=1:length(Time)-1
                fprintf(fidout,[' Vhub ' num2str(wsp_vin + wsp_dif*(1-cos(pi*i/length(Time)))*0.5) ' ' num2str(Time(i)) ' ' num2str(Time(i+1))]);
            end
            fprintf(fidout,[ '\n\n']);

            %xx to Vin
            fprintf(fidout,['11' num2str(wsp2,'%0.2d') 'aT0S' num2str(k) ' Prod. ' num2str(wsp_keys{k}) ' m/s to ' num2str(wsp_keys{1}) ' Wdir=0 and T=0.0'   '\n']);
            fprintf(fidout,['ntm ' num2str(seed) ' freq 0 LF 1.35 \n']);
            fprintf(fidout,['0.1' ' 2 ' num2str(wsp2) ' 0 turb 0.0 rho 1.325']);
            if wsp2>=wsp_vrat-1
                fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp_values(k)) ' -1300 -1000']);
            end


            for i=1:length(Time)-1
                fprintf(fidout,[' Vhub ' num2str(wsp2 - wsp_dif*(1-cos(pi*i/length(Time)))*0.5) ' ' num2str(Time(i)) ' ' num2str(Time(i+1))]);
            end
            fprintf(fidout,[ '\n\n']);    
        end    
    elseif nargin==3

        disp('2. Writing DLC11 with 10% turb');

        fprintf(fidout,'**** DLC 1.1 with 10per turb  \n\n');
        for k=1:length(wsp)

            fprintf(fidout,['11' num2str(wsp(k),'%0.2d') 'aT10 Prod. ' num2str(wsp(k)) ' - ' num2str(wsp(k)+1) 'm/s Wdir=0 and T=10.0'   '\n']);
            fprintf(fidout,['ntm 1 - 6 Weib ' num2str(wsp(k)) ' ' num2str(wsp(k)+1) ' 1 LF 1.35 \n']);
            fprintf(fidout,['0.1' ' 2 ' num2str(wsp(k)) ' 0 turb ' num2str(Turb/100) ' rho 1.325']);
            if wsp(k)>=wsp_vrat-1
                fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp(k)) ' -1300 -1000']);
            end
            fprintf(fidout,[ '\n\n']);    
        end
    else
        disp('3. Writing DLC11');

        fprintf(fidout,'**** DLC 1.1 with default turb  \n\n');
        for k=1:length(wsp)

        fprintf(fidout,['11' num2str(wsp(k),'%0.2d') 'aNTM Prod. ' num2str(wsp(k)) ' - ' num2str(wsp(k)+1) 'm/s Wdir=0 '   '\n']);
        fprintf(fidout,['ntm 1 - 6 Weib ' num2str(wsp(k)) ' ' num2str(wsp(k)+1) ' 1 LF 1.35 \n']);
        fprintf(fidout,['0.1' ' 2 ' num2str(wsp(k)) ' 0  rho 1.325']);
        if wsp(k)>=wsp_vrat-1
            fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp(k)) ' -1300 -1000']);
        end
        fprintf(fidout,[ '\n\n']);    
        end
    end
end

%% Include a stress case where the Cp is reduced which has an effect on the wind speed lower by xx%
% Px_OTC_DegrProfile_CpEstGain 
% Px_OTC_DegrProfile_CpEstOffset 
 
