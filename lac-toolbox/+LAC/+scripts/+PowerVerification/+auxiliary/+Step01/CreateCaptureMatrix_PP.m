function [CapturMatrx,CapturMatrx_table,TI,MeanWindSpeed_vec] = CreateCaptureMatrix_PP(sens,data,WTG,bin_Vn)

% Update:
% 06/05/2019 - MODFY - To fit power performance verification
% To add the bin size in function of the WTG input: WTG.BinSize

% WTG.CutOutWSP = floor(WTG.CutOutWSP);

if bin_Vn==1
    MeanWindSpeed = data.dat1.mean(:,sens.WSPnorm);
else
    MeanWindSpeed = data.dat1.mean(:,sens.WSP);
end
MeanWindSpeed_vec = [data.dat1.mean(:,sens.WSP) data.dat1.mean(:,sens.WSPnorm)];

TI = data.dat1.mean(:,sens.turb)*100;
max_TI = max(TI);
CapturMatrx = [];

WSbin_vec = (WTG.CutInWSP-1-WTG.WSBinSize/2):WTG.WSBinSize:WTG.CutOutWSP+WTG.WSBinSize/2;
        
    for ibin = 1:length(WSbin_vec)-1
        index1 = (MeanWindSpeed > WSbin_vec(ibin) & MeanWindSpeed <= WSbin_vec(ibin+1) );
        TIs_in_WindBin = TI(index1);
        WindBinColumn = [];
        clear index1;
        
        for TIbin = 1:2:max_TI
           index2 = find(TIs_in_WindBin > TIbin & TIs_in_WindBin <= TIbin+2);
           WindBinColumn = [WindBinColumn;length(index2)];
           clear index2;
        end;
        
       CapturMatrx = [CapturMatrx WindBinColumn];
       
       clear WindBinColumn;
       clear TIbin;
       clear TIs_in_WindBin;   
    end;
    
    clear ibin


%--- creating capture matrix in text format which can be exported easily to word report
   if size(CapturMatrx,1)< 15
       CapturMatrx = [CapturMatrx;zeros(15-size(CapturMatrx,1),size(CapturMatrx,2))];
   elseif size(CapturMatrx,1)== 15
       % do nothing;
   else 
       CapturMatrx = [CapturMatrx(1:14,:);sum(CapturMatrx(15:size(CapturMatrx,1),:))];
   end

    for i=1:size(CapturMatrx,1)
        for j=1:size(CapturMatrx,2)
            if CapturMatrx(i,j)==0
                 CapturMatrx_str{i,j}='';
            else
            CapturMatrx_str{i,j}=num2str(CapturMatrx(i,j));
            end
        end
    end
    clear i j;
                    
    % Added by MODFY to suit Power Performance V117
    Wind_bin_row = cell(1,round(length(WSbin_vec-1)/2)-1);
    Wind_bin_row{1} = 'WindSpeedBin(m/s)=> TI_bin_(%)';
    i_bin_row=2;
    for i=1:length(WSbin_vec)-1
        Wind_bin_row{i_bin_row} = char(strcat(num2str(WSbin_vec(i)),'-',num2str(WSbin_vec(i+1))));
        i_bin_row = i_bin_row+1;
    end
    clear i i_bin_row

    % End Added by MODFY
                    
    TI_bin_column = {'< 3 %';'3-5 %';'5-7 %';'7-9 %';'9-11 %';'11-13 %';'13-15 %';'15-17 %';'17-19 %';'19-21 %';'21-23 %';'23-25 %';'25-27 %';'27-29 %';'>29 %'};
    WS_bin_row = Wind_bin_row;                    

    % Write number of data sets in WSP_bin
    number_of_datasets = sum(CapturMatrx); 
    for i=1:size(number_of_datasets,2)    
        if number_of_datasets(i)==0
             number_of_datasets_str{1,i}='-';
        else
        number_of_datasets_str{1,i}=num2str(number_of_datasets(1,i));
        end;
    end; clear i ;
                    
    % Write number of TI_bins with at least 3 time series
    for i=1:size(CapturMatrx,2)
        % For wind speeds below 16 m/s, one TI_bin with more than 8 times series is needed
        if i <= 13 && length(find(CapturMatrx(:,i) > 6))>=1 
            ReqNOTI_BINS{1,i}=num2str(length(find(CapturMatrx(:,i) > 6)));
            TI_req(i) = 1;
        % For wind speeds above 16 m/s, only number of time series per wsp_bin is needed    
        elseif round(WTG.NomSpeed)-4  && length(find(CapturMatrx(:,i) > 6))<1
            ReqNOTI_BINS{1,i}='0';
            TI_req(i) = 0;
        elseif i > 13 
            ReqNOTI_BINS{1,i} = 'nan';
        end
    end
    clear i ;

%            Modified by MODFY for Power Performance Verification of V117 
%           The conditions to fulfill, based on IEC Standards, are: 
%           - each bin includes a minimum of 30 min sampled data -> 3 time series
%           - the database includes a minimum of 180h of sampled data (this
%               is fulfilled by all the measurement campaign)
%           - moreover, data should be available from Vin-1 m/s to 1.5*Vn1 
%               with P(Vn1) = 0.85 Prated
        
                    % Write if data capture requirements have been meet
                    
                    for i=1:size(CapturMatrx,2)
                    % For the wsp captured, 3 time series per bin are
                    % necessary 

                            if number_of_datasets(1,i) >=3 && sum(number_of_datasets) >= (180*60/10)
                                Req_meet{1,i} = 'Yes';
                            else
                                Req_meet{1,i} = 'No';
                            end
                    
%                     % the second condition is fulfilled if the 1st
%                     % condition is fulfilled in the range Vin-1 to Vn1
%                     
%                             if WTG.per85WSP > bin_ext(2*i-1) && strcmp(Req_meet{1,i},'Yes')
%                                 Req_meet{2,i} = 'Yes';
%                             else
%                                 Req_meet{2,i} = 'No';
%                             end 

                    end
                    clear i ;
%                     clear Req_meet_binary;
%             End of modification by MODFY for Power Performance

                CapturMatrx_table = ...
                [WS_bin_row; TI_bin_column CapturMatrx_str;...
                {'Total number of datasets available'},number_of_datasets_str;...
                {'No. of TI bins following min. data req'},ReqNOTI_BINS;...
                {'Minimum Data requirements meet'},Req_meet];

                CapturMatrx_table = [CapturMatrx_table];