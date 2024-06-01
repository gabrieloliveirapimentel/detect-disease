% Especifica o caminho da pasta
folder_path = fullfile("dataset_full/limoes2/good_quality/");;  % Altere para o caminho da sua pasta

% Inicializa variáveis
total_width = 0;
total_height = 0;
image_count = 0;
non_compliant_images = {};

% Obtém uma lista de todos os arquivos na pasta
image_files = dir(fullfile(folder_path, '*.jpg'));  % Altere para o formato de imagem desejado

% Loop por todas as imagens
for idx = 1:length(image_files)
    % Lê a imagem
    img = imread(fullfile(folder_path, image_files(idx).name));

    % Atualiza as dimensões totais
    total_width = total_width + size(img, 2);
    total_height = total_height + size(img, 1);

    % Incrementa o contador de imagens
    image_count = image_count + 1;
end

% Calcula a dimensão média
avg_dim = [total_height / image_count, total_width / image_count];

% Verifica novamente as imagens para conformidade com a dimensão média
for idx = 1:length(image_files)
    img = imread(fullfile(folder_path, image_files(idx).name));
    if ~isequal(size(img, 1), round(avg_dim(1))) || ~isequal(size(img, 2), round(avg_dim(2)))
        non_compliant_images = [non_compliant_images; image_files(idx).name];
    end
end

% Exibe a dimensão média e as imagens não conformes
disp('Dimensão média:');
disp(avg_dim);
disp('Imagens não conformes:');
disp(non_compliant_images);
