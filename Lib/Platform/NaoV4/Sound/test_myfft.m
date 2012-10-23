% sampling frequency
Fs = 16000;
% sample time
T = 1/Fs;
% length of signal
L = 512;
%L = 341;
% time vector
t = [0:L-1]*T;

% touch tone frequencies
symbols = [ '1' '2' '3' 'A'; ...
            '4' '5' '6' 'B'; ...
            '7' '8' '9' 'C'; ...
            '*' '0' '#' 'D'];

fRow = [ 697  770  852  941];  
fCol = [1209 1336 1477 1633];

symbol = '5';
[r c] = find(symbols == symbol);
h1 = fRow(r);
h2 = fCol(c);
% sum of a h1 Hz sinusoid and a h2 Hz sinusoid
%x_tone = 100 * sin(2*pi*h1*t) + 100 * sin(2*pi*h2*t);
x_tone = sin(2*pi*h1*t) + sin(2*pi*h2*t);

% process 4 tones
[rsymbol frame xLIndex xRIndex] = mydtmf(x_tone, x_tone);
[rsymbol frame xLIndex xRIndex] = mydtmf(x_tone, x_tone);
[rsymbol frame xLIndex xRIndex] = mydtmf(x_tone, x_tone);

% process pnSequence
seq = load('pnSequence.mat');
chirp = circshift(seq.y, 10);
rchirp = circshift(seq.y, 0);
[rsymbol frame xLIndex xRIndex] = mydtmf(chirp, rchirp);
[rsymbol frame xLIndex xRIndex] = mydtmf(-chirp, -rchirp);
[rsymbol frame xLIndex xRIndex] = mydtmf(chirp, rchirp);
[rsymbol frame xLIndex xRIndex leftCorr rightCorr] = mydtmf(-chirp, -rchirp);

x_tone_interleaved = zeros([2*L, 1]);
x_tone_interleaved(1:2:end) = x_tone;
x_tone_interleaved(2:2:end) = x_tone;

chirp_interleaved = zeros([2*length(chirp), 1]);
chirp_interleaved(1:2:end) = chirp;
chirp_interleaved(2:2:end) = chirp;

fh = fopen(sprintf('sym%c.pcm', symbol), 'w');
fwrite(fh, [x_tone_interleaved; x_tone_interleaved; x_tone_interleaved; ...
            chirp_interleaved; -chirp_interleaved; chirp_interleaved; -chirp_interleaved], 'int16');
fclose(fh);

plot(x_tone);
