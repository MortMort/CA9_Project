function varargout = plot_profile(varargin)
%      PLOT PROFILE MATLAB code for plot_profile.fig
%      PLOT_PROFIle, by itself, creates a new PLOT_PROFI or raises the existing
%      singleton*.
%
%      H = PLOT_PROFILE returns the handle to a new PLOT_PROFILE or the handle to
%      the existing singleton*.
%
%      PLOT_PROFILE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOT_PROFILE.M with the given input arguments.
%
%      PLOT_PROFILE('Property','Value',...) creates a new PLOT_PROFILE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plot_profile_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plot_profile_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Created by KAVAS 10-June-2020

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plot_profile_OpeningFcn, ...
                   'gui_OutputFcn',  @plot_profile_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end
% --- Executes just before plot_profile is made visible.
function plot_profile_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plot_profile (see VARARGIN)

% Choose default command line output for plot_profile
% Update handles structure

% UIWAIT makes plot_profile wait for user response (see UIRESUME)
% uiwait(handles.figure1);

end

% --- Outputs from this function are returned to the command line.
function varargout = plot_profile_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get file file names from loading directory/folder

[filename,filefolder]= uigetfile('*.PRO', 'Multiselect','on');

% Show all profi files names in the listbox
set(handles.listbox1,'String',filename);

% Reset selection for all loaded files
for jj = 1:length(filename)
set(handles.listbox1,'Value',jj);

listStr = get(handles.listbox1,'String');
listVal = get(handles.listbox1,'Value');

% assignin('base','listVal',listVal);
% assignin('base','listStr',listStr);
% assignin('base','filename',filename);
handles.filename= filename;

if (iscell(listStr))
    fID=fopen(fullfile(filefolder,filename{jj}),'r');
else
    fID=fopen(fullfile(filefolder,filename),'r');
end
 
header=fgetl(fID);
Npolar=str2double(fgetl(fID));
tcs=str2num(fgetl(fID));
Lpolar=str2double(fgetl(fID));

    for i = 1:Npolar
        Polars{jj,i}.header=fgetl(fID);
        for j = 1:Lpolar
            Polars{jj,i}.data(j,:)=str2num(fgetl(fID));
        end
        Polars{jj,i}.alpha=Polars{jj,i}.data(:,1);
        Polars{jj,i}.CL=Polars{jj,i}.data(:,2);
        Polars{jj,i}.CD=Polars{jj,i}.data(:,3);
        Polars{jj,i}.CM=Polars{jj,i}.data(:,4);

    end
thickness{jj,:}=tcs;
fclose(fID);
end


number = length(filename);
handles.number= length(filename);

if (iscell(listStr))
    for jj = 1:number
        % [left bottom width height]
        % left:	Distance from the inner left edge of the parent container to the outer left edge of the uicontrol
        % bottom:	Distance from the inner bottom edge of the parent container to the outer bottom edge of the uicontrol
        % width:	Distance between the right and left outer edges of the uicontrol
        % height:	Distance between the top and bottom outer edges of the uicontrol
        title_profi(jj)= uicontrol(handles.uipanel2,'Style','text','String',filename{jj},'Units','normalized','Position',[jj/11-1/11 0.9 1/11 0.1]);
        
            for i = 1:length(thickness{jj})
            t = i/40;
            thicknesses_profi(jj,i) = uicontrol(handles.uipanel2,'Style','checkbox','String',thickness{jj,1}(i),'Units','normalized','Position',[jj/11-1/11 0.95-t 1/11 0.03]);
            load_thickness(jj,i) = Polars{jj,i};
            thicknesses_profi_2(jj,i) = (thicknesses_profi(jj,i));
            end    
    end
else
    title_profi= uicontrol(handles.uipanel2,'Style','text','String',filename,'Units','normalized','Position',[0 0.9 0.1 0.1]);
    for i = 1:length(tcs)
        t = i/40;
        thicknesses_profi(i) = uicontrol(handles.uipanel2,'Style','checkbox','String',thickness{1,1}(i),'Units','normalized','Position',[0 0.95-t 0.05 0.03]);
        load_thickness(1,i) = Polars(1,i);
        thicknesses_profi_2(1,i) = (thicknesses_profi(1,i));
%         assignin('base','thicknesses_profi_2',thicknesses_profi_2);
%         assignin('base','load_thickness',load_thickness);
    end    

end
 
handles.load_thickness= Polars;
handles.thickness = thickness;
handles.thicknesses_profi_2 = thicknesses_profi_2;
handles.thicknesses_profi = thicknesses_profi;
handles.title_profi=title_profi;
guidata(gcbo, handles);

% assignin('base','Polars',Polars);
% assignin('base','thickness',thickness);

end

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject, handles);
% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1
end

% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in pushbutton.
function pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = handles.number;
load_thickness= handles.load_thickness;
thickness = handles.thickness;
thicknesses_profi_2 = handles.thicknesses_profi_2;
filename = handles.filename;
thicknesses_profi = handles.thicknesses_profi;

u = 1;

    for jj = 1:number
        for i = 1:length(thickness{jj})
            if thicknesses_profi_2(jj,i).Value == thicknesses_profi_2(jj,i).Max
                profi_1_flag(u,:) = [jj,i];
                assignin('base','profi_1_flag',profi_1_flag);
            end
        end
        u = u+1;
    end

f1 = figure;
handles.f1 = f1;
set(handles.f1,'Name','Lift to drag Ratio and Pitching moment coefficient')
set(handles.f1,'units','normalized','outerposition',[0 0 1 1])
Min_x_lim = str2double(get(handles.edit1,'String'));
Max_x_lim = str2double(get(handles.edit2,'String'));

for i = 1:size(profi_1_flag,1)
    if profi_1_flag(i,2) ~=0
    thick_to_display(i) = (thickness{i,1}(profi_1_flag(i,2)));
    end
end
assignin('base','thick_to_display',thick_to_display);

condition = profi_1_flag(:,1)==0 ;
profi_1_flag(condition,:) = [];

condition2 = thick_to_display(1,:)==0 ;
thick_to_display(:,condition2) = [];

for i  = 1:size(profi_1_flag,1)
    j = profi_1_flag(i);
    space = ' t/c = ';
    str{i} = [filename{j} space num2str(thick_to_display(i))];

    hold on
    subplot(2,1,1)
    plot(load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.alpha,load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.CL./load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.CD)
    xlim([Min_x_lim Max_x_lim])
    xlabel('Angle of attack °')
    ylabel('CL/CD')
    if size(profi_1_flag,1)==1
        legend(str{i},'Interpreter', 'none')
    elseif i==size(profi_1_flag,1)
        legend(str,'Interpreter', 'none')
    end
    hold off
    
    hold on
    subplot(2,1,2)
    plot(load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.alpha,load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.CM)
    xlim([Min_x_lim Max_x_lim])
    xlabel('Angle of attack °')
    ylabel('CM')
    if size(profi_1_flag,1)==1
        legend(str{i},'Interpreter', 'none')
    elseif i==size(profi_1_flag,1)
        legend(str,'Interpreter', 'none')
    end
    hold off
    
end
datacursormode off;
dcm = datacursormode(f1);
set(dcm,'UpdateFcn',@customdatatip)
% columnlegend(number/3, str, 'Location', 'northoutside','interpreter','none');


f = figure;
handles.f = f;
set(handles.f,'Name','Lift and Drag coefficient')
set(handles.f,'units','normalized','outerposition',[0 0 1 1])

for i  = 1:size(profi_1_flag)
    j = profi_1_flag(i);
    space = ' t/c = ';
    str{i} = [filename{j} space num2str(thick_to_display(i))];

    hold on
    subplot(2,1,1)
    plot(load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.alpha,load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.CL)
    xlim([Min_x_lim Max_x_lim])
    xlabel('Angle of attack °')
    ylabel('CL')
    if size(profi_1_flag,1)==1
        legend(str{i},'Interpreter', 'none')
    elseif i==size(profi_1_flag,1)
        legend(str,'Interpreter', 'none')
    end
    hold off
    
    hold on
    subplot(2,1,2)
    plot(load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.alpha,load_thickness{profi_1_flag(i,1),profi_1_flag(i,2)}.CD)
    xlim([Min_x_lim Max_x_lim])
    xlabel('Angle of attack °')
    ylabel('CD')
    if size(profi_1_flag,1)==1
        legend(str{i},'Interpreter', 'none')
    elseif i==size(profi_1_flag,1)
        legend(str,'Interpreter', 'none')
    end
    hold off    
end
datacursormode off;
dcm = datacursormode(f);
set(dcm,'UpdateFcn',@customdatatip)
% columnlegend(number/3,str, 'Location', 'northoutside','interpreter','none');


if number <3
    set(thicknesses_profi_2,'Value',0)
% else
%     set(thicknesses_profi_2,'Value',0)
end


guidata(gcbo, handles);
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f = handles.f;
f1 = handles.f1;
close(f)
close(f1)
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
quit
end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
number = handles.number;
thicknesses_profi_2=handles.thicknesses_profi_2;
title_profi = handles.title_profi;

delete(thicknesses_profi_2)
delete(title_profi)
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f = handles.f;
f1 = handles.f1;

hgexport(f1, 'Lift to drag Ratio and Pitching moment coefficient.jpg', hgexport('factorystyle'), 'Format', 'jpeg');
hgexport(f, 'Lift and Drag coefficient.jpg', hgexport('factorystyle'), 'Format', 'jpeg');

end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
end


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
