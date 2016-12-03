function scrProp=drawCircle(x,y,r,color,scrProp)

dst_rect=[x-r y-r x+r y+r];
Screen('FillOval', scrProp.window, color, dst_rect');

% Flip our drawing to the screen
scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
end
