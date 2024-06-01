clc,clear,close all
% Esboço de treino de rede

% Caminho para os limões do dataset1
dataset1 = fullfile("dataset_full/limoes1/images/");

% Abra o arquivo JSON
fileName = "dataset_full/limoes1/annotations/instances_default.json";
str = fileread(fileName);

% Converta o conteúdo do arquivo JSON em uma estrutura
data = jsondecode(str);

%Cria um imageDatastore desses limões
imdsLemons1 = imageDatastore(dataset1,"LabelSource", 'foldernames');





