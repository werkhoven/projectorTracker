function [frameRate]=estimateFrameRate(vidObj)

% Estimates the current acquisition rate of an active video object when
% "frameRate" is not an accesible field of the device

nFrames = 20;
tStamps = NaN(nFrames,1);
prev_im = peekdata(vidObj,1);
prev_im = prev_im(:,:,1);
fCount=0;

tic
while any(isnan(tStamps))
    tmp_tStamp = toc;
    im = peekdata(vidObj,1);
    im = im(:,:,1);
    if any(any(im~=prev_im))
        fCount=fCount+1;
        tStamps(fCount)=tmp_tStamp;
    end
    prev_im = im;
    clearvars im
end

frameRate=1/mean(diff(tStamps));