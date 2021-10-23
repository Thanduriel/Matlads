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
    %            m1 = 0.0001;
    %            m2 = 1;
    %            impulse = (m1 * m2) / (m1 + m2) * (1 + restitution) * norm(comps.velocities(:,i));
    %            comps.velocities(:,i) = comps.velocities(:,i) + impulse / m1 * n;
            dir = oldPos - newPos;
            len = norm(dir); 
            newPositions(:, i) = [x y] + dir / len * 0.0001;
        else
            comps.deleted = [comps.deleted i];
        end
    end
end
comps.positions = newPositions;
end