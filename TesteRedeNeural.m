clc,clear,close all
% Esboço de treino de rede

% Caminho para os limões do dataset2
datasetBad = fullfile("dataset_full/limoes2/");


%Cria um imageDatastore desses limões
imds = imageDatastore(datasetBad,"IncludeSubfolders",true,'LabelSource','foldernames');

[imdsTrain,imdsValidation] = splitEachLabel(imds,0.75,'randomize');


layers = [

 imageInputLayer([300 300 3])

 convolution2dLayer(3,8,'Padding','same')
 batchNormalizationLayer
 reluLayer
 maxPooling2dLayer(2,'Stride',2)

 convolution2dLayer(3,16,'Padding','same')
 batchNormalizationLayer
 reluLayer
 maxPooling2dLayer(2,'Stride',2)

 convolution2dLayer(3,32,'Padding','same')
 batchNormalizationLayer
 reluLayer

 fullyConnectedLayer(3)
 softmaxLayer
 classificationLayer];

options = trainingOptions('adam', ...
 'MaxEpochs',20, ...
 'ValidationData',imdsValidation, ...
 'ValidationFrequency',30, ...
 'Verbose',1, ...
 'Plots','training-progress');

net = trainNetwork(imdsTrain,layers,options);

YPred = classify(net,imdsValidation);
YValidation = imdsValidation.Labels;
accuracy = sum(YPred == YValidation)/numel(YValidation);
