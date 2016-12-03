function varargout = projectortrackergui(varargin)
% PROJECTORTRACKERGUI MATLAB code for projectortrackergui.fig
%      PROJECTORTRACKERGUI, by itself, creates a new PROJECTORTRACKERGUI or raises the existing
%      singleton*.
%
%      H = PROJECTORTRACKERGUI returns the handle to a new PROJECTORTRACKERGUI or the handle to
%      the existing singleton*.
%
%      PROJECTORTRACKERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROJECTORTRACKERGUI.M with the given input arguments.
%
%      PROJECTORTRACKERGUI('Property','Value',...) creates a new PROJECTORTRACKERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before projectortrackergui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to projectortrackergui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help projectortrackergui

% Last Modified by GUIDE v2.5 12-Oct-2016 15:53:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @projectortrackergui_OpeningFcn, ...
                   'gui_OutputFcn',  @projectortrackergui_OutputFcn, ...
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


% --- Executes just before projectortrackergui is made visible.
function projectortrackergui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to projectortrackergui (see VARARGIN)

% Choose default command line output for projectortrackergui
handles.output = hObject;
set(handles.threshold_slider,'value',40);
set(gca,'Xtick',[],'Ytick',[]);

%% Query available camera and modes
imaqreset
c=imaqhwinfo;

% Select appropriate adaptor for connected camera
for i=1:length(c.InstalledAdaptors)
    camInfo=imaqhwinfo(c.InstalledAdaptors{i});
    if ~isempty(camInfo.DeviceIDs)
        adaptor=i;
    end
end
camInfo=imaqhwinfo(c.InstalledAdaptors{adaptor});

% Set the device to default format and populate pop-up menu
if ~isempty(camInfo.DeviceInfo.SupportedFormats);
set(handles.Cam_popupmenu,'String',camInfo.DeviceInfo.SupportedFormats);
default_format=camInfo.DeviceInfo.DefaultFormat;

    for i=1:length(camInfo.DeviceInfo.SupportedFormats)
        if strcmp(default_format,camInfo.DeviceInfo.SupportedFormats{i})
            set(handles.Cam_popupmenu,'Value',i);
            camInfo.ActiveMode=camInfo.DeviceInfo.SupportedFormats(i);
        end
    end
    
else
set(handles.Cam_popupmenu,'String','Camera not detected');
end
handles.camInfo=camInfo;


%% Initialize teensy for motor and light board control

%Close and delete any open serial objects
if ~isempty(instrfindall)
fclose(instrfindall);           % Make sure that the COM port is closed
delete(instrfindall);           % Delete any serial objects in memory
end

% Attempt handshake with light panel teensy
[handles.teensy_port,ports]=identifyMicrocontrollers;

% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',handles.teensy_port);

% Initialize light panel at default values
IR_intensity=str2num(get(handles.edit_IR_intensity,'string'));
White_intensity=str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
handles.IR_intensity=uint8((IR_intensity/100)*255);
handles.White_intensity=uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(handles.teensy_port,1,handles.IR_intensity);
writeInfraredWhitePanel(handles.teensy_port,0,handles.White_intensity);

%% Initialize experiment parameters from text boxes in the GUI
handles.ref_stack_size=str2num(get(handles.edit_ref_stack_size,'String')); %#ok<*ST2NM>
handles.ref_freq=str2num(get(handles.edit_ref_freq,'String'));
handles.exp_duration=str2num(get(handles.edit_exp_duration,'String'));
handles.camInfo.Gain=str2num(get(handles.edit_gain,'String'));
handles.camInfo.Exposure=str2num(get(handles.edit_exposure,'String'));
handles.camInfo.Shutter=str2num(get(handles.edit_cam_shutter,'String'));
handles.tracking_thresh=get(handles.threshold_slider,'Value');
handles.pixel_step_size=str2num(get(handles.edit_pixel_step_size,'String'));
handles.reg_spot_r=str2num(get(handles.edit_reg_spot_r,'String'));
handles.step_interval=str2num(get(handles.edit_step_interval,'String'));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes projectortrackergui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = projectortrackergui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in microcontroller_popupmenu.
function microcontroller_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns microcontroller_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from microcontroller_popupmenu


% --- Executes during object creation, after setting all properties.
function microcontroller_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Cam_popupmenu.
function Cam_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
strCell=get(handles.Cam_popupmenu,'string');
handles.camInfo.ActiveMode=strCell(get(handles.Cam_popupmenu,'Value'));
guidata(hObject, handles);


% Hints: contents = cellstr(get(hObject,'String')) returns Cam_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Cam_popupmenu

