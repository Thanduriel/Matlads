function updatePhysics()
global comps;
global ground;
global dt;
global numPlayers;

gravity = [0; -0.55];
%restitution = 0.1;

% update physics
comps.velocities = comps.velocities + dt * gravity;
newPositions = comps.positions + dt * comps.velocities;
% resolve collisions
for i = 1:size(comps.positions, 2)
    oldPos = [comps.positions(1,i) comps.positions(2,i)];
    newPos = [newPositions(1,i) newPositions(2,i)];
    [x,y,~,ind2] = intersections([oldPos(1) newPos(1)], ...
        [oldPos(2) newPos(2)], ...
        ground.vertices(1,:), ground.vertices(2,:));
    if (x)
        dir = oldPos - newPos;
        len = norm(dir); 
        newPositions(:, i) = [x y] + dir / len * 0.0001;
        
        if i <= numPlayers
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
            v = comps.velocities(:,i);
            % remove any velocity in normal direction
            newV = 0.34 * (v -  2.0 * (n' * v) * n);
            if norm(newV) < 0.1
                newV = [0; 0];
            end
            comps.velocities(:,i) = newV;
        else
            blastDir = comps.positions(:,1:numPlayers) - newPositions(:, i);
            blastDist = vecnorm(blastDir);
            for j = 1:length(blastDist)
                % reduce damage if a barrier is in between
                if intersections([comps.positions(1,j) newPositions(1,i)],...
                        [comps.positions(2,j) newPositions(2,i)], ...
                        ground.vertices(1,:), ground.vertices(2,:))
                    blastDist(j) = blastDist(j) + 1.0;
                end
            end
            comps.health = min(100, max(0,comps.health - 100 * max(0, 0.1 - blastDist)));
            comps.deleted = [comps.deleted i];
        end
    end
end
comps.positions = newPositions;
end