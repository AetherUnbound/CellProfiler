function CPimagetool(varargin)

% This function opens or updates the Image Tool window when the user clicks
% on an image produced by a module. The tool is embedded by the CPimagesc
% function which is used to display almost all images in CellProfiler. The
% help is contained in a file called ImageToolWindow in the image tools
% folder.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Please see the AUTHORS file for credits.
%
% Website: http://www.cellprofiler.org
%
% $Revision$

% Check that the input argument is an action in the form of a string

handles = guidata(findall(0,'tag','figure1'));
FontSize = handles.Preferences.FontSize;

if ~isempty(varargin)
    action = varargin{1};
    [foo, ImageToolWindowHandle] = gcbo;
    FigHandles = get(ImageToolWindowHandle,'UserData');
    if ishandle(FigHandles.ImageToolWindowHandle)  % The user might have closed the figure with the current image handle, check that it exists!
        ImageHandle = FigHandles.ImageToolWindowHandle;
        switch action
            case {'NewWindow'}        % Show image in a new window
                %%% Retrieves the image data and colormap
                data = get(ImageHandle,'Cdata');
                FigHandle = get(get(ImageHandle,'Parent'),'Parent');
                figure(FigHandle);
                cmap = colormap;
                %%% Opens a new figure window and sets image, colormap and title.
                FigureHandle = figure;
                CPfigure(handles,'Image',FigureHandle);
                CPimagesc(data,handles);
                colormap(cmap);
                Title = char(get(get(get(ImageHandle,'parent'),'title'),'string'));
                title(Title);
                Title = strrep(Title,'_','_');
                set(FigureHandle,'Name',Title);
            case {'Histogram'}                                % Produce histogram (only for scalar images)
                CPfigure(handles);
                data = get(ImageHandle,'Cdata');
                hist(data(:),min(200,round(length(data(:))/150)));
                set(gca,'FontSize',FontSize);
                title(['Histogram for ' get(get(get(ImageHandle,'parent'),'title'),'string')])
                xlabel('Pixel intensity');
                ylabel('Number of pixels'); 
                grid on
            case {'MatlabWS'}                                 % Store image in Matlab base work space
                assignin('base','Image',get(ImageHandle,'Cdata'));
                try CPmsgbox('The image is now saved as the variable ''Image'' in the Matlab workspace.');
                catch msgbox('The image is now saved as the variable ''Image'' in the Matlab workspace.');
                end
            case {'MeasureLength'}
                %%% Places the measure length tool onto the axis containing the image.
                LineHandle = imdistline(get(ImageHandle,'parent'));
                %%% Retrieves a bunch of information about the line that was placed on the
                %%% image.
                api = iptgetapi(LineHandle);
                %%% Using that retrieved data, looks up the handle to the text label.
                LabelHandle = api.getLabelHandle();
                %%% Changes the font size of the text label - if handles
                %%% are not available we do not want this to fail, though.
                try
                    set(LabelHandle,'fontsize',FontSize)
                end
            case {'ChangeColormap'}                         % Change colormap of the whole figure
                FigureHandle = get(get(ImageHandle,'Parent'),'Parent');
                ButtonData.FigureHandle = FigureHandle;
                try
                    ButtonData.IntensityColormap = handles.Preferences.IntensityColorMap;
                catch
                    ButtonData.IntensityColormap = 'gray';
                end
                try
                    ButtonData.LabelColormap = handles.Preferences.LabelColorMap;
                catch
                    ButtonData.LabelColormap = 'jet';
                end
                ChangeColormapHandle = findobj('Tag','ChangeColormapWindow');
                % Check if the Change Colormap window is already open
                if ~isempty(ChangeColormapHandle)
                    CPfigure(ChangeColormapHandle); % Bring the window forward
                    set(findobj(ChangeColormapHandle,'tag','FigureText'),'String',get(FigureHandle,'name')); % Reset the title
                    set(findobj(ChangeColormapHandle,'tag','OpenEditorButton'),'UserData',FigureHandle);     % Update the figure handle
                    set(findobj(ChangeColormapHandle,'tag','ApplyButton'),'UserData',ButtonData);            % Update the figure handle and default colormaps
                    set(findobj(ChangeColormapHandle,'tag','ApplyAllButton'),'UserData',ButtonData);
                else
                    drawnow
                    % Create the Change Colormap window
                    ChangeColormapHandle = CPfigure('units','inches','resize','off','menubar','none','toolbar','none','numbertitle','off','Tag','ChangeColormapWindow','Name','Change Colormap');
                    pos = get(ChangeColormapHandle,'position');
                    %set(ChangeColormapHandle,'position',[(pos(1)+2) pos(2) 3.5 1.2]);
                    set(ChangeColormapHandle,'position',[(pos(1)+2) pos(2) 3.5 2.0]);
                    %                    set(ChangeColormapHandle,'position',[(pos(1)+2) pos(2) 3.5 1.6]);
                    Title = get(FigureHandle,'name');

                    % Create callback functions
                    OpenEditorCallback = [...
                        '[Button, ThisFigure] = gcbo;',...
                        'ThatFigure = get(Button,''userdata'');',...
                        'close(ThisFigure);',...
                        'colormapeditor(ThatFigure);',...
                        'clear Button ThisFigure ThatFigure'];
                    ApplyAllCallback = [...
                        'Answer = CPquestdlg(''Are you sure you want to apply this colormap to all CellProfiler display figures? Remember you can make it the default colormap under File > Set Preferences in the main CellProfier window.'',''Confirm'',''Yes'',''No'',''Yes'');',...
                        'if strcmp(Answer,''Yes''),',...
                        '[Button, ThisFigure] = gcbo;',...
                        'ButtonData = get(Button,''UserData'');',...
                        'ChangeColormapPopupMenu = findobj(''Tag'',''ChangeColormapPopupMenu'');',...
                        'ColormapOptions = get(ChangeColormapPopupMenu,''String'');'...
                        'SelectedColormap = ColormapOptions(get(ChangeColormapPopupMenu,''Value''));',...
                        'SelectedColormap = SelectedColormap{1};',...
                        'AllFigures = findobj(''NumberTitle'',''on'',''-and'',''-property'',''UserData'');',...
                        'for k = length(AllFigures):-1:1,',...
                        'CurrentFigure = AllFigures(k);',...
                        'if ishandle(CurrentFigure),',...
                        'userData = get(CurrentFigure,''UserData'');',...
                        'if (~isempty(userData) && isfield(userData,''Application'') && ',...
                        'isstr(userData.Application) && strcmp(userData.Application,''CellProfiler'')),',...
                        'if strcmp(SelectedColormap, ''default''),',...
                        'WhichColormap = [];',...
                        'ImagesInFigure = findobj(get(CurrentFigure,''Children''),''Type'',''Image'');',...
                        'for i = 1:length(ImagesInFigure),',...
                        'CurrentData = get(ImagesInFigure(i),''CData'');',...
                        'if ndims(CurrentData)==2,',...
                        'CurrentData = CurrentData(:);',...
                        'if any(CurrentData<1 & CurrentData>0),',...
                        'WhichColormap(end+1,1) = 0;',...
                        'else,',...
                        'WhichColormap(end+1,1) = 1;',...
                        'end;',...
                        'end;',...
                        'end;',...
                        'if any(WhichColormap),',...
                        'if any(WhichColormap==0),',...
                        'Choice = CPquestdlg([''The figure '', get(ButtonData.FigureHandle,''Name''), '', whose colormap you are trying to change, has both object and grayscale images. Which default colormap would you like to use, if any?''],''Default colormap conflict'',''Intensity Colormap'',''Objects Colormap'',''Leave unchanged'',''Intensity Colormap'');',...
                        'switch Choice,',...
                        'case ''Intensity Colormap'',',...
                        'CurrentColormap = ButtonData.IntensityColormap;',...
                        'case ''Objects Colormap'',',...
                        'CurrentColormap = ButtonData.LabelColormap;',...
                        'case ''Leave unchanged'',',...
                        'figure(CurrentFigure);',...
                        'CurrentColormap = colormap;',...
                        'end;',...
                        'else,',...
                        'CurrentColormap = ButtonData.LabelColormap;',...
                        'end;',...
                        'else,',...
                        'CurrentColormap = ButtonData.IntensityColormap;',...
                        'end;',...
                        'else,',...
                        'CurrentColormap = SelectedColormap;',...
                        'end;',...
                        'figure(CurrentFigure);',...
                        'colormap(CurrentColormap);',...
                        'end;',...
                        'end;',...
                        'end;',...
                        'figure(ThisFigure);',...
                        'end;',...
                        'clear Answer Button ThisFigure ButtonData ChangeColormapPopupMenu ColormapOptions SelectedColormap AllFigures k CurrentFigure i userData Choice WhichColormap ImagesInFigure CurrentData CurrentColormap;'];
                    ApplyCallback = [...
                        '[Button, ThisFigure] = gcbo;',...
                        'ButtonData = get(Button,''UserData'');',...
                        'if ishandle(ButtonData.FigureHandle),',...
                        'ChangeColormapPopupMenu = findobj(''Tag'',''ChangeColormapPopupMenu'');',...
                        'ColormapOptions = get(ChangeColormapPopupMenu,''String'');'...
                        'SelectedColormap = ColormapOptions(get(ChangeColormapPopupMenu,''Value''));',...
                        'SelectedColormap = SelectedColormap{1};',...
                        'if strcmp(SelectedColormap, ''default''),',...
                        'WhichColormap = [];',...
                        'ImagesInFigure = findobj(get(ButtonData.FigureHandle,''Children''),''Type'',''Image'');',...
                        'for i = 1:length(ImagesInFigure),',...
                        'CurrentData = get(ImagesInFigure(i),''CData'');',...
                        'if ndims(CurrentData)==2,',...
                        'CurrentData = CurrentData(:);',...
                        'if any(CurrentData<1 & CurrentData>0),',...
                        'WhichColormap(end+1,1) = 0;',...
                        'else,',...
                        'WhichColormap(end+1,1) = 1;',...
                        'end;',...
                        'end;',...
                        'end;',...
                        'if any(WhichColormap),',...
                        'if any(WhichColormap==0),',...
                        'Choice = CPquestdlg([''The figure '', get(ButtonData.FigureHandle,''Name''), '', whose colormap you are trying to change, has both object and grayscale images. Which default colormap would you like to use, if any?''],''Default colormap conflict'',''Intensity Colormap'',''Objects Colormap'',''Leave unchanged'',''Intensity Colormap'');',...
                        'switch Choice,',...
                        'case ''Intensity Colormap'',',...
                        'SelectedColormap = ButtonData.IntensityColormap;',...
                        'case ''Objects Colormap'',',...
                        'SelectedColormap = ButtonData.LabelColormap;',...
                        'case ''Leave unchanged'',',...
                        'figure(ButtonData.FigureHandle);',...
                        'SelectedColormap = colormap;',...
                        'end;',...
                        'else,',...
                        'SelectedColormap = ButtonData.LabelColormap;',...
                        'end;',...
                        'else,',...
                        'SelectedColormap = ButtonData.IntensityColormap;',...
                        'end;',...
                        'end;',...
                        'figure(ButtonData.FigureHandle);',...
                        'colormap(SelectedColormap);',...
                        'figure(ThisFigure);',...
                        'else,',...
                        'CPwarndlg([''The figure whose colormap you are trying to change was closed. Its colormap cannot be changed.''],''Figure not available'');',...
                        'end;',...
                        'clear Button ThisFigure ButtonData ChangeColormapPopupMenu ColormapOptions SelectedColormap ImagesInFigure WhichColormap CurrentData Choice i;'];
                    CloseCallback = 'delete(gcf)';
                     %                   HelpCallback = 'CPhelpdlg(''Help for this window and colormaps in general can be found in the Image Tool window help and in Help > General Help in the main CellProfiler window.'',''Colormaps Help'')';
                    HelpCallback = 'HelpColormaps';
                    % Create buttons
                    FigureText         = uicontrol(ChangeColormapHandle,'style','text','units','normalized','position',[.05 .8 .9 .15],'string',Title,'BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'FontWeight','bold','Tag','FigureText');
                    SelectColormapText = uicontrol(ChangeColormapHandle,'style','text','units','normalized','position',[.055 .36 .56 .4],'string','Please specify the colormap to use.   Note: this will have effect in the whole figure, not just the selected image.','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'HorizontalAlignment','left');
                    %SelectColormapText = uicontrol(ChangeColormapHandle,'style','text','units','normalized','position',[.055 .36 .56 .4],'string','Please specify the colormap to use.   Note: this will have effect in the whole figure, not just the selected image.','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'HorizontalAlignment','left');
                    OpenEditorButton   = uicontrol(ChangeColormapHandle,'style','pushbutton','units','normalized','position',[.685 .33 .26 .2],'string','Open Editor','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Tag','OpenEditorButton','UserData',FigureHandle,'Callback',OpenEditorCallback);
                    ApplyToAllButton   = uicontrol(ChangeColormapHandle,'style','pushbutton','units','normalized','position',[.685 .075 .26 .2],'string','Apply To All','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Tag','ApplyAllButton','UserData',ButtonData,'Callback',ApplyAllCallback);
                    ApplyButton        = uicontrol(ChangeColormapHandle,'style','pushbutton','units','normalized','position',[.405 .075 .26 .2],'string','Apply','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Tag','ApplyButton','UserData',ButtonData,'Callback',ApplyCallback);
                    CloseButton        = uicontrol(ChangeColormapHandle,'style','pushbutton','units','normalized','position',[.125 .075 .26 .2],'string','Close','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Callback',CloseCallback);
                    HelpButton         = uicontrol(ChangeColormapHandle,'style','pushbutton','units','normalized','position',[.055 .075 .05 .2],'string','?','BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Callback',HelpCallback);
                    uicontrol(ChangeColormapHandle,'Style','popupmenu','Units','normalized','Position',[0.685 0.55 .26 .2],'String',{'default' 'autumn' 'bone' 'colorcube' 'cool' 'copper' 'flag' 'gray' 'hot' 'hsv' 'jet' 'lines' 'pink' 'prism' 'spring' 'summer' 'white' 'winter'},'BackgroundColor',[.7 .7 .9],'FontSize',FontSize,'Tag','ChangeColormapPopupMenu','Value',1);

                    if isdeployed
                        set(OpenEditorButton,'enable','off')
                    end
                end
            case {'SaveImageAs'}
                Image = get(ImageHandle,'Cdata');

                SaveImageHandle = findobj('tag','SaveImageHandle');
                if ~isempty(SaveImageHandle)
                    close(SaveImageHandle);
                end

                [ScreenWidth,ScreenHeight] = CPscreensize;
                GUIwidth = 410;
                GUIheight = 310;
                Left = 0.5*(ScreenWidth - GUIwidth);
                Bottom = 0.5*(ScreenHeight - GUIheight);

                MainWinPos = [Left Bottom GUIwidth GUIheight];

                userData.Application = 'CellProfiler';
                userData.MyHandles=handles;
                userData.Image=Image;
                SaveImageHandle = figure(...
                    'Units','pixels',...
                    'Color',[.7 .7 .9],...
                    'DockControls','off',...
                    'MenuBar','none',...
                    'Name','Save Image',...
                    'NumberTitle','off',...
                    'Position',MainWinPos,...
                    'Resize','off',...
                    'HandleVisibility','on',...
                    'Tag','SaveImageHandle',...
                    'UserData',userData);
                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.85 0.7 0.14],...
                    'String',['   What would you like to call the file?    ' ;'(file extension will be added automatically)'],...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[1 1 1],...
                    'Callback','string = get(findobj(''Tag'',''FileNameEditBox''),''String'');if(~ischar(string)||isempty(string)); warndlg(''That is not a valid entry'');end;clear string',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.05 0.79 0.7 0.07],...
                    'String','',...
                    'Style','edit',...
                    'Tag','FileNameEditBox');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.69 0.6 0.07],...
                    'String','Where would you like to save it?',...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[1 1 1],...
                    'Callback','string = get(findobj(''Tag'',''FileDirEditBox''),''String'');if(~isdir(string)); warndlg(''That is not a valid entry'');end;clear string',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.05 0.63 0.7 0.07],...
                    'String',handles.Current.DefaultOutputDirectory,...
                    'Style','edit',...
                    'Tag','FileDirEditBox');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'Callback','UserData = get(findobj(''Tag'',''SaveImageHandle''),''UserData'');directory = uigetdir(get(findobj(''Tag'',''FileDirEditBox''),''String'')); if directory ~= 0, set(findobj(''Tag'',''FileDirEditBox''),''String'',directory);end,pause(.1);figure(findobj(''Tag'',''SaveImageHandle''));clear UserData directory',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.83 0.63 0.15 0.07],...
                    'String','Browse...',...
                    'Tag','BrowseButton',...
                    'BackgroundColor',[.7 .7 .9]);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.53 0.7 0.07],...
                    'String','Which file format would you like to use?',...
                    'Style','text');

                %%% Writeable file formats using imwrite command. We cannot
                %%% get this list from CPimread because not all readable
                %%% formats are also writeable. We have adjusted the Save
                %%% Images module to also save avi, fig, and mat files.
                Formats = {'bmp','gif','hdf','jpg','jpeg','pbm','pcx','pgm','png','pnm','ppm','ras','tif','tiff','xwd','avi','fig','mat'};

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'Callback','',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.75 0.53 0.23 0.07],...
                    'String',Formats,...
                    'Style','popupmenu',...
                    'Tag','ExtensionPopupMenu');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'Callback','CPtextdisplaybox(sprintf(''Some image formats do not support saving at a bit depth of 12 or 16. \n\n For grayscale images this can be 1, 2, 4, 8, or 16. \n For grayscale images with an alpha channel this can be 8 or 16.\n For indexed images this can be 1, 2, 4, or 8.\n For truecolor images with or without an alpha channel this can be 8 or 16.''),''Bit Depth Help'');',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[.01 .45 .03 .06],...
                    'String','?',...
                    'Tag','BitDepthHelpButton',...
                    'BackgroundColor',[.7 .7 .9]);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.43 0.7 0.07],...
                    'String','At what bit depth would you like to save the file?',...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'Callback','',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.75 0.43 0.23 0.07],...
                    'String',{'8' '12' '16'},...
                    'Style','popupmenu',...
                    'Tag','NumberBitsPopupMenu');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.33 0.6 0.07],...
                    'String','Would you like to rescale?',...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'Callback','',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.75 0.33 0.23 0.07],...
                    'String',{'yes' 'no'},...
                    'Style','popupmenu',...
                    'Tag','RescalePopupMenu',...
                    'Value',2);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.23 0.7 0.07],...
                    'String','For grayscale images, specify the colormap to use.',...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'Callback','CPtextdisplaybox(sprintf(''Anything other than gray may degrade or stretch the image.\n See also Help > HelpColormaps in the main CellProfiler window.''),''Colormaps Help'');',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[.01 .25 .03 .06],...
                    'String','?',...
                    'Tag','ColormapHelpButton',...
                    'BackgroundColor',[.7 .7 .9]);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'Callback','',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.75 0.23 0.23 0.07],...
                    'String',{'Default' 'autumn' 'bone' 'colorcube' 'cool' 'copper' 'flag' 'gray' 'hot' 'hsv' 'jet' 'lines' 'pink' 'prism' 'spring' 'summer' 'white' 'winter'},...
                    'Style','popupmenu',...
                    'Tag','SaveImageColormapPopupMenu',...
                    'Value',1);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[.7 .7 .9],...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'HorizontalAlignment','left',...
                    'Position',[0.05 0.13 0.7 0.07],...
                    'String','Enter any optional parameters here',...
                    'Style','text');

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'BackgroundColor',[1 1 1],...
                    'Callback','',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.75 0.13 0.23 0.07],...
                    'String','/',...
                    'Style','edit',...
                    'Tag','OptionsTag');

                SaveFunction = ...
                    ['filename = get(findobj(''Tag'',''FileNameEditBox''),''String'');'...
                    'dirname = get(findobj(''Tag'',''FileDirEditBox''),''String'');'...
                    'if isempty(filename)||~ischar(filename),'...
                    'warndlg(''The filename is not valid'');'...
                    'clear filename dirname;'...
                    'elseif ~isdir(dirname),'...
                    'warndlg(''The directory is not valid'');'...
                    'clear filename dirname;'...
                    'else,'...
                    '[ignoreDir filename ignoreext] = fileparts(filename);'...
                    'if ~isempty(ignoreDir) && ~strcmp(ignoreDir,dirname)&&isdir(ignoreDir),'...
                    'warndlg([''The file path in the name, '' ignoreDir '' is not the same as the specified path, '' dirname ''.  So, we are using '' ignoreDir]);'...
                    'dirname = ignoreDir;'...
                    'end,'...
                    'tempHandles.Current.CurrentModuleNumber = ''01'';'...
                    'tempHandles.Settings.ModuleNames{1} = ''SaveImageAs'';'...
                    'tempHandles.Settings.VariableValues{1,1}=''OrigBlue'';'...
                    'tempHandles.Settings.VariableValues{1,2}=''OrigBlue'';'...
                    'tempHandles.Settings.VariableValues{1,3}=''\'';'...
                    'ListExtensions = get(findobj(''Tag'',''ExtensionPopupMenu''),''String'');'...
                    'ext=ListExtensions(get(findobj(''Tag'',''ExtensionPopupMenu''),''Value''));'...
                    'if ~isempty(ignoreext)&&~strcmp(ignoreext,ext),'...
                    'warndlg([''The extension in the name, '' ignoreext '' is not the same as the extension that you entered, '' ext ''.  So, we are using '' tempext]);'...
                    'ext = tempext;'...
                    'end,'...
                    'tempHandles.Settings.VariableValues{1,4}=ext;'...
                    'tempHandles.Settings.VariableValues{1,5}=dirname;'...
                    'BitDepths = get(findobj(''Tag'',''NumberBitsPopupMenu''),''String'');'...
                    'tempHandles.Settings.VariableValues{1,6}=BitDepths(get(findobj(''Tag'',''NumberBitsPopupMenu''),''Value''));'...
                    'tempHandles.Settings.VariableValues{1,7}=''Yes'';'...
                    'tempHandles.Settings.VariableValues{1,8}=''Every cycle'';'...
                    'tempHandles.Settings.VariableValues{1,9}=''L'';'...
                    'RescaleOptions = get(findobj(''Tag'',''RescalePopupMenu''),''String'');'...
                    'tempHandles.Settings.VariableValues{1,10}=RescaleOptions(get(findobj(''Tag'',''RescalePopupMenu''),''Value''));'...
                    'ColormapOptions = get(findobj(''Tag'',''SaveImageColormapPopupMenu''),''String'');'...
                    'tempHandles.Settings.VariableValues{1,11}=ColormapOptions(get(findobj(''Tag'',''SaveImageColormapPopupMenu''),''Value''));'...
                    'OptionValues = get(findobj(''Tag'',''OptionsTag''),''String'');'...
                    'tempHandles.Settings.VariableValues{1,12}=OptionValues;'...
                    'tempHandles.Settings.VariableValues{1,13}=''No'';'...
                    'tempHandles.Current.CurrentModuleNumber=''01'';'...
                    'tempHandles.Current.SetBeingAnalyzed=1;'...
                    'tempHandles.Current.StartingImageSet=0;'...
                    'tempHandles.Current.NumberImageSets=1;'...
                    'UserData = get(findobj(''tag'',''SaveImageHandle''),''UserData'');'...
                    'tempHandles.Pipeline.OrigBlue=UserData.Image;'...
                    'try handles = guidata(findobj(''Tag'',''figure1''));'...
                    'tempHandles.Current.DefaultImageDirectory = handles.Current.DefaultImageDirectory;'...
                    'tempHandles.Preferences.IntensityColorMap = handles.Preferences.IntensityColorMap;'...
                    'catch tempHandles.Current.DefaultImageDirectory = ''C:\Anything'';'...
                    'tempHandles.Preferences.IntensityColorMap = ''gray'';'...
                    'end;'...
                    'tempHandles.Pipeline.FileListOrigBlue{1}{1}=filename;'...
                    'tempHandles.Pipeline.FilenameOrigBlue = {filename};'...
                    'try,'...
                    'SaveImages(tempHandles);'...
                    'try CPmsgbox(''The image was successfully saved.'');'...
                    'catch msgbox(''The image was successfully saved.'');'...
                    'end,'...
                    'catch,'...
                    'try CPmsgbox(''For some reason, the image was unable to save.'');'...
                    'catch msgbox(''For some reason, the image was unable to save.'');'...
                    'end,'...
                    'end,'...
                    'delete(findobj(''Tag'',''SaveImageHandle''));'...
                    'clear filename dirname ListExtensions BitDepths RescaleOptions ColormapOptions tempHandles ListExtensions ext BitDepths RescaleOptions ColormapOptions UserData handles ignoreDir ignoreext;'...
                    'end'];

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'Callback',SaveFunction,...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.68 0.03 0.18 0.07],...
                    'String','Save',...
                    'Tag','SaveImageButton',...
                    'BackgroundColor',[.7 .7 .9]);

                uicontrol(...
                    'Parent',SaveImageHandle,...
                    'Units','normalized',...
                    'Callback','delete(findobj(''Tag'',''SaveImageHandle''));',...
                    'FontSize',FontSize,...
                    'FontWeight','bold',...
                    'Position',[0.14 0.03 0.18 0.07],...
                    'String','Cancel',...
                    'Tag','CancelSaveImageButton',...
                    'BackgroundColor',[.7 .7 .9]);


            otherwise
                disp('Unknown action')                        % Should never get here, but just in case.
        end % goes with switch
    else
        CPwarndlg(['The image that you are trying to work with is no longer available. It was named ''',get(findobj(get(ImageToolWindowHandle,'children'),'style','text'),'string'),''', and it appears to have been closed or deleted.'],'Image Not Found');
    end
else
    handle = gcbo;
    % Check if the Image Tool window already is open
    ImageToolWindowHandle = findobj('Tag','Image Tool');
    if ~isempty(ImageToolWindowHandle)
        CPfigure(ImageToolWindowHandle);
        userData = get(ImageToolWindowHandle,'UserData');
        userData.ImageToolWindowHandle = handle;
        set(ImageToolWindowHandle,'UserData',userData);                                % Store the new handle in the UserData property
        th = findobj(get(ImageToolWindowHandle,'children'),'style','text');            % Get handle to text object

        Title = get(get(get(handle,'Parent'),'Title'),'String');      % Get title of image
        set(th,'string',Title);                                       % Put new text

        if length(Title)>36                                           % Adjust position
            width = 0.06*length(Title);
        else
            width = 2;
        end
        pos = get(ImageToolWindowHandle,'position');
        set(ImageToolWindowHandle,'position',[pos(1) pos(2) width pos(4)]);

        % Enable histogram function if 2D image
        if ndims(get(handle,'Cdata')) == 2
            set(findobj(get(ImageToolWindowHandle,'children'),'tag','Histogram'),'Enable','on')
        else
            set(findobj(get(ImageToolWindowHandle,'children'),'tag','Histogram'),'Enable','off')
        end
    else
        drawnow
        % Create Image Tool window
        ImageToolWindowHandle = CPfigure;
        set(ImageToolWindowHandle,'units','inches','resize','off','menubar','none','toolbar','none','numbertitle','off','Tag','Image Tool','Name','Image Tool');
        userData = get(ImageToolWindowHandle,'UserData');
        userData.ImageToolWindowHandle = handle;
        set(ImageToolWindowHandle,'UserData',userData);
        % Get title of image
        Title = get(get(get(handle,'Parent'),'Title'),'String');
        % Adjust position
        if length(Title)>36
            width = 0.06*length(Title);
        else
            width = 2;
        end
        pos = get(ImageToolWindowHandle,'position');
        set(ImageToolWindowHandle,'position',[pos(1) pos(2) width 3.4]);
        % Create buttons
        Text = uicontrol(ImageToolWindowHandle,'style','text','units','normalized','position',[.03 .85 .95 .12],'string',Title,'BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        NewWindow =      uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .78 .9 .1],'string','Open in new window','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        Histogram =      uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .66 .9 .1],'string','Show intensity histogram','Tag','Histogram','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        MeasureLength =  uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .54 .9 .1],'string','Measure Length','Tag','MeasureLength','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        ChangeColormap = uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .42 .9 .1],'string','Change Colormap','Tag','ChangeColormap','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        MatlabWS  =      uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .30 .9 .1],'string','Save to work space','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        SaveImageAs=     uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .18 .9 .1],'string','Save to hard drive','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        Cancel    =      uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.25 .05 .7 .1],'string','Cancel','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);
        Help    =        uicontrol(ImageToolWindowHandle,'style','pushbutton','units','normalized','position',[.05 .05 .15 .1],'string','?','BackgroundColor',[.7 .7 .9],'FontSize',FontSize);

        % Assign callback functions
        set(NewWindow,'Callback','CPimagetool(''NewWindow'');');
        set(Histogram,'Callback','CPimagetool(''Histogram'');');
        set(MeasureLength,'Callback','CPimagetool(''MeasureLength'');');
        set(ChangeColormap,'Callback','CPimagetool(''ChangeColormap'');');
        set(MatlabWS,'Callback','CPimagetool(''MatlabWS'');');
        set(SaveImageAs,'Callback','CPimagetool(''SaveImageAs'');');
        set(Cancel,'Callback','[foo,ImageToolWindowHandle] = gcbo;close(ImageToolWindowHandle); clear foo ImageToolWindowHandle;');
        set(Help,'Callback','handles = guidata(findobj(''tag'',''figure1''));for i = 1:length(handles.Current.ImageToolsFilenames),if strmatch(''ImageToolWindow'',handles.Current.ImageToolsFilenames{i},''exact''),Option = i;break,end,end,CPtextdisplaybox(handles.Current.ImageToolHelp{Option-1},''Help for the Image Tool Window'');clear Option handles i ans');

        % Currently, no histogram function for RGB images
        if ndims(get(handle,'Cdata')) ~= 2
            set(Histogram,'Enable','off')
        end

        if isdeployed
            set(MatlabWS,'Enable','off')
        end
    end
end
