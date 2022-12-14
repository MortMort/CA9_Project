function DLC12(raw,fidout)

% to write the DLC 1.2 with mass and pitch offset on 1/2/3 blades
%% identifying the pitch offset based on DLC:21PSBB and mass offset from DLC12
pidx=find(contains(raw.LoadCaseNames,'21PSBB'));
midx=find(contains(raw.LoadCaseNames,'12IceU'));

if ~isempty(pidx)
    pioffv=regexp(raw.LoadCases{pidx(1)}{3},'(?<=pioff\s+\-)\d+\.\d+','match');
else
    prompt={'Input pitch offset for DLC12'};title='DLC12: Pitch input'; 
    definput={'1.25'};
    userinput1=inputdlg(prompt,title,[1 50],definput);
    pioffv=userinput1(1);
end

if ~isempty(midx)
    for i =1:length(midx)
        tempmfacv(i)=regexp(raw.LoadCases{midx(i)}{3},'(?<=mfac\s+)\d+\.\d+','match');
    end
    mfacv=max(str2double(tempmfacv));
else
    prompt={'Input mass offset for DLC12'};title='DLC12: mass input'; 
    definput={'1.092'};
    userinput1=inputdlg(prompt,title,[1 50],definput);
    mfacv=str2num(userinput1{1});    
end
%% 
% wsp_keys={'Vin','Vrat','Vr-2','Vr+2','Vout'};
wsp_keys={'Vin','Vr-2','Vrat','Vr+2','Vout'};
wsp_vin=round(raw.WindSpeeds(wsp_keys{1}));
wsp_vratm=round(raw.WindSpeeds(wsp_keys{2}));
wsp_vrat=round(raw.WindSpeeds(wsp_keys{3}));
wsp_vratp=round(raw.WindSpeeds(wsp_keys{end-1}));
wsp_vout=round(raw.WindSpeeds(wsp_keys{end}));
wsp_values=[wsp_vin,wsp_vratm,wsp_vrat,wsp_vratp,wsp_vout];
disp('4. Writing DLC12 with mass and pitchoffset');

fprintf(fidout,'**** DLC 1.2 with pitch and mass offset \n\n');

    for k=1:length(wsp_keys)
    wsp=round(raw.WindSpeeds(wsp_keys{k}));
    
        for j=1:3
            mvec=[1.000 1.000 1.000];
            mvec(1:j)=mvec(1:j).*mfacv;
            
            fprintf(fidout,['12Ice' num2str(j) 'U' num2str(wsp,'%0.2d') 'ms Prod. at ' num2str(wsp) 'm/s with Ice on ' num2str(j) ' blade'   '\n']);
            fprintf(fidout,['ntm 1 - 6 Freq 0 LF 1.35 \n']);
            fprintf(fidout,['0.1' ' 2 ' wsp_keys{k} ' 0']);
            if wsp>=wsp_vrat-1
                fprintf(fidout,[' Vhub ' num2str(wsp_vratm) ' -2000 -1800 Vhub ' num2str(wsp_values(k)) ' -1300 -1000']);
            end    
            fprintf(fidout,[' mfac ' num2str(mvec,'%4.4f\t') ' rho 1.325 pioff -' num2str(str2double(pioffv)) ' 0 ' num2str(str2double(pioffv))]);
            fprintf(fidout,[ '\n\n']);    
        end
    end
end