% --- Executes during object creation, after setting all properties.
function Cam_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_IR_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Initialize light panel at default values
handles.IR_intensity=str2num(get(handles.edit_IR_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
handles.IR_intensity=uint8((handles.IR_intensity/100)*255);

writeInfraredWhitePanel(handles.teensy_port,1,handles.IR_intensity);

% --- Executes during object creation, after setting all properties.
function edit_IR_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_White_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
White_intensity=str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
handles.White_intensity=uint8((White_intensity/100)*255);
writeInfraredWhitePanel(handles.teensy_port,0,handles.White_intensity);

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_White_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_exposure_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.camInfo.Exposure=str2num(get(handles.edit_exposure,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Exposure=handles.camInfo.Exposure;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_gain_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.camInfo.Gain=str2num(get(handles.edit_gain,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Gain=handles.camInfo.Gain;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in save_path_button1.
function save_path_button1_Callback(hObject, eventdata, handles)
% hObject    handle to save_path_button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fpath] = uigetdir('E:\Decathlon Raw Data','Select a save destination');
handles.fpath=fpath;
set(handles.save_path,'String',fpath);
guidata(hObject,handles);



function save_path_Callback(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of save_path as text
%        str2double(get(hObject,'String')) returns contents of save_path as a double


% --- Executes during object creation, after setting all properties.
function save_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Cam_confirm_pushbutton.
function Cam_confirm_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_confirm_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
imaqreset;
pause(0.02);
handles.vid=initializeCamera(handles.camInfo);
handles.src=getselectedsource(handles.vid);
start(handles.vid);
pause(0.1);
im=peekdata(handles.vid,1);
handles.hImage=image(im);
set(gca,'Xtick',[],'Ytick',[]);
stop(handles.vid);
guidata(hObject, handles);


% --- Executes on button press in Cam_preview_pushbutton.
function Cam_preview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_preview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'vid') == 0
    errordlg('Please confirm camera settings')
else
    preview(handles.vid,handles.hImage);       
end


% --- Executes on button press in Cam_stopPreview_pushbutton.
function Cam_stopPreview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_stopPreview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Cam_preview_pushbutton,'Value',0);
set(handles.Cam_stopPreview_pushbutton,'Value',0);
stoppreview(handles.vid);
rmfield(handles,'src');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function labels_uitable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
data=cell(5,8);
data(:)={''};
set(hObject, 'Data', data);
handles.labels=data;
guidata(hObject, handles);


% --- Executes when entered data in editable cell(s) in labels_uitable.
function labels_uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
handles.labels{eventdata.Indices(1), eventdata.Indices(2)} = {''};
handles.labels{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;
guidata(hObject, handles);


function edit_ref_stack_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ref_stack_size=str2num(get(handles.edit_ref_stack_size,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_ref_stack_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ref_freq_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ref_freq=str2num(get(handles.edit_ref_freq,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_ref_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_exp_duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.exp_duration=str2num(get(handles.edit_exp_duration,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_exp_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'fpath') == 0 
    errordlg('Please specify Save Location')
elseif isfield(handles, 'vid') == 0
    errordlg('Please confirm camera settings')
else
    switch handles.experiment
    	case 2
            projector_escape_response;
        case 3
            projector_optomotor;
        case 4
            projector_slow_phototaxis;
    end
end


% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tracking_thresh=get(handles.threshold_slider,'Value');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_thresh_pushbutton.
function accept_thresh_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_thresh_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.accept_thresh_pushbutton,'value',1);
guidata(hObject, handles);



function edit_frame_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_rate as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_rate as a double


% --- Executes during object creation, after setting all properties.
function edit_frame_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in exp_select_popupmenu.
function exp_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.experiment=get(handles.exp_select_popupmenu,'Value');
guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns exp_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from exp_select_popupmenu


% --- Executes during object creation, after setting all properties.
function exp_select_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in begin_reg_button.
function begin_reg_button_Callback(hObject, eventdata, handles)
% hObject    handle to begin_reg_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Turn infrared and white background illumination off during registration
writeInfraredWhitePanel(handles.teensy_port,1,0);
writeInfraredWhitePanel(handles.teensy_port,0,0);

msg_title=['Projector Registration Tips'];
spc=[' '];
intro=['Please check the following before continuing to ensure successful registration:'];
item1=['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
    'Make sure the projector is the only light source visible to the camera'];
item2=['2.) Camera is not imaging through infrared filter. '...
    'Projector display should be visible through the camera.'];
item3=['3.) Projector is turned on and set to desired resolution.'];
item4=['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
    ' This will appear as moving streaks in the camera if not properly adjusted.'];
item5=['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
    ' after registration.'];
closing=['Click OK to continue with the registration'];
message={intro spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display registration tips
waitfor(msgbox(message,msg_title));

% Register projector
reg_projector(handles.camInfo,handles.pixel_step_size,handles.step_interval,handles.reg_spot_r,handles.edit_time_remaining);

% Reset infrared and white lights to prior values
writeInfraredWhitePanel(handles.teensy_port,1,handles.IR_intensity);
writeInfraredWhitePanel(handles.teensy_port,0,handles.White_intensity);

guidata(hObject, handles);


function edit_reg_spot_r_Callback(hObject, eventdata, handles)
% hObject    handle to edit_reg_spot_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.reg_spot_r=str2num(get(handles.edit_reg_spot_r,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_reg_spot_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_reg_spot_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_pixel_step_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pixel_step_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.pixel_step_size=str2num(get(handles.edit_pixel_step_size,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_pixel_step_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pixel_step_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_cam_shutter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.camInfo.Shutter=str2num(get(handles.edit_cam_shutter,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Shutter=handles.camInfo.Shutter;
end

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit_cam_shutter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_step_interval_Callback(hObject, eventdata, handles)
% hObject    handle to edit_step_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.step_interval=str2num(get(handles.edit_step_interval,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_step_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_step_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_time_remaining_Callback(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_time_remaining as text
%        str2double(get(hObject,'String')) returns contents of edit_time_remaining as a double


% --- Executes during object creation, after setting all properties.
function edit_time_remaining_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exp_parameter_pushbutton.
function exp_parameter_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to exp_parameter_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.experiment<2
errordlg('Please select an experiment first')
else
    switch handles.experiment
        case 2

        case 3
            exp_parameters=optomotor_parameter_gui
        case 4
            exp_parameters=slowphototaxis_parameter_gui
    end
    handles.exp_parameters=exp_parameters;
end
guidata(hObject,handles);


% --- Executes on button press in refresh_COM_pushbutton.
function refresh_COM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_COM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Refresh items on the COM ports
   
% Attempt handshake with light panel teensy
[handles.teensy_port,ports]=identifyMicrocontrollers;

if ~isempty(ports)
% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',handles.teensy_port);
else
set(handles.microcontroller_popupmenu,'string','COM not detected');
end


guidata(hObject,handles);