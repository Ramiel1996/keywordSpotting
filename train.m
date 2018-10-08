clc
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


datadir = '.\speech_dataset_1' ;
speechdata = dir(datadir) ;
a = readtable('.\speech_dataset_1\label.csv') ;
datainfo = struct('label', num2cell(a.label), 'classname', a.classname) ;

%% ͨ��vgg16�������������ͱ�ǩ

dataset = ([]) ;

for k = 1:length(datainfo)
    speecherdir = dir(sprintf('%s/%d/*.wav', datadir, datainfo(k).label)) ;
    speechnum = length(speecherdir) ;
    
    dataset_ = struct('feat', zeros(1000, 40), ...
                      'label', num2cell(zeros(speechnum, 1)), ...
                      'index', num2cell(zeros(speechnum, 1))) ;
    for v = 1:speechnum
        tic
        %feature
        speechname = sprintf('%s/%d/%s', datadir, datainfo(k).label, speecherdir(v).name) ;
        wav = audioread(speechname, 'native') ;
%         figure(1)
%         plot(wav) ;
        
        info = audioinfo(speechname) ; 
        wav = myVAD(wav) ;
        info.Duration = double(length(wav)/info.SampleRate) ;
%         figure(2)
%         plot(wav);
        
        
        featVec = fbank(wav, info) ;
        dataset_(v).feat = featVec' ;
        
        %index
        if v==9 || v==115 || v==130 || v==200 || v==170 || v==189 || v==40 || v==88
        
           dataset_(v).index= 1 ; %1 test��0 train
        end
        %label
        dataset_(v).label= datainfo(k).label ;
        disp(['class', num2str(k), 'speech', num2str(v), ' spend ', num2str(toc)]) ;
    end
    dataset = [dataset; dataset_] ;
end

%% ���ݴ���

%load('.\dataset.mat', 'dataset') ;
a = {dataset.feat} ;
a = a(:) ;
maxFrameLength = 0 ;
for i = 1:length(a)
    m = size(cell2mat(a(i))) ;
    if m(2)>maxFrameLength
       maxFrameLength = m(2) ;
    end
end
    
dataset_train = dataset([dataset.index]==0) ;
dataset_test = dataset([dataset.index]==1) ;

dataTrain = {dataset_train.feat}' ;
labelTrain = categorical([dataset_train.label]') ;
dataTest = {dataset_test.feat}' ;
labelTest = categorical([dataset_test.label]') ;

%%sort and pad
numObservations = numel(dataTrain) ;
for i=1:numObservations 
    sequence = dataTrain{i} ;
    sequenceLengths(i) = size(sequence,2) ;
end

[sequenceLengths,idx] = sort(sequenceLengths) ;
dataTrain = dataTrain(idx) ;
labelTrain = labelTrain(idx) ;

figure
bar(sequenceLengths)
ylim([0 1000])
xlabel("Sequence")
ylabel("Length")
title("Sequence Lengths")

% dataTrain = dataTrain(3:end-5);
% labelTrain = labelTrain(3:end-5);

%% ����lstm�㣬���ò���

rng('default') ;
rng(0) ;

inputsize = 40 ;                        %��������ά��
outputsize1 = 20 ;                       %�������ά���������������޹أ������С�㣬���Ӵ��
numClasses = length(datainfo) ;        
OutputMode1 =  'last' ;%'sequence' ;                   %������һ����������һ��rnn��Ԫ���

layers = [ ... 
    sequenceInputLayer(inputsize)
    lstmLayer(outputsize1, 'OutputMode', OutputMode1)    
    %lstmLayer(20, 'OutputMode', 'last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer]

maxEpochs = 50000 ; %��������
miniBatchSize = 8 ;

options = trainingOptions('sgdm', ...   %'sgdm' 'rmsprop' 'adam'(2017b only support sgd)
    'ExecutionEnvironment', 'auto', ... %cpu&gpu
    'InitialLearnRate', 0.002, ...   
    'LearnRateSchedule', 'piecewise',...    
    'LearnRateDropFactor', 0.5,...       %ÿx��ѧϰ��*0.5
    'LearnRateDropPeriod', 3000,...
    'MaxEpochs', maxEpochs, ...         %��������
    'MiniBatchSize', miniBatchSize, ... 
    'Verbose', 1, ...                   %��������ʾ������Ϣ
    'Plots', 'training-progress', ...   %���ӻ�
    'Shuffle','never') ;                %�Ƿ�����ϴ��

%% ѵ��

net = trainNetwork(dataTrain, labelTrain, layers, options) ;
 
%% ����

labelPred = classify(net, dataTest, ...
    'MiniBatchSize', miniBatchSize) ;

acc = sum(labelPred == labelTest)./numel(labelTest)






