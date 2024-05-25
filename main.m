clc, clear, close all

% Leitura da imagem (Imagem do MATLAB)
% img = imread('dataset/all_short/good_quality_104.jpg');
% img = imread('dataset/dataset-used/0005_C_H_45_H.jpg');
img = imread('dataset/dataset-used/0012_G_V_0_F.jpg');
% img = imread('dataset/dataset-used/0017_A_I_15_A.jpg');
% Padronização do tamanho das imagens
img = imresize(img, [300, 300]);

% Clareando a imagem
AI  = imcomplement(img);        % Inverte a imagem
BAI = imreducehaze(AI);         % Reduz ruído
img   = imcomplement(BAI);      % Inverte novamente para o original sem os ruidos

% Mostrar a imagem clareada
figure, imshow(img);
% figure, imhist(img);

% Chamar função para verificar se tem fundo preto ou não
checkBackgroundImage(img);

% Função de verificação se tem limão ou não
function checkLemonImage(imgBin, imgName, imgOriginal)
    % Conta o número de pixels brancos na imagem binarizada
    numWhitePixels = sum(imgBin(:));
    
    % Se o número de pixels brancos for menor que o limite, a imagem contém um limão
    if numWhitePixels < 200000
        disp([imgName ' contém um limão.'])
        removeLemonBackground(imgOriginal);
        
    else
        disp([imgName ' não contém um limão.']);
    end
end

% Função para remover fundo do limão
function removeLemonBackground(img)
    % Converter a imagem para o espaço de cor HSV
    hsvImg = rgb2hsv(img);

    % Segmentar o limão com base na cor forte (amarelo)
    hueThresh = (hsvImg(:,:,1) >= 0.0  & hsvImg(:,:,1) <= 0.2);
    satThresh = (hsvImg(:,:,2) >= 0.2  & hsvImg(:,:,2) <= 1);
    valThresh = (hsvImg(:,:,3) >= 0.25 & hsvImg(:,:,3) <= 1);

    % Combinar os limiares
    lemonMask = hueThresh & satThresh & valThresh;

    % Preencher buracos que foram retirados
    lemonMask = imfill(lemonMask, 'holes');

    % Aplicar a máscara na imagem original
    newImage = img;
    newImage(repmat(~lemonMask, [1, 1, 3])) = 0;
    
    % Visualizar a imagem segmentada
    figure, imshow(newImage);
    Ix = newImage(:,:,3);
    
    figure, imshow(Ix);
    tratarImagem(newImage);
end

function checkBackgroundImage(img)
    pixelsBlackCount = 0;    
    for i = 1:size(img, 1)
        for j = 1:size(img, 2)
            if img(i, j,:) == 0
               pixelsBlackCount = pixelsBlackCount + 1;
            end
        end
    end

    % Se tem fundo preto não precisa cortar o limão
    if pixelsBlackCount > 10000
         figure, imshow(img);
         Ix = img(:,:,3);
    
         figure, imshow(Ix);
         % figure, imhist(Ix);
         tratarImagem(img);
    % Se não tiver, verificar se tem limão ou não e depois cortar o limão
    else
        % Binarizar a imagem (acima de 150 valores brancos (1); abaixo pretos (0))
        imgBin = img > 150;

        % Chamada da função para vericar se a imagem tem limão ou não
        checkLemonImage(imgBin, 'img', img);
    end
end

function tratarImagem(I)
    I = rgb2gray(I);    
end