%% clear
clear; close all; clc;

%% read wav
filename = '¿ªÊ¼.wav';
wav = audioread(filename, 'native');
wav_info = audioinfo(filename);
%figure; plot(wav); title('wavform'); hold on;

%% extract frames
frame_length_ms = 25;
frame_shift_ms = 10;
num_of_frames = floor((wav_info.Duration * 1000 - frame_length_ms) / frame_shift_ms);
len_of_frames = floor(frame_length_ms * wav_info.SampleRate / 1000);

wav_frames = zeros(num_of_frames, len_of_frames);
for f = 1:num_of_frames
    idx = (f - 1) * frame_shift_ms * wav_info.SampleRate / 1000 + 1;    % index start from 1, not 0
    wav_frames(f,:) = wav(idx:idx+len_of_frames-1);
end

%% sum(abs())
amplitudes = zeros(num_of_frames, 1);
for f = 1:num_of_frames
    amplitudes(f) = sum(abs(wav_frames(f,:)));
end
figure;
subplot(2,1,1); plot(wav); title('wavform'); hold on;
subplot(2,1,2); plot(amplitudes); title('amplitudes'); hold on;

%% energy
energy = zeros(num_of_frames, 1);
for f = 1:num_of_frames
    energy(f) = sum(power(wav_frames(f,:),2));
end
figure;
subplot(3,1,1); plot(wav); title('wavform'); hold on;
subplot(3,1,2); plot(amplitudes); title('amplitudes'); hold on;
subplot(3,1,3); plot(energy); title('energy'); hold on;

%% zero-crossing rate
zcr = zeros(num_of_frames, 1);
for f = 1:num_of_frames
    zcr(f) = 1 / 2 * sum(abs(wav_frames(f,2:len_of_frames) - ...
                             wav_frames(f,1:len_of_frames-1)));
end
figure;
subplot(2,1,1); plot(wav); title('wavform'); hold on;
subplot(2,1,2); plot(zcr); title('zero-crossing rate'); hold on;

%% energy + window
vad_energy_threshold = 1000;
vad_energy_mean_scale = 0.2;
vad_frames_context = 5;     % window_size = 2 * vad_frames_context + 1;
vad_proportion_threshold = 0.8;
energy_win = zeros(num_of_frames, 1);

vad_energy_threshold = vad_energy_threshold + vad_energy_mean_scale * mean(energy);
for f = 1:num_of_frames
    win_s = max(1, f - vad_frames_context);
    win_e = min(num_of_frames, f + vad_frames_context);
    energy_win(f) = ((sum(energy(win_s:win_e) > vad_energy_threshold) >= (2 * vad_frames_context + 1)*vad_proportion_threshold));
end
figure;
subplot(2,1,1); plot(wav); title('wavform'); hold on;
subplot(2,1,2); plot(energy_win); title('energy_win'); hold on;
plot(energy.*energy_win); title('jj');
