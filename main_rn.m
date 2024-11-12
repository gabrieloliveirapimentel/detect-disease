clc, clear, close all

% Diretórios dos datasets
dataset1Folder = 'dataset_train/dataset1';
dataset2Folder = 'dataset_train/dataset2';

% Carregar imagens de ambos os datasets com imageDatastore
imds1 = imageDatastore(dataset1Folder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');
imds2 = imageDatastore(dataset2Folder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Concatenar os imageDatastores
imds = imageDatastore(cat(1, imds1.Files, imds2.Files), ...
    'Labels', cat(1, imds1.Labels, imds2.Labels));

% Contar o número de imagens por label
labelCount = countEachLabel(imds);

% Encontrar o número mínimo de arquivos em qualquer classe
minNumFiles = min(labelCount{:,2});

% Definir o número de arquivos para treinamento como 70% do mínimo
numTrainFiles = floor(0.7 * minNumFiles);

% Dividir os dados em treinamento, validação e teste
[imdsTrain, imdsRest] = splitEachLabel(imds, numTrainFiles, 'randomize');
numValidationFiles = floor(0.5 * (minNumFiles - numTrainFiles));
[imdsValidation, imdsTest] = splitEachLabel(imdsRest, numValidationFiles, 'randomize');

% Redimensionar as imagens para [300 300 3]
inputSize = [300 300 3];
augimdsTrain = augmentedImageDatastore(inputSize, imdsTrain);
augimdsValidation = augmentedImageDatastore(inputSize, imdsValidation);
augimdsTest = augmentedImageDatastore(inputSize, imdsTest);

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
options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'MaxEpochs', 10, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', augimdsValidation, ...
    'ValidationFrequency', 30, ...
    'Verbose', false, ...
    'Plots', 'training-progress');

% Treinar a rede
trainedNet = trainNetwork(augimdsTrain, layers, options);

% Avaliar a rede no conjunto de treinamento
YPredTrain = classify(trainedNet, augimdsTrain);
YTrain = imdsTrain.Labels;
trainAccuracy = sum(YPredTrain == YTrain) / numel(YTrain);
disp(['Train accuracy: ', num2str(trainAccuracy)]);

% Avaliar a rede no conjunto de validação
YPredValidation = classify(trainedNet, augimdsValidation);
YValidation = imdsValidation.Labels;
validationAccuracy = sum(YPredValidation == YValidation) / numel(YValidation);
disp(['Validation accuracy: ', num2str(validationAccuracy)]);

% Avaliar a rede no conjunto de teste
YPredTest = classify(trainedNet, augimdsTest);
YTest = imdsTest.Labels;
testAccuracy = sum(YPredTest == YTest) / numel(YTest);
disp(['Test accuracy: ', num2str(testAccuracy)]);

% Exibir matriz de confusão para o conjunto de teste
figure;
confusionchart(YTest, YPredTest);
title('Confusion Matrix - Test Set');

% Exibir algumas imagens classificadas incorretamente do conjunto de teste
incorrectIdx = find(YTest ~= YPredTest);
figure;
for i = 1:min(20, numel(incorrectIdx))
    subplot(4, 5, i);
    imshow(readimage(imdsTest, incorrectIdx(i)));
    title(['Pred: ' char(YPredTest(incorrectIdx(i))) ', True: ' char(YTest(incorrectIdx(i)))]);
end

% Salvar o modelo treinado, se necessário
save('classificacao_limao.mat', 'trainedNet');