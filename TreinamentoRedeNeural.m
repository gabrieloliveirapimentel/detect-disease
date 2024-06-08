clc, clear, close all

%% Trabalho final de Visão por Computador
% Controlo de qualidade em frutos (limões) 
% Etapa de treinamento da rede neural
% Elaborado por: Augusto Dessanti e Gabriel Pimentel

% Caminho para os limões
dataset1Folder = 'dataset_train/dataset1';
dataset2Folder = 'dataset_train/dataset2'; 

% Carregar imagens de ambos os datasets com imageDatastore
imds1 = imageDatastore(dataset1Folder, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
imds2 = imageDatastore(dataset2Folder, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

% Cria um imageDatastore desses limões
inputSize = [300 300 3];
imds = imageDatastore(cat(1, imds1.Files, imds2.Files),'Labels', cat(1, imds1.Labels, imds2.Labels));
[imdsTrain,imdsValidation] = splitEachLabel(imds,0.75,'randomize');

augimdsTrain = augmentedImageDatastore(inputSize, imdsTrain);
augimdsValidation = augmentedImageDatastore(inputSize, imdsValidation);

% Definir as camadas da rede neural
layers = [
    imageInputLayer(inputSize)
    convolution2dLayer(3, 8, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)
    convolution2dLayer(3, 16, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)
    convolution2dLayer(3, 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numel(categories(imdsTrain.Labels)))
    softmaxLayer
    classificationLayer];

% Definir opções de treinamento
options = trainingOptions('adam', ...
    'MiniBatchSize', 32, ...
    'MaxEpochs', 10, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', augimdsValidation, ...
    'ValidationFrequency', 30, ...
    'Verbose', false, ...
    'Plots', 'training-progress');

% Treinar a rede
net = trainNetwork(augimdsTrain, layers, options);

% Avaliar a rede no conjunto de treinamento
YPred = classify(net,augimdsValidation);
YValidation = augimdsValidation;
accuracy = sum(YPred == YValidation)/numel(YValidation);

% Salvar o modelo treinado
% save('classificacao_limoes.mat', 'net');