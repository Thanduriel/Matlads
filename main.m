% ------------- Input --------------

fig = figure('Color',[0.8 0.8 1.0],'KeyPressFcn', @keyPress, 'KeyReleaseFcn',@keyRelease);
ax = axes('Parent',fig, ...
    'XLim',[0 1], 'YLim',[0 1], 'NextPlot', 'add');
grid on

% 
global ground;
ground = struct;
indicies = linspace(0, 1, 128);
ground.vertices = [indicies; 0.3 + 0.1 * sin(16 * indicies)];
ground.vertices(:,1) = [0.0 0.7];
ground.vertices(:,2) = [0.1 0.9];
ground.sprite = line(ground.vertices(1,:), ground.vertices(2,:));

% general data
global comps;
comps = struct;
comps.positions = [0.4 0.7; 0.6, 0.5];
comps.velocities = [-0.75 0; 0 0];
comps.sprites = [makeactor('\pi') makeactor('\lambda')];
% player entity
player = 1;

global ball;
ball = struct;
ball.position = [0.1 0.5];
%ball.sprite = line(ball.position(1), ball.position(2),'marker', '.', 'markersize',50);
ball.velocity = [0 0];

global keyboard;
keyboard = struct;

gravity = [0; -0.2];

% ------------- Game Loop --------------
dt = 1 / 144;
while true
    tic
    processInputs()
    
    % update physics
    comps.velocities = comps.velocities + dt * gravity;
    newPositions = comps.positions + dt * comps.velocities;
    % resolve collisions
    for i = 1:size(comps.positions, 2)
        oldPos = [comps.positions(1,i) comps.positions(2,i)];
        newPos = [newPositions(1,i) newPositions(2,i)];
        [x,y] = intersections([oldPos(1) newPos(1)], ...
            [oldPos(2) newPos(2)], ...
            ground.vertices(1,:), ground.vertices(2,:));
        if (x)
            comps.velocities(:,i) = [0 0];
            dir = newPos - oldPos;
            len = norm(dir);
            newPositions(:, i) = [x y] - dir / len * 0.00001;
        end
    end
    comps.positions = newPositions;
    
    % update sprites
    arrayfun(@updateprite, comps.sprites, comps.positions(1,:), comps.positions(2,:));

    drawnow()

    pause(dt - toc)

    if(isfield(keyboard,'escape') && keyboard.escape)
        break;
    end
end

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

function processInputs()
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