function [ ax,h ] = m_bar( varargin )
%    M_BAR was adapted from M_CONTFBAR by har,more details:
%    M_BAR Draws a colour bar for contourf plots
%    M_BAR([X1,X2],Y,DATA,LEVELS) draws a horizontal colourbar
%    between the normalized coordinates (X1,Y) and (X2,Y) where
%    X/Y are both in the range 0 to 1 across the current axes.
%    Negative values can be used to position outside the axis.
%
%    Differences from COLORBAR are: the bar is divided into solid
%    colour patches exactly corresponding to levels provided by
%    CONTOURF(DATA,LEVELS) instead of showing the whole continuous
%    colourmap, the parent axis is not resized, the axis can be made
%    as large or small as desired, and the presence of values
%    above/below contoured levels is indicated by triangular pieces
%    (MATLAB 2014b or later).
%
%     M_BAR(X,[Y1,Y2],...) draws a vertical colourbar
%
%    The DATA,LEVELS pair can also be replaced with CS,CH where
%    [CS,CH]=CONTOURF(DATA,LEVELS).
%
%     M_BAR(...,'parameter','value') lets you specify extra
%    parameter/value pairs for the colourbar in the usual handle-graphics
%    way. Parameters you might set include 'xticks','xticklabels',
%    'xscale','xaxisloc' (or corresponding y-axis parameters for
%    a vertical colourbar) and 'fontsize'.
%
%    Additional parameter/value pairs allow special customization of the
%    colourbar:
%        'axfrac' : width of the colourbar (default 0.03)
%        'endpiece' : 'yes' (default) or 'no' show triangular
%                      endpieces.
%        'levels' : 'set' (default) shows a colourbar with exactly
%                   the levels in the LEVELS argument.
%                   'match' shows only the subsect of levels actually
%                   used in the CONTOURF call. E.g., if your data ranges
%                   from (say) 121 to 192, and LEVELS=[10:10:300],
%                   then only levels in 130:10:190 actually appear in both
%                   the CONTOURF and the colourbar.
%         'edgecolor' : 'none' removes edges between colors.
%         'expand': 'yes' for expand level
%         'ticks' : ticks for the level
%         'labels' : ticklabels for the ticks
%    [AX,H]= M_BAR(...) returns the handle to the axis AX and to
%    the contourobject H. This is useful to add titles, xlabels, etc.
%
%     M_BAR(BAX,...) where BAX is an axis handle draws the colourbar
%    for that axis.
%
%    Note that if you assign a colormap to the specific axes BAX for which
%    you want a colorbar by calling COLORMAP(BAX,...), then in order to
%    import that colormap to the colorbar you must use M_CONTFBAR(BAX,...).
%    However, if you call COLORMAP without specifying an axes (which sets
%    the figure colormap) then you must call  M_BAR without specifying
%    an axis.
%
%    Calling  M_BAR a second time will replace the first colourbar.
%    Calling  M_BAR without arguments will erase a colourbar.
%
%    See also COLORBAR


% R. Pawlowicz Nov/2017
%     Dec/2017 - inherit colormaps from the source axes.
%     Dec/2018 - if no axis specified, inherit colors from gca

% if users enters a '0' or a '1' as the first argument it can
% easily be interpreted as a figure handle - make sure this
% doesn't happen.
if nargin>0 && length(varargin{1})==1 && (varargin{1}==0 || varargin{1}==1 )
    varargin{1}=varargin{1}+eps;
end

% Is first argument an axis handle?
if nargin>0 && length(varargin{1})==1 && ishandle(varargin{1})
    if  strcmp(get(varargin{1},'type'),'axes')
        savax=varargin{1};
        varargin(1)=[];
        %  inheritcolormap=true;
    else
        error(['map: ' mfilename ':invalidAxesHandle'],...
            ' First argument must be an axes handle ');
    end
else
    savax=gca;
    % inheritcolormap=false;
end

% Delete any existing colorbars associated with savax
oldax=get(savax,'userdata');
if ~isempty(oldax) && ishandle(oldax) && strcmp('m_contfbar',get(oldax,'tag'))
    delete(oldax);
end

if isempty(varargin)  % No input arguments? - exit immediately after deleting old colorbar.
    return
elseif length(varargin)>=4
    posx=varargin{1};
    posy=varargin{2};
    Data=varargin{3};
    Levels=varargin{4};
    varargin(1:4)=[];
end

% Check trailing arguments for anything special

