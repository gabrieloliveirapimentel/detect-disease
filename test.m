clc, clear, close all

% Leitura da imagem (Imagem do MATLAB)
imgLimao = imread('dataset/all_short/good_quality_1050.jpg');
imgFundo = imread('dataset/all_short/empty_background_405.jpg');

% Padronização do tamanho das imagens
imgLimao = imresize(imgLimao, [300, 300]);
imgFundo = imresize(imgFundo, [300, 300]);

% Calcular os histogramas para cada canal de cor
histLimaoR = imhist(imgLimao(:,:,1));
histLimaoG = imhist(imgLimao(:,:,2));
histLimaoB = imhist(imgLimao(:,:,3));

histFundoR = imhist(imgFundo(:,:,1));
histFundoG = imhist(imgFundo(:,:,2));
histFundoB = imhist(imgFundo(:,:,3));

% Subtração dos histogramas
diffHistR = histLimaoR - histFundoR;
diffHistG = histLimaoG - histFundoG;
diffHistB = histLimaoB - histFundoB;

% Identificar os picos que correspondem ao objeto (ajustar conforme necessário)
thresholdR = 200;
thresholdG = 200;
thresholdB = 200;

maskR = ismember(imgLimao(:,:,1), find(diffHistR > thresholdR));
maskG = ismember(imgLimao(:,:,2), find(diffHistG > thresholdG));
maskB = ismember(imgLimao(:,:,3), find(diffHistB > thresholdB));

% Combinação das máscaras
finalMask = maskR & maskG & maskB;

% Processamento morfológico para limpar a máscara
finalMask = imfill(finalMask, 'holes'); % Preencher buracos
finalMask = bwareaopen(finalMask, 50); % Remover áreas pequenas

% Aplicar a máscara na imagem original
segmentado = imgLimao;
segmentado(repmat(~finalMask, [1, 1, 3])) = 0;

% Mostrar a imagem segmentada
figure, imshow(segmentado);
title('Limão Segmentado');