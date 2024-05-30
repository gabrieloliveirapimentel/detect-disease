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
imagem = imread('dataset/bad_quality_1.jpg');
% imagem = imread('dataset/0003_B_H_0_H.jpg');

% Padronização do tamanho das imagens
imagem = imresize(imagem, [300, 300]);

% Mostrar a imagem original
% figure, imshow(imagem);

% Mostrar o histograma da imagem
% figure, imhist(img);

% Chamar função para verificar se tem fundo preto ou não
verificarFundoPreto(imagem);

% Verificar fundo preto
function verificarFundoPreto(imagem)
    countPixelsPreto = 0;    
    
    % Fazer a verificação dos pixels
    for i = 1:size(imagem, 1)
        for j = 1:size(imagem, 2)
            % Se o pixel for preto, incrementa a contagem
            if imagem(i, j,:) == 0
               countPixelsPreto = countPixelsPreto + 1;
            end
        end
    end

    % Se tem fundo preto pega a imagem do limão
    if countPixelsPreto > 10000
        % Passar para escala de cinza
        imagem_gray = rgb2gray(imagem);

        % Binarizar a imagem
        threshold = graythresh(imagem_gray);
        imagem_binaria = imbinarize(imagem_gray, threshold);

        % Extrair o contorno da região do limão
        contorno = bwperim(imagem_binaria);
        figure, imshow(imagem); hold on;
        visboundaries(contorno, 'Color', 'r');
        hold off;
        
        % Chamada da função para verificar condição do limão
        verificarCondicaoLimao(imagem);
         
    % Se não tiver, verificar se tem limão ou não e depois cortar o limão
    else
        % Binarizar a imagem (acima de 150 valores brancos (1); abaixo pretos (0))
        imagemBin = imagem > 150;

        % Chamada da função para vericar se a imagem tem limão ou não
        verificarLimao(imagemBin, imagem);
    end
end

% Função de verificação se tem limão ou não
function verificarLimao(imagemBinarizada, imagemOriginal)
    % Conta o número de pixels brancos na imagem binarizada
    numPixelsBranco = sum(imagemBinarizada(:));
    
    % Se o número de pixels brancos for menor que o limite, a imagem contém um limão
    if numPixelsBranco < 200000
        removerFundoImagem(imagemOriginal);
    % Se não, é apenas o fundo cinza na imagem  
    else
        disp('A imagem não contém um limão.');
    end
end

% Função para remover fundo cinza do limão
function removerFundoImagem(imagem)
    % Converter a imagem para o espaço de cor HSV
    imagemHsv = rgb2hsv(imagem);

    % Segmentar o limão com base na cor forte (amarelo)
    limiarMatiz     = (imagemHsv(:,:,1) >= 0.0  & imagemHsv(:,:,1) <= 0.15);
    limiarSaturacao = (imagemHsv(:,:,2) >= 0.3  & imagemHsv(:,:,2) <= 1);
    limiarBrilho    = (imagemHsv(:,:,3) >= 0.2 & imagemHsv(:,:,3) <= 1);

    % Combinar os limiares
    mascaraLimao = limiarMatiz & limiarSaturacao & limiarBrilho;

    % Preencher buracos que foram retirados
    mascaraLimao = imfill(mascaraLimao, 'holes');

    % Aplicar a máscara na imagem original
    imagemTratada = imagem;
    imagemTratada(repmat(~mascaraLimao, [1, 1, 3])) = 0;
    
    % Visualizar a imagem segmentada
    figure, imshow(imagemTratada);
    
    % Remover pequenas áreas ruidosas
    mascaraLimao = bwareaopen(mascaraLimao, 50);

    % Refinar a máscara com operações morfológicas
    se_large = strel('disk', 5);
    se_small = strel('disk', 3);
    mascaraLimao = imclose(mascaraLimao, se_large);
    mascaraLimao = imfill(mascaraLimao, 'holes');
    mascaraLimao = imopen(mascaraLimao, se_small);
    mascaraLimao = bwareaopen(mascaraLimao, 100);

    % Aplicar a máscara na imagem original
    imagemTratada = imagem;
    imagemTratada(repmat(~mascaraLimao, [1, 1, 3])) = 0;
    
    % Visualizar a imagem segmentada
    figure, imshow(imagemTratada);

    % Identificar os contornos das regiões conectadas
    [B, L] = bwboundaries(mascaraLimao, 'noholes');

    % Extrair propriedades das regiões
    estados = regionprops(L, 'Area');

    % Definir um limiar apropriado para a área
    threshold_area = 100; % Ajuste conforme necessário

    % Visualizar as áreas problemáticas identificadas
    imshow(imagemTratada);
    hold on;
    for k = 1:length(B)
        boundary = B{k};
        if estados(k).Area > threshold_area
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
    mascaraImagem = ~(Ir == 0 & Ig == 0 & Ib == 0);
    
    % Aplicar a máscara aos canais de cor
    Ir_valid = Ir(mascaraImagem);
    Ig_valid = Ig(mascaraImagem);
    Ib_valid = Ib(mascaraImagem);
    
    % Calcular a média dos valores dos pixels para cada canal, ignorando os pixels pretos
    mediaR = mean(Ir_valid(:));
    mediaG = mean(Ig_valid(:));
    mediaB = mean(Ib_valid(:));
    
    % Definir os limites para um limão bom
    limiteR = 128;
    limiteG = 105;
    limiteB = 60;
    
    % Verificar a condição do limão com base nos limites
    if mediaR > limiteR && mediaG > limiteG && mediaB < limiteB
         disp('O limão está em boa qualidade.');
    else
         disp('O limão está com mofo.');
    end
end