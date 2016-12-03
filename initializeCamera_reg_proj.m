function out=initializeCamera_reg_proj(adaptorName,deviceID,format)

vid = videoinput(adaptorName,deviceID,format);
src = getselectedsource(vid);
src.Exposure = 0.6;
src.Gain = 1;
src.Shutter = 16.61;
src.WhiteBalanceRBMode = 'Off';
src.Gamma = 1;

triggerconfig(vid,'manual');

% Create the image object in which you want to display 
% the video preview data. Make the size of the image
% object match the dimensions of the video frames.

vidRes = vid.VideoResolution;
nBands = vid.NumberOfBands;

start(vid)
VidStatus = 1;

out=vid;
