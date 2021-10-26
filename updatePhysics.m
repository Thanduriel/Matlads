function updatePhysics()
global comps;
global ground;
global dt;
global numPlayers;

gravity = [0; -0.55];
%restitution = 0.1;

% update physics
comps.velocities(:, comps.hasCollision) = comps.velocities(:, comps.hasCollision) + dt * gravity;
newPositions = comps.positions + dt * comps.velocities;

% resolve collisions
inds = 1:size(comps.positions, 2);
for i = inds(comps.hasCollision)
    oldPos = [comps.positions(1,i) comps.positions(2,i)];
    newPos = [newPositions(1,i) newPositions(2,i)];
    [x,y,~,ind2] = intersections([oldPos(1) newPos(1)], ...
        [oldPos(2) newPos(2)], ...
        ground.vertices(1,:), ground.vertices(2,:));
    if (x)
        dir = oldPos - newPos;
        len = norm(dir); 
        
        % multiple intersections, determine the first
        if (size(x,1) > 1)
            dists = vecnorm([x; y] - oldPos);
            [~,I] = min(dists);
            x = x(I);
            y = y(I);
            ind2 = ind2(I);
        end
        ind2 = floor(ind2);
        n = ground.normals(:,ind2);
        if i <= numPlayers
            v = comps.velocities(:,i);
            % velocity is reflected and reduced to simulate friction
            newV = 0.34 * (v -  2.0 * (n' * v) * n);
            if norm(newV) < 0.1
                newV = [0; 0];
            end
            comps.velocities(:,i) = newV;
            newPositions(:, i) = [x y] + dir / len * 0.0001;
        else
            spawnExplosion([x;y] + n * 0.005, 200);
            comps.deleted = [comps.deleted i];
        end
    end
end
comps.positions = newPositions;
end

function spawnExplosion(position, damage)
    global comps;
    global ground;
    global numPlayers;
    global newComps;

    maxRange = 0.2;
    maxRangeSq = maxRange * maxRange;

    % damage
    blastDir = comps.positions(:,1:numPlayers) - position;
    blastDist = vecnorm(blastDir);
    for j = 1:length(blastDist)
        % reduce damage if a barrier is in between
        if intersections([comps.positions(1,j) position(1)],...
            [comps.positions(2,j) position(2)], ...
            ground.vertices(1,:), ground.vertices(2,:))
            blastDist(j) = blastDist(j) + 1.0;
        end
    end
    comps.health = min(100, max(0,comps.health - damage * max(0, maxRange - blastDist)));

    % terrain deformation
    t = 0.05:0.5:2*pi;
    blast = polyshape(0.5 * maxRange * cos(t) + position(1),...
        0.5 * maxRange * sin(t) + position(2));
    terrain = subtract(ground.shape, blast);
    ground.vertices = terrain.Vertices';
    ground.shape = terrain;

    set(ground.polygon, 'Shape', ground.shape);
    ground.normals = computeNormals(ground.vertices);

    % particle effect
    numParticles = 64;
    particlePositions = repmat(position, [1 numParticles]);
    lifeTimes = 0.25 * rand(1,numParticles) + 0.25;
    angles = 2*pi*rand(1,numParticles);
    % scaling such that they do not leave the damage radius
    velScales = repmat(maxRange,size(lifeTimes))./lifeTimes;
    particleVelocities = [sin(angles); cos(angles)].* ...
        (repmat(min(1,0.75 + 0.25 * randn(1,numParticles)).* velScales, [2 1]));
    newComps.positions = [newComps.positions particlePositions];
    newComps.velocities = [newComps.velocities particleVelocities];
    newComps.hasCollision = [newComps.hasCollision false(1, numParticles)];
    newComps.lifeTimes = [newComps.lifeTimes lifeTimes];
end