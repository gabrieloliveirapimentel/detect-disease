clc, clear, close all

%% Trabalho final de Visão por Computador
% Controlo de qualidade em frutos (limões) 
% Elaborado por: Augusto Dessanti e Gabriel Pimentel
%
% Fluxo de execução do código
% Verifica se a imagem tem fundo preto (dataset 1), se sim, cria uma nova 
% imagem com os pixels que não são pretos (limão) e chama a função para 
% verificar a condição do limão (se está bom ou com mofo)
%
% Caso a imagem não tem fundo preto (dataset 2), chama a função verificarLimao
% que irá verificar se tem limão ou só o fundo da imagem, caso tenha, 
% corta o limão e chama a função para verificar a condição do limão
%
% Se não tem limão, irá informar que a imagem não possui limão
%
%% Código da aplicação

% Leitura da imagem
% imagem = imread('dataset/all_short/good_quality_104.jpg');
imagem = imread('dataset/all_short/good_quality_108.jpg');
% imagem = imread('dataset/dataset-used/0012_G_V_45_F.jpg');

% Padronização do tamanho das imagens
imagem = imresize(imagem, [300, 300]);

% Clareando a imagem
AI  = imcomplement(imagem);     % Inverte a imagem
BAI = imreducehaze(AI);         % Reduz ruído
imagem   = imcomplement(BAI);   % Inverte novamente para o original sem os ruidos

% Mostrar a imagem clareada
figure, imshow(imagem);

% Mostrar o histograma da imagem
% figure, imhist(img);

% Chamar função para verificar se tem fundo preto ou não
verificarFundoPreto(imagem);

% Verificar fundo preto
function verificarFundoPreto(imagem)
    countPixelsPreto = 0;    
    imagemSemFundo = zeros(size(imagem), 'like', imagem);
    
    for i = 1:size(imagem, 1)
        for j = 1:size(imagem, 2)
            if imagem(i, j,:) == 0
               countPixelsPreto = countPixelsPreto + 1;
            else
                imagemSemFundo(i,j,:) = imagem(i,j,:);
            end
            
        end
    end

    % Se tem fundo preto, pega a nova imagem do limão cortado
    if countPixelsPreto > 10000
        imgMask = any(imagem ~= 0, 3);
        
        % Aplicar a máscara para obter a imagem sem fundo
        imagemSemFundo = imagem;
        imagemSemFundo(repmat(~imgMask, [1 1 3])) = 0;
        figure, imshow(imagemSemFundo)
        
        % Chamada da função para verificar condição do limão
        verificarCondicaoLimao(imagemSemFundo);
         
    % Se não tiver, verificar se tem limão ou não e depois cortar o limão
    else
        % Binarizar a imagem (acima de 150 valores brancos (1); abaixo pretos (0))
        imagemBin = imagem > 150;

        % Chamada da função para vericar se a imagem tem limão ou não
        verificarLimao(imagemBin, 'img', imagem);
    end
end

% Função de verificação se tem limão ou não
function verificarLimao(imagemBinarizada, imagemNome, imagemOriginal)
    % Conta o número de pixels brancos na imagem binarizada
    numPixelsBranco = sum(imagemBinarizada(:));
    
    % Se o número de pixels brancos for menor que o limite, a imagem contém um limão
    if numPixelsBranco < 200000
        disp([imagemNome ' contém um limão.'])
        removerFundoImagem(imagemOriginal);
    % Se não, é apenas o fundo na imagem  
    else
        disp([imagemNome ' não contém um limão.']);
    end
end

% Função para remover fundo do limão
function removerFundoImagem(imagem)
    % Converter a imagem para o espaço de cor HSV
    imagemHsv = rgb2hsv(imagem);

    % Segmentar o limão com base na cor forte (amarelo)
    limiarMatiz     = (imagemHsv(:,:,1) >= 0.0  & imagemHsv(:,:,1) <= 0.2);
    limiarSaturacao = (imagemHsv(:,:,2) >= 0.2  & imagemHsv(:,:,2) <= 1);
    limiarBrilho    = (imagemHsv(:,:,3) >= 0.25 & imagemHsv(:,:,3) <= 1);

    % Combinar os limiares
    mascaraLimao = limiarMatiz & limiarSaturacao & limiarBrilho;

    % Preencher buracos que foram retirados
    mascaraLimao = imfill(mascaraLimao, 'holes');

    % Aplicar a máscara na imagem original
    imagemTratada = imagem;
    imagemTratada(repmat(~mascaraLimao, [1, 1, 3])) = 0;
    
    % Visualizar a imagem segmentada
    % figure, imshow(imagemTratada);
    
    % Remover pequenas áreas ruidosas
    defect_mask = bwareaopen(mascaraLimao, 50);

    % Refinar a máscara de defeitos com operações morfológicas
    se_small = strel('disk', 2);
    defect_mask = imclose(defect_mask, se_small);
    defect_mask = imfill(defect_mask, 'holes');
    defect_mask = bwareaopen(defect_mask, 100);

    % Identificar os contornos das regiões conectadas
    [B, L] = bwboundaries(defect_mask, 'noholes');

    % Extrair propriedades das regiões
    stats = regionprops(L, 'Area');

    % Definir um limiar apropriado para a área
    threshold_area = 100; % Ajuste conforme necessário

    % Visualizar as áreas problemáticas identificadas
    imshow(imagemTratada);
    hold on;
    for k = 1:length(B)
        boundary = B{k};
        if stats(k).Area > threshold_area
            plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
        end
    end
    
    % Chamada da função para verificar condição do limão
    verificarCondicaoLimao(imagemTratada);
end

% Função para verificar a condição do limão (bom ou com mofo)
function verificarCondicaoLimao(imagem)
    % Extrair os canais vermelho, verde e azul da imagem
    Ir = imagem(:,:,1);
    Ig = imagem(:,:,2);
    Ib = imagem(:,:,3);
    
    % Criar uma máscara para excluir os pixels pretos (fundo)
    mask = ~(Ir == 0 & Ig == 0 & Ib == 0);
    
    % Aplicar a máscara aos canais de cor
    Ir_valid = Ir(mask);
    Ig_valid = Ig(mask);
    Ib_valid = Ib(mask);
    
    % Calcular a média dos valores dos pixels para cada canal, ignorando os pixels pretos
    meanR = mean(Ir_valid(:))
    meanG = mean(Ig_valid(:))
    meanB = mean(Ib_valid(:))
    
    % Definir os limites para um limão bom
    limiteR = 160;
    limiteG = 160;
    limiteB = 60;
    
    % Verificar a condição do limão com base nos limites
    if meanR > limiteR && meanG > limiteG && meanB < limiteB
        disp('O limão está em boa qualidade.');
    else
        disp('O limão está com mofo.');
    end
    
%     imagem_gray = rgb2gray(imagem);
% 
%     % Binarizar a imagem
%     threshold = graythresh(imagem_gray);
%     imagem_binaria = imbinarize(imagem_gray, threshold);
% 
%     % Extrair o contorno da região do limão
%     contorno = bwperim(imagem_binaria);
%     figure, imshow(imagem); hold on;
%     visboundaries(contorno, 'Color', 'r');
%     title('Contorno do Limão');
%     hold off;
end