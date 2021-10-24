fig = figure('Color',[0.8 0.8 1.0], ...
    'KeyPressFcn', @keyPress, ...
    'KeyReleaseFcn',@keyRelease, ...
    'WindowButtonDownFcn', @buttonDown, ...
    'WindowButtonUpFcn', @buttonUp);
fig.Position = [100 100 800 600];

global keyboard;
keyboard = struct;

introMsgString = {'MATLADS', '', 'choose your character', '', '', ''};
introMsg = annotation("textbox", [.1 .1 .8 .8], String=introMsgString, ...
        Color="white", BackgroundColor='Blue', ...
        EdgeColor='Red', FontSize=30, VerticalAlignment="middle", ...
        HorizontalAlignment="center");

ui1 = uicontrol('Style', 'edit', 'String', 'π', 'Position', [400-60 240 40 40], 'FontSize',26);
ui2 = uicontrol('Style', 'edit', 'String', 'e', 'Position', [400+20 240 40 40], 'FontSize',26);
ui3 = uicontrol('Style', 'pushbutton','String','START', Position=[400-40 180 80 40]);
global shouldStart;
shouldStart = false;

ui3.Callback = @startButtonPressed;

while ~shouldStart && ~(isfield(keyboard,'escape') && keyboard.escape)
    pause(0.01667);
end

playerChars = {ui1.String, ui2.String};

delete(ui1);
delete(ui2);
delete(ui3);
delete(introMsg);


tlayout = tiledlayout(1,4);
tlayout.Padding = 'compact';
tlayout.TileSpacing = 'compact';
barAx = nexttile;
set(barAx, 'XLim', [0 100]);
healthBars = barh([ 100 100], 'FaceColor','flat');
xlabel('Health');
xlim('manual');
ax = nexttile([1 3]);
set(ax, 'XLim', [0 1], 'YLim', [0 1], 'NextPlot', 'add');
grid on

% 
global ground;
ground = struct;
indicies = linspace(0, 1, 128);
ground.vertices = [indicies; 0.3 + 0.1 * sin(16 * indicies)];
ground.vertices(:,1) = [0.0 -10.0];
ground.vertices(:,2) = [0.0 10.0];
ground.vertices(:,127) = [1.0 10.0];
ground.vertices(:,128) = [1.0 -10.0];
ground.shape = polyshape(ground.vertices(1,:), ground.vertices(2,:));%line(ground.vertices(1,:), ground.vertices(2,:));
ground.normals = computeNormals(ground.vertices);
ground.polygon = plot(ground.shape);

% general data
componentNames = {'positions', 'velocities', 'hasCollision', 'lifeTimes'};
global comps;
comps = struct;
comps.positions = [0.4 0.7; 0.6, 0.5];
comps.velocities = [0.0 0; 0 0];
comps.hasCollision = [true true];
comps.lifeTimes = [realmax realmax];
comps.sprites = [makeactor(playerChars{1}) makeactor(playerChars{2})];
comps.markers = line(0,0,'LineStyle', 'none', 'Marker', '*');
%comps.markers2 = line(0,0,'LineStyle', 'none', 'Marker', '.');
comps.deleted = [];
comps.health = [ 100 100 ];
global newComps;
newComps = struct;
for i = 1:numel(componentNames)
    % init with real components to determine the correct type
    newComps.(componentNames{i}) = comps.(componentNames{i});
    newComps.(componentNames{i})(:) = [];
end

% active player entity
global player;
global numPlayers;
numPlayers = 2;
player = numPlayers;

global totalTime;
totalTime = 0;
global dt;
dt = 1 / 60;

global chargeParams;
chargeParams = struct;
chargeParams.startTime = 0;
chargeParams.direction = [1;0];
chargeParams.maxCharge = 1.5;
chargeParams.minCharge = 0.5;
chargeParams.scale = 0.25 / chargeParams.maxCharge;
chargeParams.indicator = quiver(0,0, 1,1, 0, 'linewidth', 4, 'Visible', 'off');
chargeParams.mode = -1; % 0 - jump, 1 - gun

