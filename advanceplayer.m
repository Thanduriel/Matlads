function advancePlayer()
global numPlayers;
global comps;
global player;

set(comps.sprites(player), 'EdgeColor', 'none');

for i = 1:numPlayers
    player = player + 1;
    if player > numPlayers
        player = 1;
    end
    if comps.health(player) > 0
        break;
    end
end

set(comps.sprites(player), 'EdgeColor', 'green');
end