axfrac=.03;
endpiece=true;
sublevels=false;
edgeargs={};
expand = false;
exsit_tic = false;
exsit_lab = false;
k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        case 'axf'
            axfrac=varargin{k+1};
            varargin([k k+1])=[];
        case 'end'
            switch lower(varargin{k+1}(1))
                case 'n'
                    endpiece=false;
                otherwise
                    endpiece=true;
            end
            varargin([k k+1])=[];
        case 'lev'
            switch lower(varargin{k+1}(1))
                case 's'
                    sublevels=false;
                otherwise
                    sublevels=true;
            end
            varargin([k k+1])=[];
        case 'col'
            cmp = varargin{k+1};
            varargin([k k+1])=[];
        case 'tic'
            ticks = varargin{k+1};
            varargin([k k+1])=[];
            exsit_tic = true;
        case 'lab'
            labels = varargin{k+1};
            varargin([k k+1])=[];
            exsit_lab = true;
        case {'edg','lin'}
            edgeargs=varargin([k k+1]);
            varargin([k k+1])=[];
        otherwise
            k=k+2;
    end
end

if isempty(Levels)
    return;
end

if ishandle(Levels)  % CS,CH pair
    Data=get(Levels,'ZData');
    Levels=get(Levels,'LevelList');
end
% added by har 2023.6.3
if k ==3
    switch lower(varargin{k-2}(1:3))
        case 'exp'
            switch lower(varargin{k-1}(1))
                case 'y'
                    expand = true;
                    dl = Levels(2)-Levels(1);
                    Levels = [Levels(1)-dl,Levels,Levels(end)+dl];
                otherwise
                    expand = false;
            end
    end
    varargin([k-2 k-1])=[];
end
% added by har 2023.6.3

% Min and max data values is all I need

ii=isfinite(Data(:));
minD=double(min(Data(ii)));
maxD=double(max(Data(ii)));
% I need to get the levels actually contoured
% if its just a set number of levels then we have
% to regenerate what they actually are
% Otherwise use the levels vector

if length(Levels)==1 || sublevels
    CS=contourc([1;1]*[minD maxD],Levels);
    k=1;
    nlevels=0;
    while k<size(CS,2)
        nlevels=nlevels+1;
        Clevel(nlevels)=CS(1,k);
        k=k+CS(2,k)+1;
    end
    Clevel=unique(Clevel);
else
    Clevel=Levels;
end
dC=Clevel(end)-Clevel(1);
dl = Levels(2)-Levels(1);
% Form the colorbar, with or without the left/right triangles
% as needed depending on data range and levels chosen.
haha =0.4;
if Clevel(1)>=minD && endpiece
    fakedata=[1;1]*[minD Clevel(2)];
    fakex=[1;1]*[Clevel(2)-dl*haha Clevel(2)];
    fakey=[1 2;1 0];
    % leftpatch=true;
elseif expand
    fakedata=[1;1]*[Clevel(2)];
    fakex=[1;1]*[Clevel(2)];
    fakey=[2;0];
else
    fakedata=[1;1]*[Clevel(1) ];
    fakex=[1;1]*[Clevel(1)];
    fakey=[2;0];
    %leftpatch=false;
end

if Clevel(end)<=maxD && endpiece
    fakedata=[ fakedata [1;1]*[Clevel(end) maxD]];
    fakex=[fakex [1;1]*[Clevel(end-1) Clevel(end-1)+dl*haha] ];
    fakey=[fakey [2 1;0 1]];
    
elseif expand
    fakedata=[ fakedata [1;1]*[Clevel(end) ]];
    fakex=[fakex [1;1]*[Clevel(end)] ];
    fakey=[fakey [2 ;0 ]];
else
    fakedata=[ fakedata [1;1]*[Clevel(end) ]];
    fakex=[fakex [1;1]*[Clevel(end)] ];
    fakey=[fakey [2 ;0 ]];
end

axpos=get(savax,'position');
if  ( length(posx)==2 && length(posy)==1)
    horiz=true;
    cpos=[ axpos(1)+posx(1)*axpos(3) ...
        axpos(2)+(posy-1/2*axfrac)*axpos(4) ...
        diff(posx)*axpos(3) ...
        axfrac*axpos(4) ];
    
elseif  ( length(posx)==1 && length(posy)==2)
    horiz=false;
    cpos=[ axpos(1)+(posx-1/2*axfrac)*axpos(3) ...
        axpos(2)+posy(1)*axpos(4) ...
        axfrac*axpos(3) ...
        diff(posy)*axpos(4) ];
    tmp=fakex;
    fakex=fakey;
    fakey=tmp;
end

ax=axes('position',cpos);

