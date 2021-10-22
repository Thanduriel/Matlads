% ------------- Input --------------

fig = figure('Color',[0.8 0.8 1.0],'KeyPressFcn', @keyPress, 'KeyReleaseFcn',@keyRelease);
ax = axes('Parent',fig, ...
    'XLim',[0 100], 'YLim',[0 100], 'NextPlot', 'add');
grid on

uicontrol('Style', 'radiobutton', 'String', 'Test');

global ball;
ball = struct;
ball.position = [20 50];
%ball.vis = line(ball.position(1), ball.position(2),'marker', '.', 'markersize',50);
ball.velocity = [0 0];

global keyboard;
keyboard = struct;

%Music
[bgm, Fs] = audioread('bensound-jazzyfrenchy.mp3');
bgmplay = audioplayer(bgm, Fs);
bgmplay.play;

%Image
[I, ~, alphachannel] = imread('smiley.png');
ball.img = image([ball.position(1)-5,  ball.position(1)+5], [ball.position(2)+5, ball.position(2)-5], I,...
    'Parent', ax, ...
    'Visible', 'on', ...
    'AlphaData', alphachannel);

% ------------- Game Loop --------------

while true
    tic
    processInput()
    % update ball
    ball.position = ball.position + ball.velocity;
    set(ball.img, 'XData', [ball.position(1)-5,  ball.position(1)+5], 'YData', [ball.position(2)+5, ball.position(2)-5]);
    ball.velocity = [0,0];

    drawnow()


    pause(1/100 - toc)

    if(isfield(keyboard,'escape') && keyboard.escape)
        break;
    end
end

stop(bgmplay);
clear; clc; close all;

% ------------- Functions --------------

function keyPress(~, event)
    global keyboard;    
    keyboard.(event.Key) = true;
end

function keyRelease(~,event)
    global keyboard;    
    keyboard.(event.Key) = false;
end

function processInput()
    global keyboard;
    global ball;
    speed = 0.5;

    if (isfield(keyboard, 'rightarrow') && keyboard.rightarrow)
        ball.velocity(1) = speed;
    elseif (isfield(keyboard, 'leftarrow') && keyboard.leftarrow)
        ball.velocity(1) = -speed;
    end

    if (isfield(keyboard, 'uparrow') && keyboard.uparrow)
        ball.velocity(2) = speed;
    elseif (isfield(keyboard, 'downarrow') && keyboard.downarrow)
        ball.velocity(2) = -speed;
    end
end