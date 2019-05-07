function  [Image1,bool]=SobelBlur(image)
% SobelBlur è una funzione che legge un 'immagine, attraverso l'operatore
% di sobel valuta la presenza di dettagli e determina se l'immagine in questione è a fuoco o
% meno.Se l'immagine è a fuoco la funzione stampa a video "Immagine a
% fuoco" e la salva, altrimenti stampa "Immagine NON a fuoco".

%NomeFile=image;  
Image1=image; % Leggi l'immagine e memorizzala per l'analisi
Image=image; % Leggi l'immagine e memorizzala per l'uscita
Soglia=20*10^3; % Soglia determinata sperimentalmente per immagini di dimensione sopra 200x300 pixel
[m,n,l]= size(Image); % acquisisci dimensioni dell'immagine
if m>1024 || n>1024 % Condizione necessaria di ridimensionamento di immagini 
                    % troppo grandi che superano le dimensioni massime implementate da Matlab in Sobel
                    % e quindi con numero troppo elevato di bit
    Image = imresize(Image,0.3); % Ridimensiona l'immagine con un fattore di scala 0.3
elseif m<=400 && n<=400 % Condizione di cambiamento di soglia (decisa sperimentalmente) per immagini troppo piccole (sotto 200x300 pixel)
    Soglia=5*10^3; % aggiornamento soglia
end

%figure,imshow(g)
if [m,n,l]== [m,n,3] % Sobel vuole in input solo immagini in scala di grigi , perciò se l'immagine è RGB convertila altrimenti no
Image=rgb2gray(Image);
end
ImgGray= double(Image); % Sobel vuole in input immagini in tipo double , perciò convertila
edgeImage =  sobel(ImgGray, 150); % Calcola Sobel con soglia a 150 (determinata sperimentalmente)
%figure,imshow(edgeImage)
Presenze = CalcolaOccorrenze(edgeImage); % Calcola le occorrenze di pixel bianchinellimmagine binaria di sobel 
if Presenze >= Soglia % se i pixel sono maggiori di soglia l'immagine è a fuoco
    
   bool=1;
    
else
    bool=0;
end
end

function Presenze = CalcolaOccorrenze(edgeImage)
% La funzione CalcolaOccorrenze , conta il numero di occorrenze di una
% matrice , serve come metodo di supporto , per non appesantire troppo il
% codice nella funzione principale.

Occ=0; % inizializzo la variabile presenze

[Righe,Col]=size(edgeImage); % vario gli indici sia delle righe sia delle colonne della matrice per variare l'elemento
    for m = 1:Righe
        for n = 1:Col
      if edgeImage(m,n) == 255   % se la nella matrice dei bordi quell'elemento è BIANCO
        Occ = Occ + 1; % aggiorna la variabile presenze e restituiscila
      end
        end
    end
Presenze=Occ;

end
% OPERATORE SOBEL GIA' IMPLEMENTATO IN MATLAB
% edgeImage = sobel(originalImage, threshold)
% Sobel edge detection. Given a normalized image (with double values)
% return an image where the edges are detected w.r.t. threshold value.
function edgeImage = sobel(originalImage, threshold) %#codegen
assert(all(size(originalImage) <= [1024 1024]));
assert(isa(originalImage, 'double'));
assert(isa(threshold, 'double'));

k = [1 2 1; 0 0 0; -1 -2 -1];
H = conv2(double(originalImage),k, 'same');
V = conv2(double(originalImage),k','same');
E = sqrt(H.*H + V.*V);
edgeImage = uint8((E > threshold) * 255);
end