advanceplayer();
% ------------- Game Loop --------------
while true
    tic
    processInputs()
    
    updatePhysics()

    % update life times
    comps.lifeTimes = comps.lifeTimes - dt;
    inds = 1:numel(comps.lifeTimes);
    comps.deleted = [comps.deleted inds(comps.lifeTimes <= 0)];
%     testD = sum(comps.lifeTimes <= 0);
%     if(testD)
%         comps.velocities(:,inds(comps.lifeTimes <= 0)) = repmat([0;0], [1 testD]);
%     end
    % update sprites
    arrayfun(@updateprite, comps.sprites, ...
        comps.positions(1,1:numPlayers), comps.positions(2,1:numPlayers));

    colors = repmat([0 0.447 0.741], [numPlayers 1]);
    colors(player,:) = [0 1 0];
    set(healthBars, 'YData', comps.health, 'CData', colors);
    
    if (size(comps.positions, 2) > numPlayers)
        set(comps.markers, 'Visible', 'On', ...
            'XData', comps.positions(1,numPlayers+1:end), ...
            'YData', comps.positions(2, numPlayers+1:end));
    else
        set(comps.markers, 'Visible', 'Off');
    end

    % update charge quiver
    dir = chargeParams.direction * min(chargeParams.maxCharge, ...
        totalTime - chargeParams.startTime) * chargeParams.scale;
    set(chargeParams.indicator, 'UData', dir(1), 'VData', dir(2));
    drawnow()
    
    % clean up
    if comps.deleted
        for i = 1:numel(componentNames)
            comps.(componentNames{i})(:, comps.deleted) = [];
        end
        comps.deleted = [];
    end
    if newComps.positions
        for i = 1:numel(componentNames)
            comps.(componentNames{i}) = [comps.(componentNames{i}) newComps.(componentNames{i})];
            newComps.(componentNames{i})(:) = [];
        end
    end

    % next game turn
    if(chargeParams.mode < 0)
        if (norm(comps.velocities, 'fro') < 0.001)
            chargeParams.mode = chargeParams.mode * -1;
        end
    end

    % check win con
    alive = comps.health > 0;
    if sum(alive) <= 1
        winner = find(alive);
        txt = sprintf('PLAYER %d WINS!', winner);
        text(0.5,0.5,txt, 'FontSize', 42, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle');
        drawnow();
        while ~(isfield(keyboard,'escape') && keyboard.escape)
            pause(dt);
        end
        break;
    end

    pause(dt - toc)
    totalTime = totalTime + dt;

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

function buttonDown(~,~)
    global comps;
    global player;
    global totalTime;
    global chargeParams;
    
    if(chargeParams.mode > 0)
        playerPos = comps.positions(:, player);
        cursorPos = get(gca, 'currentpoint');
        dir = normalize(cursorPos(1,1:2)' - playerPos, 'norm');
        chargeParams.direction = dir;
        chargeParams.startTime = totalTime-0.25;
        
        playerPos = playerPos + dir * 0.05;
        dir = dir * chargeParams.minCharge * chargeParams.scale;
        set(chargeParams.indicator, 'Visible', 'On', ...
            'XData', playerPos(1), 'YData', playerPos(2),...
            'UData', dir(1), 'VData', dir(2));
    end
end

function buttonUp(~,~)
    global comps;
    global player;
    global chargeParams;
    global totalTime;
    
    dir = chargeParams.direction * min(chargeParams.maxCharge, totalTime - chargeParams.startTime);
    if (chargeParams.mode == 1)
        % apply impulse
        vel = comps.velocities(:,player);
        comps.velocities(:,player) = vel + dir * 0.4;
        chargeParams.mode = -2;
    elseif (chargeParams.mode == 2)
        spawnPos = comps.positions(:,player);%+chargeParams.direction*0.1;
        comps.positions = [comps.positions spawnPos];
        comps.velocities = [comps.velocities dir * 0.6];
        comps.hasCollision = [comps.hasCollision true];
        comps.lifeTimes = [comps.lifeTimes realmax];
        chargeParams.mode = -1;
        advanceplayer();
    end
    
    set(chargeParams.indicator, 'Visible', 'Off');
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

function startButtonPressed(src,event)
global shouldStart;
    shouldStart = true;
end