if expand   % If a left triangle is being drawn, colour a "behind"
    if horiz
        patch(Clevel(2)+[0 -.07*dC 0],[0 1 2],cmp(1,:));
        patch(Clevel(end)+[0 +.07*dC 0],[0 1 2],cmp(end,:));
    else
        patch([0 1 2],Clevel(2)+[0 -.07*dC 0],cmp(1,:));
        patch([0 1 2],Clevel(end)+[0 +.07*dC 0],cmp(end,:));
    end
    hold on;
end

% Finally, draw the colourbar
%edded by har 2023.6.3
if expand
    [~,h]=contourf(fakex,fakey,fakedata,Levels(2:end),'clipping','off',edgeargs{:});
    colormap(cmp(2:end-1,:))
    caxis([Levels(2),Levels(end)]);
else
    [~,h]=contourf(fakex,fakey,fakedata,Levels,'clipping','off',edgeargs{:});
    colormap(cmp(1:end,:))
    caxis([Levels(1),Levels(end)])
end
if horiz
    if ~exsit_tic,ticks = get(ax,'xtick'); end
    if ~exsit_lab,labels = get(ax,'xticklabels'); end
else
    if ~exsit_tic,ticks = get(ax,'ytick'); end
    if ~exsit_lab,labels = get(ax,'yticklabels'); end
end
%edded by har 2023.6.3
set(h,'clipping','off');   % Makes endpieces show in 2014b and later
% if Clevel(end)<=maxD && endpiece
%     line(fakex(2:end)',fakey(2:end)','color','k'); % long sides
%     line(fakex(2:end),fakey(2:end),'color','k');
% else
line(fakex',fakey','color','k'); % long sides
line(fakex,fakey,'color','k');
% end
% editted by har 2023.6.3
if horiz
    if expand
        set(ax,'xlim',Clevel([2 end]),'xtick',ticks,'xticklabels',labels ,...
            'ytick',[],'clipping','off','ylim',[0 2],'ycolor','w');
        if posy>0.5, set(ax,'xaxislocation','top'); end
    elseif Clevel(end)<=maxD && endpiece
        axis off;set(ax,'clipping','off','ylim',[0 2],'ycolor','w')
        for i = 1:length(ticks)
            if posy>0.5
                text(ticks(1)+(i-1)*dl*(length(ticks)-1)/length(ticks)*0.98,2.5,{labels(i)},'fontsize',9)
            else
                text(ticks(1)+(i-1)*dl*(length(ticks)-1)/length(ticks)*0.98,-0.5,{labels(i)},'fontsize',9)
            end
        end
    else
        set(ax,'xlim',Clevel([1 end]),'xtick',ticks,'xticklabels',labels ,...
            'ytick',[],'clipping','off','ylim',[0 2],'ycolor','w');
        if posy>0.5, set(ax,'xaxislocation','top'); end
    end
else
    if expand
        set(ax,'ylim',Clevel([2 end]),'ytick',ticks,'yticklabels',labels,...
            'xtick',[],'clipping','off','xlim',[0 2],'xcolor','w');
        if posx>0.5, set(ax,'yaxislocation','right'); end
    elseif Clevel(end)<=maxD && endpiece
        axis off;
        set(ax,'clipping','off','xlim',[0 2],'xcolor','w')
        for i = 1:length(ticks)
            if posx>0.5
                text(2.5,ticks(1)+(i-1)*dl*(length(ticks)-1)/length(ticks)*0.98,{labels(i)},'fontsize',9)
            else
                text(-0.5,ticks(1)+(i-1)*dl*(length(ticks)-1)/length(ticks)*0.98,{labels(i)},'fontsize',9)
            end
        end
    else
        set(ax,'ylim',Clevel([1 end]),'ytick',ticks,'yticklabels',labels,...
            'xtick',[],'clipping','off','xlim',[0 2],'xcolor','w');
        if posx>0.5, set(ax,'yaxislocation','right'); end
    end
end
% editted by har 2023.6.3

set(ax,'tickdir','out','box','off','layer','bottom',...
    'ticklength',[.0 .0],'tag','m_contfbar',varargin{:});

% Inherit the colormap. - fix Dec/28/2017
%if inheritcolormap
drawnow;  % Update all properties - if this is missing
% then we might be loading a default colormap
% simply because the correct one is in  a'pending'
% stack of graphics requests.  For colorbars there
% appears to be 'peer' property that is perhaps
% associated with handling this property.
colormap(ax,colormap(savax));
%end


% Tuck away the info that there is a colorbar
set(savax,'userdata',ax);

% Return to drawing axis
set(gcf,'currentaxes',savax);

% Make the colorlimits match
if strcmp(get(gca,'CLimMode'),'manual')
    caxis(ax,get(gca,'clim'));
else
    caxis(get(ax,'clim'));
end
if nargout==0
    clear ax h
end
end

