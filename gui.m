function varargout = gui(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 06-Sep-2018 20:35:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

%%%%%%%%%%%default_config
handles.recObj = audiorecorder(44100, 16, 1, -1);
handles.recObj.TimerFcn = {@RecDisplay, handles};
handles.recObj.TimerPeriod=0.25;
handles.playSpeed=1;

%%%%%%%%%%%icon
icon_start = imread('./icon/start.png') ;
icon_start = imresize(icon_start, 0.5) ;
set(handles.start,'CDATA',icon_start) ; 

icon_play = imread('./icon/play.png') ;
icon_play = imresize(icon_play, 0.5) ;
set(handles.play,'CDATA',icon_play); 

icon_stop = imread('./icon/stop.png');
icon_stop = imresize(icon_stop, 0.5);
set(handles.stop, 'CDATA', icon_stop); 

%%%%%%%%%%%switch
set(handles.stop, 'Enable', 'off');
set(handles.start, 'Enable', 'off');
set(handles.play, 'Enable', 'off');
 
%%%%%%%%%%%load lstm model
load('.\model6362.mat') ;
handles.net = net;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in select.
function select_Callback(hObject, eventdata, handles)
% hObject    handle to select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile('.wav', '请选择音频(仅支持wav格式)');
%handles.fpath = [filename, pathname] ;
handles.wav = audioread([pathname filename], 'native')
handles.info = audioinfo([pathname filename])
%set(handels.play, 'Enable', 'on') ;
guidata(hObject, handles) ;



% --- Executes on button press in record.
function record_Callback(hObject, eventdata, handles)
% hObject    handle to record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.start, 'Enable', 'on');
set(handles.stop, 'Enable', 'on');
set(handles.play, 'Enable', 'on');
guidata(hObject, handles);


% --- Executes on button press in recongizate.
function recongizate_Callback(hObject, eventdata, handles)
% hObject    handle to recongizate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.wav = myVAD(handles.wav) ;
handles.info.Duration = double(length(handles.wav)/handles.info.SampleRate) ;
featVec = fbank(handles.wav, handles.info) ;
handles.result = classify(handles.net, featVec')

guidata(hObject, handles) ;
set(handles.edit1, 'string', sprintf('识别结果为%s',handles.result)) ;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.edit1, 'string', '录音中...')
record(handles.recObj) ;


% --- Executes on button press in play.
function play_Callback(hObject, eventdata, handles)
% hObject    handle to play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.myRecording = getaudiodata(handles.recObj) ;
handles.playObj = audioplayer(handles.myRecording,handles.playSpeed*handles.recObj.SampleRate) ;
play(handles.playObj) ;
plot(handles.axes1,(1:length(handles.myRecording))/handles.recObj.SampleRate,handles.myRecording,'color','g')
guidata(hObject, handles) ;


% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.recObj)

handles.wav = getaudiodata(handles.recObj) ;
handles.info.Duration = handles.recObj.TimerPeriod ;
handles.info.SampleRate = handles.recObj.SampleRate ;
guidata(hObject, handles) ;



function RecDisplay(hObject, eventdata,handles)
%handles
handles.wav = getaudiodata(handles.recObj) ;
%axes(handles.axes1)
plot(handles.axes1, (1:length(handles.wav))/handles.recObj.SampleRate, handles.wav, 'color', 'g')

drawnow ;




function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


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
